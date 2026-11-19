import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import 'mood_face_mark.dart';
import 'surfaces_ports.dart';
import 'widget_snapshot.dart';

/// The iOS app group the app and the widget extension share. It is also set on the Runner and
/// MoodWidget targets in Xcode (see docs/NATIVE_SURFACES.md).
const String widgetAppGroupId = 'group.com.example.moodClicker';

/// The widget class names the native sides use. They must match the Kotlin class and the Swift `kind`.
const String androidWidgetName = 'MoodWidgetProvider';
const String iosWidgetKind = 'MoodWidget';

/// The key of the face picture the native widgets draw.
const String faceImageKey = 'face_png';

/// Real adapter on top of the `home_widget` package.
class HomeWidgetPublisher implements WidgetPublisher {
  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    if (Platform.isIOS) await HomeWidget.setAppGroupId(widgetAppGroupId);
    for (final entry in snapshot.toData().entries) {
      await HomeWidget.saveWidgetData<Object>(entry.key, entry.value);
    }
    final mood = snapshot.mood;
    if (mood == null) {
      await HomeWidget.saveWidgetData<String>(faceImageKey, null);
    } else {
      await HomeWidget.renderFlutterWidget(
        MoodFaceMark(mood: mood),
        key: faceImageKey,
        logicalSize: const Size.square(96),
        pixelRatio: 3,
      );
    }
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      iOSName: iosWidgetKind,
    );
  }
}

class HomeWidgetLaunchLinks implements LaunchLinks {
  @override
  Future<Uri?> initialUri() => HomeWidget.initiallyLaunchedFromHomeWidget();

  @override
  Stream<Uri?> get uris => HomeWidget.widgetClicked;
}

/// Real adapter on top of the `quick_actions` package.
class QuickActionsShortcuts implements IconShortcuts {
  final QuickActions _quickActions = const QuickActions();

  @override
  Future<void> start(void Function(String type) onSelected) =>
      _quickActions.initialize(onSelected);

  @override
  Future<void> register(List<ShortcutEntry> entries) =>
      _quickActions.setShortcutItems([
        for (final e in entries)
          ShortcutItem(type: e.type, localizedTitle: e.title, icon: e.icon),
      ]);
}
