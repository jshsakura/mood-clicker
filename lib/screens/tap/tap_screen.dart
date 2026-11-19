import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/app_services.dart';
import '../../design/app_theme.dart';
import '../../design/parts/dawn_wash.dart';
import '../../design/parts/hint_bubble.dart';
import '../../design/parts/how_to_button.dart';
import '../../design/parts/line_icon.dart';
import '../../design/parts/mood_face.dart';
import '../../design/parts/pressable_surface.dart';
import '../../design/parts/settle_line.dart';
import '../../design/parts/water_painter.dart';
import '../../design/parts/water_sim.dart';
import '../../design/tokens.g.dart';
import '../../domain/cheer.dart';
import '../../domain/cheer_layout.dart';
import '../../domain/day_key.dart';
import '../../domain/feel_settings.dart';
import '../../domain/fill_gauge.dart';
import '../../domain/mood.dart';
import '../../domain/release_flow.dart';
import '../../domain/save_policy.dart';
import '../../domain/spill.dart';
import '../../domain/hold_reward.dart';
import '../../domain/tuning.dart';
import '../../feedback/feedback_kind.dart';
import '../../l10n/app_localizations.g.dart';
import '../how_to_play_sheet.dart';
import '../mood_labels.dart';
import 'cheer_overlay.dart';
import 'note_sheet.dart';

/// The tap screen. The whole screen is the touch area: a Listener reads the pointer down, so a
/// tap counts the instant a finger lands. Water rises with the taps, phrases pop up where the
/// finger was, and tilting the phone sloshes the water and can spill it.
class TapScreen extends StatefulWidget {
  const TapScreen({super.key, required this.mood, this.random});

  final Mood mood;

  /// The source of chance for the water. Tests give a seeded one.
  final Random? random;

  @override
  State<TapScreen> createState() => _TapScreenState();
}

