import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/reminder/reminder_controller.dart';
import 'package:mood_clicker/reminder/reminder_port.dart';
import 'package:mood_clicker/reminder/reminder_settings.dart';

class FakeNotificationPort implements NotificationPort {
  final calls = <String>[];
  final scheduledAt = <DateTime>[];
  final scheduledIds = <int>[];
  bool permission = true;
  String? launchPayload;

  final _taps = StreamController<String>.broadcast();

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return permission;
  }

  @override
  Future<void> scheduleDaily(int id, DateTime at, ReminderText text) async {
    calls.add('schedule');
    scheduledIds.add(id);
    scheduledAt.add(at);
  }

  @override
  Future<void> cancel(int id) async => calls.add('cancel');

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> initialTap() async => launchPayload;
}

class MemoryReminderSettingsStore implements ReminderSettingsStore {
  ReminderSettings settings = const ReminderSettings();

  @override
  Future<ReminderSettings> read() async => settings;

  @override
  Future<void> write(ReminderSettings value) async => settings = value;
}

const text = ReminderText('title', 'body');
final morning = DateTime(2026, 11, 18, 8, 0);

void main() {
  test('load reads the stored settings', () async {
    final store = MemoryReminderSettingsStore()
      ..settings = const ReminderSettings(enabled: true, hour: 8, minute: 15);
    final controller = ReminderController(
      port: FakeNotificationPort(),
      store: store,
    );
    await controller.load();
    expect(
      controller.settings,
      const ReminderSettings(enabled: true, hour: 8, minute: 15),
    );
  });

  group('enable', () {
    test('permission is not touched before enabling', () async {
      final port = FakeNotificationPort();
      final controller = ReminderController(
        port: port,
        store: MemoryReminderSettingsStore(),
      );
      await controller.load();
      expect(port.calls, isNot(contains('requestPermission')));
    });

    test('a denial keeps the reminder off and schedules nothing', () async {
      final port = FakeNotificationPort()..permission = false;
      final controller = ReminderController(
        port: port,
        store: MemoryReminderSettingsStore(),
      );
      final enabled = await controller.enable(text, recordedToday: false);
      expect(enabled, isFalse);
      expect(controller.settings.enabled, isFalse);
      expect(port.calls, isNot(contains('schedule')));
    });

    test('a grant turns it on and schedules tonight', () async {
      final port = FakeNotificationPort();
      final controller = ReminderController(
        port: port,
        store: MemoryReminderSettingsStore(),
      );
      final enabled = await controller.enable(
        text,
        recordedToday: false,
        now: morning,
      );
      expect(enabled, isTrue);
      expect(controller.settings.enabled, isTrue);
      expect(port.scheduledAt.single, DateTime(2026, 11, 18, 21, 0));
    });
  });

  test('disable clears the notification and keeps the setting off', () async {
    final port = FakeNotificationPort();
    final controller = ReminderController(
      port: port,
      store: MemoryReminderSettingsStore(),
    );
    await controller.enable(text, recordedToday: false, now: morning);
    await controller.disable();
    expect(controller.settings.enabled, isFalse);
    expect(port.calls.last, 'cancel');
    expect(port.calls.where((c) => c == 'schedule'), hasLength(1));
  });

  group('setTime', () {
    test('persists the new minute and reschedules', () async {
      final port = FakeNotificationPort();
      final store = MemoryReminderSettingsStore();
      final controller = ReminderController(port: port, store: store);
      await controller.enable(text, recordedToday: false, now: morning);
      await controller.setTime(
        20,
        30,
        text,
        recordedToday: false,
        now: morning,
      );
      expect(
        controller.settings,
        const ReminderSettings(enabled: true, hour: 20, minute: 30),
      );
      expect(port.scheduledAt.last, DateTime(2026, 11, 18, 20, 30));
      expect(await store.read(), controller.settings);
    });

    test('while off keeps the reminder off', () async {
      final port = FakeNotificationPort();
      final controller = ReminderController(
        port: port,
        store: MemoryReminderSettingsStore(),
      );
      await controller.setTime(
        20,
        30,
        text,
        recordedToday: false,
        now: morning,
      );
      expect(controller.settings.enabled, isFalse);
      expect(port.calls, isNot(contains('schedule')));
    });
  });

  group('refresh', () {
    Future<ReminderController> enabledController(
      FakeNotificationPort port,
    ) async {
      final controller = ReminderController(
        port: port,
        store: MemoryReminderSettingsStore()
          ..settings = const ReminderSettings(enabled: true),
      );
      await controller.load();
      return controller;
    }

    test('a recorded day moves the series to tomorrow', () async {
      final port = FakeNotificationPort();
      final controller = await enabledController(port);
      await controller.refresh(text: text, recordedToday: true, now: morning);
      expect(port.scheduledAt.single, DateTime(2026, 11, 19, 21, 0));
    });

    test('an off reminder only cancels', () async {
      final port = FakeNotificationPort();
      final controller = ReminderController(
        port: port,
        store: MemoryReminderSettingsStore(),
      );
      await controller.refresh(text: text, recordedToday: false, now: morning);
      expect(port.calls.single, 'cancel');
    });

    test(
      'the old notification is cancelled before the new one is set',
      () async {
        final port = FakeNotificationPort();
        final controller = await enabledController(port);
        await controller.refresh(
          text: text,
          recordedToday: false,
          now: morning,
        );
        expect(port.calls, ['cancel', 'schedule']);
      },
    );

    test(
      'repeated refreshes keep one id, so at most one notification a day',
      () async {
        final port = FakeNotificationPort();
        final controller = await enabledController(port);
        await controller.refresh(
          text: text,
          recordedToday: false,
          now: morning,
        );
        await controller.refresh(
          text: text,
          recordedToday: false,
          now: morning,
        );
        expect(port.scheduledIds, [
          reminderNotificationId,
          reminderNotificationId,
        ]);
        expect(port.calls, ['cancel', 'schedule', 'cancel', 'schedule']);
      },
    );
  });
}
