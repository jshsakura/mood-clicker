import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.g.dart';
import '../domain/mood.dart';
import 'map_rules.dart';
import 'map_source.dart';

/// The map around me: a dotted ground, rings at 1 and 3 km, one word per block (sized by taps),
/// a range switch on top and a sheet below. Gray only; no mood gets a color here.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.source,
    this.ratio = const RatioPolicy(),
    this.justRecorded,
  });

  /// Defaults to the source of the app services.
  final MapSource? source;

  /// The ratio switches. The defaults are the constants of [MapRules].
  final RatioPolicy ratio;

  /// The mood tapped last today, which [RatioPolicy.hideAfterHeavyMood] looks at.
  final Mood? justRecorded;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapRange _range = MapRange.today;
  MapSnapshot? _snapshot;
  H3CellId? _picked;
  bool _started = false;
  bool _sheetOpen = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final source = widget.source ?? AppScope.of(context).mapSource;
    final range = _range;
    final snapshot = await source.load(range);
    if (!mounted || range != _range) return;
    setState(() => _snapshot = snapshot);
  }

  void _setRange(MapRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final snapshot = _snapshot;
    return Scaffold(
      backgroundColor: p.mapGround,
      body: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final unit = size.width * _unitShare;
          final center = Offset(size.width * _centerX, size.height * _centerY);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_picked != null) setState(() => _picked = null);
                  },
                  child: CustomPaint(
                    painter: _GroundPainter(
                      dot: p.mapLine,
                      center: center,
                      unit: unit,
                    ),
                  ),
                ),
              ),
              _RingLabel(
                text: _ring1,
                at: center - Offset(0, unit),
                color: p.inkMuted,
              ),
              _RingLabel(
                text: _ring3,
                at: center - Offset(0, unit * 3),
                color: p.inkMuted,
              ),
              if (snapshot != null) ..._words(context, snapshot, center, unit),
              Positioned(
                left: center.dx,
                top: center.dy,
                child: IgnorePointer(
                  child: Semantics(
                    label: l10n.map_you,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.ink.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: Space.xxxl),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.ink,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: p.mapGround,
                                width: Space.xs,
                              ),
                            ),
                            child: const SizedBox.square(dimension: Space.xl),
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
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Row(
                      children: [
                        PressableSurface.icon(
                          icon: LineIcons.back,
                          semanticLabel: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        _RangeSwitch(range: _range, onPick: _setRange),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Sheet(
                  snapshot: snapshot,
                  picked: _picked,
                  ratio: widget.ratio,
                  justRecorded: widget.justRecorded,
                  isSample:
                      (widget.source ?? AppScope.of(context).mapSource)
                          is SampleMapSource,
                  open: _sheetOpen,
                  onToggle: () => setState(() => _sheetOpen = !_sheetOpen),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _words(
    BuildContext context,
    MapSnapshot snapshot,
    Offset center,
    double unit,
  ) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final most = snapshot.cells.fold<int>(1, (m, c) => math.max(m, c.taps));
    return [
      for (final c in snapshot.cells)
        _word(context, c, center, unit, most, p, l10n),
    ];
  }

  Widget _word(
    BuildContext context,
    MapCell c,
    Offset center,
    double unit,
    int most,
    AppPalette p,
    AppLocalizations l10n,
  ) {
    final dx = c.eastKm;
    final dy = -c.northKm;
    final ratio = math.sqrt(c.taps / most);
    final size = (_wordMin + ratio * _wordSpan).roundToDouble();
    final angle = ((((dx * 7 + dy).round()) % 7) - 3) * math.pi / 180;
    final on = _picked == c.id;
    final text = wordText(l10n, c.word);
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _CenteredAt(center + Offset(dx * unit, dy * unit)),
        child: Transform.rotate(
          angle: angle,
          child: Opacity(
            opacity: _wordOpacityMin + ratio * (1 - _wordOpacityMin),
            child: PressableSurface(
              kind: PressableKind.card,
              radius: Radii.pill,
              color: on ? p.surface : Colors.transparent,
              semanticLabel: l10n.map_spotLabel(text, c.taps),
              onTap: () => setState(() => _picked = on ? null : c.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.sm,
                  vertical: Space.xs,
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  style: TypeScale.label.copyWith(
                    color: p.ink,
                    fontSize: size,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _unitShare = 0.2;
  static const double _centerX = 0.44;
  static const double _centerY = 0.355;
  static const double _wordMin = 11;
  static const double _wordSpan = 9;
  static const double _wordOpacityMin = 0.35;
  static const String _ring1 = '1km';
  static const String _ring3 = '3km';
}

/// The prepared sentence behind a word id.
String wordText(AppLocalizations l10n, MapWord word) => switch (word) {
  MapWord.smiled => l10n.map_wordSmiled,
  MapWord.rest => l10n.map_wordRest,
  MapWord.ateWell => l10n.map_wordAteWell,
  MapWord.betterThanExpected => l10n.map_wordBetterThanExpected,
  MapWord.tomorrowToo => l10n.map_wordTomorrowToo,
  MapWord.thankful => l10n.map_wordThankful,
};

class _RingLabel extends StatelessWidget {
  const _RingLabel({required this.text, required this.at, required this.color});

  final String text;
  final Offset at;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: Text(text, style: TypeScale.label.copyWith(color: color)),
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.dot, required this.center, required this.unit});

  final Color dot;
  final Offset center;
  final double unit;

  static const double _gap = 22;
  static const double _dotRadius = 1;
  static const int _dashes = 90;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = dot;
    for (var y = _gap / 2; y < size.height; y += _gap) {
      for (var x = _gap / 2; x < size.width; x += _gap) {
        canvas.drawCircle(Offset(x, y), _dotRadius, fill);
      }
    }
    final line = Paint()
      ..color = dot
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, unit, line);
    final outer = Rect.fromCircle(center: center, radius: unit * 3);
    const step = 2 * math.pi / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(outer, i * step, step / 3, false, line);
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) =>
      old.dot != dot || old.center != center || old.unit != unit;
}

class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.range, required this.onPick});

  final MapRange range;
  final ValueChanged<MapRange> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: p.mapGround,
        shape: StadiumBorder(side: BorderSide(color: p.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in [
              (MapRange.today, l10n.map_rangeToday),
              (MapRange.week, l10n.map_rangeWeek),
            ])
              PressableSurface(
                kind: PressableKind.card,
                radius: Radii.pill,
                color: range == value ? p.ink : Colors.transparent,
                selected: range == value,
                semanticLabel: label,
                onTap: () => onPick(value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.sm,
                  ),
                  child: Text(
                    label,
                    style: TypeScale.label.copyWith(
                      color: range == value ? p.mapGround : p.inkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.snapshot,
    required this.picked,
    required this.ratio,
    required this.justRecorded,
    required this.isSample,
    required this.open,
    required this.onToggle,
  });

  final MapSnapshot? snapshot;
  final H3CellId? picked;
  final RatioPolicy ratio;
  final Mood? justRecorded;
  final bool isSample;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final snap = snapshot;
    final isEmpty = snap != null && snap.cells.isEmpty;
    MapCell? cell;
    for (final c in snap?.cells ?? const <MapCell>[]) {
      if (c.id == picked) cell = c;
    }
    final showRatio = !isEmpty && ratio.visible(justRecorded);
    final share = cell?.happyShare ?? snap?.happyShare;
    final String? where;
    final String headline;
    final String? line;
    if (isEmpty) {
      where = l10n.map_nearby;
      headline = l10n.map_empty;
      line = null;
    } else if (cell != null) {
      where = l10n.map_pickedPlace;
      headline = '"${wordText(l10n, cell.word)}"';
      line = l10n.map_tapsLine(cell.taps);
    } else if (showRatio && share != null) {
      final happy = (share * 100).round();
      where = l10n.map_nearby;
      if (ratio.style == RatioStyle.percent) {
        headline = happy >= 50
            ? l10n.map_happySide(happy)
            : l10n.map_sadSide(100 - happy);
        line = l10n.map_peopleLine(snap!.people);
      } else {
        headline = happy >= 50 ? l10n.map_togetherHappy : l10n.map_togetherSad;
        line = null;
      }
    } else {
      where = null;
      headline = l10n.map_nearby;
      line = null;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.mapGround,
        border: Border(top: BorderSide(color: p.line)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.card),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Space.xl,
            Space.md,
            Space.xl,
            open ? Space.xl : Space.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FoldHandle(
                open: open,
                onToggle: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xs),
                  child: Center(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: p.line,
                        shape: const StadiumBorder(),
                      ),
                      child: const SizedBox(
                        width: Space.xxl + Space.xs,
                        height: Space.xs,
                      ),
                    ),
                  ),
                ),
              ),
              if (open) ...[
                const SizedBox(height: Space.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (where != null)
                            Text(
                              where,
                              style: TypeScale.label.copyWith(
                                color: p.inkMuted,
                              ),
                            ),
                          Text(
                            headline,
                            style: TypeScale.title.copyWith(color: p.ink),
                          ),
                        ],
                      ),
                    ),
                    if (line != null)
                      Text(
                        line,
                        style: TypeScale.label.copyWith(color: p.inkMuted),
                      ),
                  ],
                ),
                if (showRatio &&
                    ratio.style == RatioStyle.percent &&
                    share != null) ...[
                  const SizedBox(height: Space.lg),
                  _RatioBar(happyShare: share),
                ],
                if (isSample && !isEmpty) ...[
                  const SizedBox(height: Space.md),
                  Text(
                    l10n.map_sampleNotice,
                    style: TypeScale.label.copyWith(color: p.ink2),
                  ),
                ],
                const SizedBox(height: Space.lg),
                Text(
                  l10n.map_explain,
                  style: TypeScale.label.copyWith(color: p.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.happyShare});

  final double happyShare;

  static const int _scale = 1000;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final happy = (happyShare * _scale).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: SizedBox(
        height: Space.sm - Space.xs / 2,
        child: Row(
          children: [
            if (happy > 0)
              Expanded(
                flex: happy,
                child: ColoredBox(color: p.ink),
              ),
            if (happy < _scale) ...[
              if (happy > 0) const SizedBox(width: Space.xs / 2),
              Expanded(
                flex: _scale - happy,
                child: ColoredBox(color: p.mapLine),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Puts the child's center on a point. Unlike a translation, the child's box really sits there,
/// so a tap on it is found.
class _CenteredAt extends SingleChildLayoutDelegate {
  _CenteredAt(this.point);

  final Offset point;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      point - Offset(childSize.width / 2, childSize.height / 2);

  @override
  bool shouldRelayout(_CenteredAt old) => old.point != point;
}

/// The handle of the sheet: a tap folds or opens it, and so does a drag that is fast enough or
/// long enough, however slowly it goes.
class _FoldHandle extends StatefulWidget {
  const _FoldHandle({
    required this.open,
    required this.onToggle,
    required this.child,
  });

  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  /// A drag faster than this folds the sheet (logical pixels per second).
  static const double foldVelocity = 120;

  /// A drag longer than this folds it too, even a slow one.
  static const double foldDistance = 40;

  @override
  State<_FoldHandle> createState() => _FoldHandleState();
}

class _FoldHandleState extends State<_FoldHandle> {
  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('sheetHandle'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggle,
      onVerticalDragStart: (_) => _dragged = 0,
      onVerticalDragUpdate: (details) => _dragged += details.delta.dy,
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        final down =
            v > _FoldHandle.foldVelocity || _dragged > _FoldHandle.foldDistance;
        final up =
            v < -_FoldHandle.foldVelocity ||
            _dragged < -_FoldHandle.foldDistance;
        if (widget.open && down) widget.onToggle();
        if (!widget.open && up) widget.onToggle();
      },
      child: widget.child,
    );
  }
}
