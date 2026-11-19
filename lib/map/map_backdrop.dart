import 'package:flutter/widgets.dart';

import 'geo.dart';
import 'map_rules.dart';

/// One block to draw on the map: its id and its corners.
class HexShape {
  const HexShape(this.id, this.ring);

  final H3CellId id;
  final List<GeoPoint> ring;
}

/// The line between the map screen and the map that draws the ground. The screen owns the
/// blocks, the faces and the sheet; the backdrop only draws the ground and the hexagon outlines,
/// tells where it looks, and turns places into screen points. A test puts a fake backdrop here,
/// because the real map cannot draw in a widget test.
class MapBackdropLink {
  MapBackdropLink({
    required this.dark,
    required this.onViewport,
    required this.onMoving,
    required this.onTapGround,
  });

  /// Whether the ground is the dark style.
  final bool dark;

  /// The map stopped moving and looks at this now.
  final ValueChanged<MapViewport> onViewport;

  /// The map started moving: what sits on top of it should step aside until it stops.
  final VoidCallback onMoving;

  /// A tap on the ground.
  final VoidCallback onTapGround;

  /// The blocks to outline. The backdrop listens and redraws.
  final ValueNotifier<List<HexShape>> hexes = ValueNotifier(const []);

  /// Set by the backdrop: where [points] are on the screen of the map, in logical pixels.
  Future<List<Offset>> Function(List<GeoPoint> points) project =
      (points) async => const [];
}

typedef MapBackdropBuilder =
    Widget Function(BuildContext context, MapBackdropLink link);
