import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/app_services.dart';
import '../../design/app_theme.dart';
import '../../design/parts/pressable_surface.dart';
import '../../design/parts/water_painter.dart';
import '../../design/parts/water_sim.dart';
import '../../design/tokens.g.dart';
import '../../domain/cheer.dart';
import '../../domain/cheer_layout.dart';
import '../../domain/day_key.dart';
import '../../domain/feel_settings.dart';
import '../../domain/fill_gauge.dart';
import '../../domain/mood.dart';
import '../../domain/save_policy.dart';
import '../../domain/spill.dart';
import '../../domain/tuning.dart';
import '../../feedback/feedback_kind.dart';
import '../../l10n/app_localizations.g.dart';
import '../mood_labels.dart';
import 'cheer_overlay.dart';
import 'note_sheet.dart';

/// The tap screen. The whole screen is the touch area: a Listener reads the pointer down, so a
/// tap counts the instant a finger lands. Water rises with the taps, phrases pop up where the
/// finger was, and tilting the phone sloshes the water and can spill it.
class TapScreen extends StatefulWidget {
  const TapScreen({super.key, required this.mood});

  final Mood mood;

  @override
  State<TapScreen> createState() => _TapScreenState();
}

class _TapScreenState extends State<TapScreen>
    with SingleTickerProviderStateMixin {
  final WaterSim _sim = WaterSim();
  late final Ticker _ticker;
  late final AppServices _services;

  FillGauge _gauge = const FillGauge.empty();
  SpillLedger _ledger = const SpillLedger();
  List<LivePhrase> _phrases = const [];
  CheerBook? _book;
  Size _size = Size.zero;

  Duration _lastFrame = Duration.zero;
  double _tilt = 0;
  StreamSubscription<double>? _tiltSubscription;
  bool _filledThisVisit = false;
  bool _wasAboveZero = false;
  bool _leaving = false;
  bool _started = false;

  /// When the full-gauge shake began, by the app clock. Null when not shaking.
  DateTime? _shakeStart;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _services = AppScope.of(context);
    _services.feel.addListener(_onFeelChanged);
    _onFeelChanged();
    final code = Localizations.localeOf(context).languageCode;
    _services
        .loadCheers(code)
        .then((book) {
          if (mounted) _book = book;
        })
        .catchError((Object error) {
          // The screen works without phrases, but the problem is still reported.
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, library: 'tap screen'),
          );
        });
  }

  @override
  void dispose() {
    _services.feel.removeListener(_onFeelChanged);
    _tiltSubscription?.cancel();
    _ticker.dispose();
    _sim.dispose();
    super.dispose();
  }

  FeelSettings get _feel => _services.feel.value;

  void _onFeelChanged() {
    if (_feel.tiltSpill && _tiltSubscription == null) {
      _tiltSubscription = _services.tilt().listen(
        (angle) => _tilt = Spill.clampTilt(angle),
        onError: (Object _) {},
      );
    } else if (!_feel.tiltSpill) {
      _tiltSubscription?.cancel();
      _tiltSubscription = null;
      _tilt = 0;
    }
  }

  // --- each frame -------------------------------------------------------------------------

  void _onFrame(Duration elapsed) {
    final seconds = min(
      (elapsed - _lastFrame).inMicroseconds / Duration.microsecondsPerSecond,
      0.05,
    );
    _lastFrame = elapsed;
    if (seconds <= 0 || _size.isEmpty) return;
    final now = _services.now();

    var level = _gauge.valueAt(now);
    level -= _spillFrame(now, seconds, level);
    final follow =
        1 - exp(-seconds / (GaugeTuning.displayFollow.inMicroseconds / 1e6));
    final before = _sim.level;
    _sim.level += (level - _sim.level) * follow;
    _sim.tiltRadians += (_tilt - _sim.tiltRadians) * min(1.0, seconds * 10);
    _sim.ripple((before - _sim.level) * _size.height);
    _sim.step(seconds);

    if (_wasAboveZero && level <= 0) {
      _services.feedback.trigger(FeedbackKind.drop, widget.mood.id);
    }
    _wasAboveZero = level > 0;

    final alive = CheerLayout.alive([for (final p in _phrases) p.slot], now);
    if (alive.length != _phrases.length) {
      _phrases = [
        for (final p in _phrases)
          if (alive.contains(p.slot)) p,
      ];
    }
    unawaited(_services.journal.save(SaveTrigger.tick));
  }

  /// Water running out of a tilted phone. Returns the level that was spilled this frame.
  double _spillFrame(DateTime now, double seconds, double level) {
    if (!_feel.tiltSpill) return 0;
    final spilled = Spill.spilledIn(
      Duration(
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      ),
      level: level,
      tiltRadians: _sim.tiltRadians,
      screenWidth: _size.width,
      screenHeight: _size.height,
    );
    if (spilled <= 0) return 0;
    _gauge = _gauge.spilled(spilled);
    final (ledger, lost) = _ledger.add(spilled);
    _ledger = ledger;
    if (lost > 0) {
      _services.journal.removeTaps(DayKey.of(now), widget.mood, lost);
    }
    return spilled;
  }

  // --- a tap -----------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    if (_size.isEmpty || _leaving) return;
    final now = _services.now();
    _gauge = _gauge.tap(now);
    _services.journal.recordTap(widget.mood, now);
    final filled = _gauge.justFilled;
    _filledThisVisit |= filled;
    _services.feedback.trigger(
      filled ? FeedbackKind.full : FeedbackKind.tap,
      widget.mood.id,
    );
    _hitWater(event.localPosition, filled);
    if (_feel.cheerPhrases) _showCheer(event.localPosition, now, filled);
    if (filled && _feel.screenShake) _shakeStart = now;
    setState(() {});
  }

  void _hitWater(Offset at, bool filled) {
    final surfaceY = _sim.surfaceYAt(at.dx);
    final insideWater = at.dy >= surfaceY;
    _sim.hit(
      at.dx,
      insideWater: insideWater,
      scale: filled ? CompleteTuning.waterKickScale : 1,
    );
    if ((at.dy - surfaceY).abs() <= FillTuning.dropletReach) {
      _sim.throwDroplets(at.dx, surfaceY, _sim.dropletCount(complete: filled));
    }
  }

  void _showCheer(Offset at, DateTime now, bool filled) {
    final book = _book;
    if (book == null) return;
    final stage = CheerStage.of(_gauge, now);
    final draw = _services.cheerPicker.draw(book, widget.mood, stage);
    final level = _gauge.valueAt(now);
    final fontSize = CheerLayout.fontSizeFor(
      level: level,
      kind: draw.kind,
      length: draw.phrase.runes.length,
      screenWidth: _size.width,
    );
    final CheerPlacement placement;
    if (draw.kind == CheerKind.complete) {
      placement = CheerLayout.showComplete(
        center: Point(_size.width / 2, _size.height * 0.38),
        length: draw.phrase.runes.length,
        fontSize: fontSize,
        now: now,
      );
    } else {
      placement = CheerLayout.show(
        tap: Point(at.dx, at.dy),
        length: draw.phrase.runes.length,
        fontSize: fontSize,
        slots: [for (final p in _phrases) p.slot],
        now: now,
        kind: draw.kind,
        bounds: CheerRect(0, 0, _size.width, _size.height),
        screenCenterX: _size.width / 2,
      );
    }
    final known = {for (final p in _phrases) p.slot: p};
    _phrases = [
      for (final slot in placement.slots)
        known[slot] ??
            LivePhrase(slot: slot, text: draw.phrase, fontSize: fontSize),
    ];
  }

  // --- leaving ---------------------------------------------------------------------------

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    final navigator = Navigator.of(context);
    final today = DayKey.of(_services.now());
    await _services.journal.save(SaveTrigger.leaveScreen);
    await _services.cheerPicker.persist(_services.deckStore);
    final record = _services.journal.journal.dayOf(today);
    if (record.shouldAskNote(filledThisVisit: _filledThisVisit) && mounted) {
      await showNoteSheet(context, today);
    }
    if (navigator.mounted) navigator.pop();
  }

  // --- drawing ---------------------------------------------------------------------------

  Offset _shakeOffset(DateTime now) {
    final start = _shakeStart;
    if (start == null) return Offset.zero;
    final t =
        now.difference(start).inMicroseconds /
        CompleteTuning.shakeDuration.inMicroseconds;
    if (t >= 1) return Offset.zero;
    final fade = 1 - t;
    return Offset(sin(t * 14 * pi) * CompleteTuning.shakeAmplitude * fade, 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            _size = constraints.biggest;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPointerDown,
                    child: AnimatedBuilder(
                      animation: _sim,
                      builder: (context, _) => Transform.translate(
                        offset: _shakeOffset(_services.now()),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: WaterPainter(sim: _sim, palette: p),
                            ),
                            CheerOverlay(
                              phrases: _phrases,
                              now: _services.now,
                              surfaceYAt: _sim.surfaceYAt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Row(
                        children: [
                          PressableSurface.icon(
                            icon: Icons.arrow_back,
                            semanticLabel: l10n.common_back,
                            onTap: _leave,
                          ),
                          const SizedBox(width: Space.md),
                          Text(
                            '${moodEmoji(widget.mood)} ${moodName(context, widget.mood)}',
                            style: TypeScale.title.copyWith(color: p.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.xl),
                        child: ListenableBuilder(
                          listenable: _services.journal,
                          builder: (context, _) {
                            final count = _services.journal.journal
                                .dayOf(DayKey.of(_services.now()))
                                .countOf(widget.mood);
                            return Text(
                              l10n.tap_todayCount(count),
                              textAlign: TextAlign.center,
                              style: TypeScale.title.copyWith(
                                color: _sim.level * _size.height > 120
                                    ? p.onFill
                                    : p.ink,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
