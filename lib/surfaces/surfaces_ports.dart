import 'widget_snapshot.dart';

/// Puts a snapshot where the native home screen widgets read it and asks them to redraw.
abstract interface class WidgetPublisher {
  Future<void> publish(WidgetSnapshot snapshot);
}

class ShortcutEntry {
  const ShortcutEntry({
    required this.type,
    required this.title,
    required this.icon,
  });

  final String type;
  final String title;

  /// The name of the icon resource: a drawable on Android, an image set on iOS.
  final String icon;
}

/// The shortcuts of a long press on the app icon.
abstract interface class IconShortcuts {
  /// Starts listening. [onSelected] gets the type of the shortcut the user picked.
  Future<void> start(void Function(String type) onSelected);

  Future<void> register(List<ShortcutEntry> entries);
}

/// The links that open the app from a widget.
abstract interface class LaunchLinks {
  /// The link that started the app, or null when it was started another way.
  Future<Uri?> initialUri();

  /// Links that arrive while the app is running.
  Stream<Uri?> get uris;
}
