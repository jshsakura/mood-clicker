import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../design/app_theme.dart';
import 'geo.dart';
import 'map_backdrop.dart';
import 'map_defaults.dart';

/// The real ground: a MapLibre vector map with the OpenFreeMap style, dragging and zooming. The
/// hexagon outlines are one GeoJSON source with a fill and a line layer.
class MapLibreBackdrop extends StatefulWidget {
  const MapLibreBackdrop({super.key, required this.link});

  final MapBackdropLink link;

  @override
  State<MapLibreBackdrop> createState() => _MapLibreBackdropState();
}

class _MapLibreBackdropState extends State<MapLibreBackdrop> {
  static const String _source = 'blocks';
  static const String _fill = 'blocks-fill';
  static const String _line = 'blocks-line';

  MapLibreMapController? _controller;
  bool _styleReady = false;

  @override
  void initState() {
    super.initState();
    widget.link.hexes.addListener(_drawHexes);
    widget.link.project = _project;
  }

  @override
  void dispose() {
    widget.link.hexes.removeListener(_drawHexes);
    super.dispose();
  }

  Future<List<Offset>> _project(List<GeoPoint> points) async {
    final controller = _controller;
    if (controller == null || points.isEmpty) return const [];
    final screen = await controller.toScreenLocationBatch([
      for (final point in points) LatLng(point.lat, point.lng),
    ]);
    return [for (final p in screen) Offset(p.x.toDouble(), p.y.toDouble())];
  }

  Map<String, dynamic> _geojson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final shape in widget.link.hexes.value)
        {
          'type': 'Feature',
          'properties': {'id': shape.id.value},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                for (final p in [...shape.ring, shape.ring.first])
                  [p.lng, p.lat],
              ],
            ],
          },
        },
    ],
  };

  Future<void> _drawHexes() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    try {
      await controller.setGeoJsonSource(_source, _geojson());
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'map backdrop',
        ),
      );
    }
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    final p = context.palette;
    await controller.addGeoJsonSource(_source, _geojson());
    await controller.addFillLayer(
      _source,
      _fill,
      FillLayerProperties(fillColor: _hex(p.ink), fillOpacity: 0.06),
    );
    await controller.addLineLayer(
      _source,
      _line,
      LineLayerProperties(
        lineColor: _hex(p.ink),
        lineOpacity: 0.45,
        lineWidth: 1.2,
      ),
    );
    _styleReady = true;
  }

  static String _hex(Color color) {
    final rgb = color.toARGB32() & 0xffffff;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  Future<void> _reportViewport() async {
    final controller = _controller;
    if (controller == null) return;
    final box = await controller.getVisibleRegion();
    final zoom = controller.cameraPosition?.zoom ?? MapDefaults.startZoom;
    if (!mounted) return;
    widget.link.onViewport(
      MapViewport(
        bounds: GeoBounds(
          south: box.southwest.latitude,
          west: box.southwest.longitude,
          north: box.northeast.latitude,
          east: box.northeast.longitude,
        ),
        zoom: zoom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const start = MapDefaults.startCenter;
    return MapLibreMap(
      styleString: widget.link.dark
          ? MapDefaults.darkStyle
          : MapDefaults.lightStyle,
      initialCameraPosition: CameraPosition(
        target: LatLng(start.lat, start.lng),
        zoom: MapDefaults.startZoom,
      ),
      trackCameraPosition: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
      myLocationEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.topRight,
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: () async {
        await _onStyleLoaded();
        await _reportViewport();
      },
      onCameraMove: (_) => widget.link.onMoving(),
      onCameraIdle: _reportViewport,
      onMapClick: (_, _) => widget.link.onTapGround(),
    );
  }
}
