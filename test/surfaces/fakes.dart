import 'dart:async';

import 'package:mood_clicker/surfaces/surfaces_ports.dart';
import 'package:mood_clicker/surfaces/widget_snapshot.dart';

class FakeWidgetPublisher implements WidgetPublisher {
  final published = <WidgetSnapshot>[];

  @override
  Future<void> publish(WidgetSnapshot snapshot) async =>
      published.add(snapshot);
}

class FakeIconShortcuts implements IconShortcuts {
  void Function(String type)? handler;
  final registered = <List<ShortcutEntry>>[];

  @override
  Future<void> start(void Function(String type) onSelected) async =>
      handler = onSelected;

  @override
  Future<void> register(List<ShortcutEntry> entries) async =>
      registered.add(entries);
}

class FakeLaunchLinks implements LaunchLinks {
  FakeLaunchLinks({this.initial});

  Uri? initial;
  final controller = StreamController<Uri?>.broadcast();

  @override
  Future<Uri?> initialUri() async => initial;

  @override
  Stream<Uri?> get uris => controller.stream;
}