class _TapScreenState extends State<TapScreen>
    with SingleTickerProviderStateMixin {
  late final WaterSim _sim = WaterSim(random: widget.random);
  late final Random _tiltRandom = widget.random ?? Random();
  late final Ticker _ticker;
  late final AppServices _services;

  FillGauge _gauge = const FillGauge.empty();
  SpillLedger _ledger = const SpillLedger();
  List<CheerSlot> _phrases = const [];
  CheerBook? _book;
  Size _size = Size.zero;

  Duration _lastFrame = Duration.zero;
  double _tilt = 0;
  StreamSubscription<double>? _tiltSubscription;
  bool _filledThisVisit = false;
  bool _wasAboveZero = false;
  bool _leaving = false;

  /// Set when the note sheet was shown on this visit, so skipping it counts as asked.
  bool _noteAsked = false;
  bool _started = false;

  /// What one tap shows again when the reward fires: where the last finger landed.
  Offset? _lastTapAt;
  HoldReward _hold = const HoldReward();

  /// Water spilled this visit, in taps. The number on screen drops by it.
  int _spilledTaps = 0;
  bool _showBubble = false;
  Timer? _bubbleTimer;

  /// The release flow of a heavy mood (angry, sad, anxious); the other moods never use it.
  late final bool _hasRelease = hasRelease(widget.mood);
  ReleaseFlow _flow = const ReleaseFlow.start();

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
    _maybeShowBubble();
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
    // Closed some way other than the back button (a widget link replaced this screen): the taps
    // still must not wait for the next timer.
    unawaited(_services.journal.save(SaveTrigger.leaveScreen));
    _services.feedback
      ..hapticEase = 1
      ..settled = false;
    _services.feel.removeListener(_onFeelChanged);
    _tiltSubscription?.cancel();
    _bubbleTimer?.cancel();
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

  /// The count block sits this far above the bottom edge, as in the canvas.
  static const double _countBottom = 48;

  /// Vertical place of the hint: under the 200 px character slot of the canvas, 20 px gap.
  static const double _hintAlignY = 0.3;

  /// The header starts this far from the top edge, as in the canvas (it includes the status bar).

  /// The first visit only: the bubble beside the how-to button stays a moment, then never again.
  void _maybeShowBubble() {
    if (_services.hints.seen(HowToTuning.bubbleHintId)) return;
    unawaited(_services.hints.markSeen(HowToTuning.bubbleHintId));
    _showBubble = true;
    _bubbleTimer = Timer(HowToTuning.bubbleDuration, _dismissBubble);
  }

  void _dismissBubble() {
    _bubbleTimer?.cancel();
    if (!_showBubble || !mounted) return;
    setState(() => _showBubble = false);
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
    if (_hasRelease) _followRelease(now, level);
    _followHold(now, level);
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

    unawaited(_services.journal.save(SaveTrigger.tick));
  }

  /// Brings the release flow to [level] at [now] and hands what it says to the water and the
  /// feedback: the water gathers and the haptic softens on the approach, and after the cleanse the
  /// taps sound as the calm kalimba.
  void _followRelease(DateTime now, double level) {
    _flow = _flow.withLevel(level, now);
    final frame = _flow.frameAt(now);
    _sim.gather = frame.approach;
    _services.feedback
      ..hapticEase =
          1 - (1 - ReleaseTuning.approachHapticFloor) * frame.approach
      ..settled = frame.phase == ReleasePhase.settle;
  }

  /// Pays the hold reward once when the level has stayed just below full long enough: a rare
  /// phrase with its stars and rays, and the short chord.
  void _followHold(DateTime now, double level) {
    final (next, earned) = _hold.update(level, now);
    _hold = next;
    if (!earned) return;
    _services.feedback.trigger(FeedbackKind.hold, widget.mood.id);
    if (!_feel.cheerPhrases) return;
    _showCheer(
      _lastTapAt ?? _size.center(Offset.zero),
      now,
      false,
      forceRare: true,
    );
    setState(() {});
  }

  /// Water running out of a tilted phone. Returns the level that was spilled this frame.
  double _spillFrame(DateTime now, double seconds, double level) {
    if (!_feel.tiltSpill) {
      _sim.spillAt(0);
      return 0;
    }
    final spilled = Spill.spilledIn(
      Duration(
        microseconds: (seconds * Duration.microsecondsPerSecond).round(),
      ),
      level: level,
      tiltRadians: _sim.tiltRadians,
      screenWidth: _size.width,
      screenHeight: _size.height,
    );
    _sim.spillAt(seconds > 0 ? spilled / seconds : 0);
    if (spilled <= 0) return 0;
    _gauge = _gauge.spilled(spilled);
    final (ledger, lost) = _ledger.add(spilled);
    _ledger = ledger;
    if (lost > 0) {
      _spilledTaps += lost;
      setState(() {});
      if (SpillTuning.takesFromRecord) {
        _services.journal.removeTaps(DayKey.of(now), widget.mood, lost);
      }
    }
    return spilled;
  }

  // --- a tap -----------------------------------------------------------------------------

  /// An edge touch waits: it may be the system back gesture. Null when none is waiting.
  final Map<int, Offset> _edgeTouches = {};

  bool _atEdge(Offset at) =>
      at.dx < FillTuning.edgeGuard ||
      at.dx > _size.width - FillTuning.edgeGuard;

  void _onPointerDown(PointerDownEvent event) {
    if (_atEdge(event.localPosition)) {
      _edgeTouches[event.pointer] = event.localPosition;
      return;
    }
    _registerTap(event.localPosition);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _edgeTouches[event.pointer];
    if (start == null) return;
    if ((event.localPosition - start).distance > FillTuning.edgeTapSlop) {
      _edgeTouches.remove(event.pointer);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_edgeTouches.remove(event.pointer) == null) return;
    _registerTap(event.localPosition);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _edgeTouches.remove(event.pointer);
  }

  /// A tap from the keyboard or from assistive technology: the middle of the screen.
  void _tapFromAction() => _registerTap(_size.center(Offset.zero));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.space && key != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    _tapFromAction();
    return KeyEventResult.handled;
  }

  void _registerTap(Offset at) {
    if (_size.isEmpty || _leaving) return;
    final now = _services.now();
    _lastTapAt = at;
    final wasFull = _gauge.isFullAt(now);
    _gauge = _gauge.tap(now);
    _services.journal.recordTap(widget.mood, now);
    final filled = _gauge.justFilled;
    _filledThisVisit |= filled;
    final releases = _hasRelease && filled;
    _services.feedback.trigger(
      releases
          ? FeedbackKind.cleanse
          : filled
          ? FeedbackKind.full
          : FeedbackKind.tap,
      widget.mood.id,
    );
    _hitWater(at, filled, wasFull: wasFull);
    // A heavy mood does not celebrate a full gauge: no complete phrase, no shake.
    if (_feel.cheerPhrases && !releases) _showCheer(at, now, filled);
    if (filled && _feel.screenShake && !releases) _shakeStart = now;
    if (_hasRelease) _followRelease(now, _gauge.valueAt(now));
    setState(() {});
  }

  void _hitWater(Offset at, bool filled, {required bool wasFull}) {
    final surfaceY = _sim.surfaceYAt(at.dx);
    final insideWater = at.dy >= surfaceY;
    final power = filled
        ? CompleteTuning.waterKickScale
        : (wasFull ? FillTuning.fullKick : 1.0);
    _sim.hit(at.dx, insideWater: insideWater, scale: power);
    if (surfaceY < _size.height - FillTuning.dropletFloorMargin &&
        (at.dy - surfaceY).abs() < FillTuning.dropletReach) {
      _sim.throwDroplets(
        at.dx,
        surfaceY,
        _sim.dropletCount(power: power),
        power: power,
      );
    }
  }

  void _showCheer(
    Offset at,
    DateTime now,
    bool filled, {
    bool forceRare = false,
  }) {
    final book = _book;
    if (book == null) return;
    final stage = CheerStage.of(_gauge, now);
    final draw = forceRare
        ? _services.cheerPicker.drawRare(book, widget.mood)
        : _services.cheerPicker.draw(book, widget.mood, stage);
    final fontSize = CheerLayout.fontSizeFor(
      level: _gauge.valueAt(now),
      kind: draw.kind,
      length: draw.phrase.length,
      screenWidth: _size.width,
      textScale: _feel.textScale,
    );
    final screen = Size2(_size.width, _size.height);
    final CheerPlacement placement;
    if (draw.kind == CheerKind.complete) {
      placement = CheerLayout.showComplete(
        screen: screen,
        text: draw.phrase,
        fontSize: fontSize,
        now: now,
      );
    } else {
      placement = CheerLayout.show(
        tap: Point(at.dx, at.dy),
        text: draw.phrase,
        fontSize: fontSize,
        slots: _phrases,
        now: now,
        screen: screen,
        rotationDegrees:
            _tiltRandom.nextInt(CheerTuning.tiltDegrees * 2 + 1) -
            CheerTuning.tiltDegrees,
        kind: draw.kind,
      );
    }
    _phrases = placement.slots;
  }

  /// Whether leaving must first ask for the note: the gauge was filled in this visit and the day
  /// has no note yet.
  bool get _noteDue =>
      _filledThisVisit &&
      !_noteAsked &&
      _services.journal.journal
          .dayOf(DayKey.of(_services.now()))
          .shouldAskNote(filledThisVisit: true);

  /// The screen is already gone (the system back gesture or button): write what is waiting and, if
  /// the day still owes a note, ask for it over the screen below, the same as the back button does.
  Future<void> _afterSystemExit() async {
    final navigator = Navigator.of(context);
    final services = _services;
    final today = DayKey.of(services.now());
    final owed = _noteDue;
    if (owed) _noteAsked = true;
    final filled = _filledThisVisit;
    await services.journal.save(SaveTrigger.leaveScreen);
    await services.cheerPicker.persist(services.deckStore);
    final overlay = navigator.overlay?.context;
    if (owed && navigator.mounted && overlay != null && overlay.mounted) {
      await showNoteSheet(overlay, today, afterComplete: filled);
    }
  }

  // --- leaving ---------------------------------------------------------------------------

  /// The back button. Leaves once: a second exit while this one waits for the disk is ignored,
  /// and the pop happens only when this screen is still the current route.
  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    final today = DayKey.of(_services.now());
    await _services.journal.save(SaveTrigger.leaveScreen);
    await _services.cheerPicker.persist(_services.deckStore);
    final record = _services.journal.journal.dayOf(today);
    if (!_noteAsked &&
        record.shouldAskNote(filledThisVisit: _filledThisVisit) &&
        mounted) {
      _noteAsked = true;
      await showNoteSheet(context, today, afterComplete: _filledThisVisit);
    }
    if (navigator.mounted && (route?.isCurrent ?? false)) navigator.pop();
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

  /// The water. In the cleanse of a heavy mood the dawn wash takes its place; in the settle the
  /// wash dissolves over the water.
  List<Widget> _releaseLayers(AppPalette p, AppLocalizations l10n) {
    final water = CustomPaint(
      painter: WaterPainter(
        sim: _sim,
        palette: p,
        bleed: CompleteTuning.shakeAmplitude,
      ),
    );
    if (!_hasRelease) return [water];
    final frame = _flow.frameAt(_services.now());
    return switch (frame.phase) {
      ReleasePhase.release => [water],
      ReleasePhase.cleanse => [DawnWash(progress: frame.cleanse)],
      ReleasePhase.settle => [
        water,
        Opacity(opacity: 1 - frame.blend, child: const DawnWash(progress: 1)),
      ],
    };
  }

  /// The one line, once the dawn wash is over.
  List<Widget> _settleLayers(AppLocalizations l10n) {
    if (!_hasRelease) return const [];
    final frame = _flow.frameAt(_services.now());
    if (frame.phase != ReleasePhase.settle) return const [];
    final line = settleLineFor(l10n, widget.mood);
    return [
      if (line != null)
        Align(
          alignment: const Alignment(0, 0.6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            child: SettleLine(text: line),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return PopScope(
      // The default back gesture stays on. Only an exit that is already under way blocks a second
      // one. A system exit writes what is waiting and asks for the note after the screen is gone.
      canPop: !_leaving,
      onPopInvokedWithResult: (didPop, _) {
        // The back button pops this route itself after its own sheet, so only a system exit
        // that did not start from _leave asks here.
        if (didPop && !_leaving) unawaited(_afterSystemExit());
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            _size = constraints.biggest;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: l10n.tap_action,
                    onTap: _tapFromAction,
                    child: Focus(
                      autofocus: true,
                      onKeyEvent: _onKey,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _onPointerDown,
                        onPointerMove: _onPointerMove,
                        onPointerUp: _onPointerUp,
                        onPointerCancel: _onPointerCancel,
                        child: AnimatedBuilder(
                          animation: _sim,
                          builder: (context, _) => ClipRect(
                            child: Transform.translate(
                              offset: _shakeOffset(_services.now()),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ..._releaseLayers(p, l10n),
                                  CheerOverlay(
                                    phrases: _phrases,
                                    now: _services.now,
                                  ),
                                  ..._settleLayers(l10n),
                                ],
                              ),
                            ),
                          ),
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
                            icon: LineIcons.back,
                            semanticLabel: l10n.common_back,
                            onTap: _leave,
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Row(
                              children: [
                                MoodFace(mood: widget.mood, size: 28),
                                const SizedBox(width: Space.sm),
                                Flexible(
                                  child: Text(
                                    moodName(context, widget.mood),
                                    style: TypeScale.title.copyWith(
                                      color: p.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_services.settingsBuilder != null) ...[
                            const SizedBox(width: Space.md),
                            PressableSurface.icon(
                              icon: LineIcons.settings,
                              semanticLabel: l10n.settings_title,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: _services.settingsBuilder!,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: Space.md),
                          HowToButton(
                            onTap: () {
                              _dismissBubble();
                              showHowToPlaySheet(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showBubble)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: Space.lg + PressableSurface.iconSize + Space.xs,
                          right: Space.lg,
                        ),
                        child: HintBubble(text: l10n.howTo_bubble),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ListenableBuilder(
                      listenable: _services.journal,
                      builder: (context, _) {
                        final count = _services.journal.journal
                            .dayOf(DayKey.of(_services.now()))
                            .countOf(widget.mood);
                        return Align(
                          alignment: Alignment(0, _hintAlignY),
                          child: Opacity(
                            opacity: count > FillTuning.hintUntilCount ? 0 : 1,
                            child: Text(
                              l10n.tap_hint,
                              style: TypeScale.label.copyWith(
                                color: p.inkMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _countBottom,
                  child: IgnorePointer(
                    child: ListenableBuilder(
                      listenable: _services.journal,
                      builder: (context, _) {
                        final count = _services.journal.journal
                            .dayOf(DayKey.of(_services.now()))
                            .countOf(widget.mood);
                        final shown = max(0, count - _spilledTaps);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$shown',
                              style: TypeScale.count.copyWith(color: p.ink),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              l10n.tap_todayLabel,
                              style: TypeScale.label.copyWith(
                                color: p.inkMuted,
                              ),
                            ),
                          ],
                        );
                      },
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
