import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../design/app_theme.dart';
import '../design/parts/line_icon.dart';
import '../design/parts/mood_face.dart';
import '../design/parts/pressable_surface.dart';
import '../design/tokens.g.dart';
import '../domain/mood.dart';
import '../l10n/app_localizations.g.dart';
import 'geo.dart';
import 'h3_grid.dart';
import 'hex_grid.dart';
import 'map_backdrop.dart';
import 'map_defaults.dart';
import 'map_rules.dart';
import 'map_source.dart';
import 'maplibre_backdrop.dart';

/// The map around me: a real map to drag and zoom, a hexagon grid of one-kilometer blocks over
/// it with a mood face and a head count on every block that is shown, a range switch on top and
/// a sheet below. The map ground is drawn by a [MapBackdropBuilder]; everything on top of it is
/// drawn here.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.source,
    this.grid,
    this.backdrop = _realBackdrop,
    this.ratio = const RatioPolicy(),
    this.justRecorded,
  });

  /// Defaults to the source of the app services.
  final MapSource? source;

  /// Defaults to the H3 grid.
  final HexGrid? grid;

  /// Draws the ground. Defaults to the MapLibre map.
  final MapBackdropBuilder backdrop;

  /// The ratio switches. The defaults are the constants of [MapRules].
  final RatioPolicy ratio;

  /// The mood tapped last today, which [RatioPolicy.hideAfterHeavyMood] looks at.
  final Mood? justRecorded;

  static Widget _realBackdrop(BuildContext context, MapBackdropLink link) =>
      MapLibreBackdrop(link: link);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapRange _range = MapRange.today;
  MapSnapshot? _snapshot;
  H3CellId? _picked;
  bool _sheetOpen = true;

  MapViewport? _viewport;
  bool _tooWide = false;
  bool _moving = false;
  Map<H3CellId, Offset> _spots = const {};
  int _round = 0;
  HexGrid? _grid;
  late final MapBackdropLink _link;
  bool _linked = false;

  HexGrid get _hexGrid => _grid ??= widget.grid ?? H3Grid();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_linked) return;
    _linked = true;
    _link = MapBackdropLink(
      dark: context.palette.brightness == Brightness.dark,
      onViewport: _onViewport,
      onMoving: _onMoving,
      onTapGround: () {
        if (_picked != null) setState(() => _picked = null);
      },
    );
  }

  @override
  void dispose() {
    _link.hexes.dispose();
    super.dispose();
  }

  void _onMoving() {
    if (_moving || !mounted) return;
    setState(() => _moving = true);
  }

  void _onViewport(MapViewport viewport) {
    _viewport = viewport;
    _refresh();
  }

  /// Asks for the blocks in view and places them. A newer look at the map wins over an older one
  /// still on its way.
  Future<void> _refresh() async {
    final viewport = _viewport;
    if (viewport == null || !mounted) return;
    final round = ++_round;
    final wide = viewport.zoom < MapDefaults.minGridZoom;
    var cells = const <H3CellId>[];
    if (!wide) {
      try {
        cells = _hexGrid.cellsIn(viewport.bounds, limit: MapDefaults.maxBlocks);
      } on Object catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack, library: 'map'),
        );
      }
    }
    final tooWide = wide || cells.isEmpty;
    final source = widget.source ?? AppScope.of(context).mapSource;
    final snapshot = tooWide
        ? MapSnapshot(cells: const [])
        : await source.load(_range, cells);
    if (!mounted || round != _round) return;
    final shapes = [
      for (final c in snapshot.cells) HexShape(c.id, _hexGrid.boundary(c.id)),
    ];
    _link.hexes.value = shapes;
    final points = await _link.project([
      for (final s in shapes) centerOf(s.ring),
    ]);
    if (!mounted || round != _round) return;
    setState(() {
      _tooWide = tooWide;
      _snapshot = snapshot;
      _moving = false;
      _spots = {
        for (var i = 0; i < points.length; i++) shapes[i].id: points[i],
      };
      if (_picked != null && !_spots.containsKey(_picked)) _picked = null;
    });
  }

  void _setRange(MapRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final snapshot = _snapshot;
    return Scaffold(
      backgroundColor: p.mapGround,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.backdrop(context, _link),
                if (snapshot != null && !_moving)
                  for (final c in snapshot.cells)
                    if (_spots[c.id] case final spot?)
                      _marker(context, c, spot),
                Positioned(
                  left: Space.md,
                  bottom: Space.xs,
                  child: IgnorePointer(
                    child: Text(
                      MapDefaults.attribution,
                      style: TypeScale.label.copyWith(
                        color: p.inkMuted,
                        fontSize: 10,
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
              ],
            ),
          ),
          _Sheet(
            snapshot: snapshot,
            picked: _picked,
            ratio: widget.ratio,
            justRecorded: widget.justRecorded,
            tooWide: _tooWide,
            isSample:
                (widget.source ?? AppScope.of(context).mapSource)
                    is SampleMapSource,
            open: _sheetOpen,
            onToggle: () => setState(() => _sheetOpen = !_sheetOpen),
          ),
        ],
      ),
    );
  }

  /// The face and the head count of one shown block, on the middle of the block.
  Widget _marker(BuildContext context, MapCell c, Offset spot) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final on = _picked == c.id;
    final text = wordText(l10n, c.word);
    return Positioned(
      left: spot.dx - _markerWidth / 2,
      top: spot.dy - _markerHeight / 2,
      width: _markerWidth,
      height: _markerHeight,
      child: PressableSurface(
        kind: PressableKind.card,
        radius: Radii.pill,
        color: on ? p.surface : Colors.transparent,
        semanticLabel: l10n.map_spotLabel(text, c.taps),
        onTap: () => setState(() => _picked = on ? null : c.id),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MoodFace(mood: c.mood, size: _faceSize),
            Text(
              '${c.people}',
              style: TypeScale.label.copyWith(
                color: p.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _markerWidth = 44;
  static const double _markerHeight = 52;
  static const double _faceSize = 28;
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
    required this.tooWide,
    required this.open,
    required this.onToggle,
  });

  final MapSnapshot? snapshot;
  final H3CellId? picked;
  final RatioPolicy ratio;
  final Mood? justRecorded;
  final bool isSample;

  /// The view is too wide for blocks: the sheet asks to zoom in.
  final bool tooWide;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final snap = snapshot;
    final isEmpty = snap != null && snap.cells.isEmpty && !tooWide;
    MapCell? cell;
    for (final c in snap?.cells ?? const <MapCell>[]) {
      if (c.id == picked) cell = c;
    }
    final showRatio = !isEmpty && !tooWide && ratio.visible(justRecorded);
    final share = cell?.happyShare ?? snap?.happyShare;
    final String? where;
    final String headline;
    final String? line;
    if (tooWide) {
      where = null;
      headline = l10n.map_zoomIn;
      line = null;
    } else if (isEmpty) {
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
                if (isSample && !isEmpty && !tooWide) ...[
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
