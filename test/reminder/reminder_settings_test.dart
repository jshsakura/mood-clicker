import 'package:flutter_test/flutter_test.dart';
import 'package:mood_clicker/reminder/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryReminderSettingsStore implements ReminderSettingsStore {
  ReminderSettings settings = const ReminderSettings();

  @override
  Future<ReminderSettings> read() async => settings;

  @override
  Future<void> write(ReminderSettings value) async => settings = value;
}

void main() {
  test('defaults are off at 21:00', () {
    const settings = ReminderSettings();
    expect(settings.enabled, isFalse);
    expect(settings.hour, 21);
    expect(settings.minute, 0);
  });

  test('copyWith changes only the given fields', () {
    const settings = ReminderSettings();
    expect(
      settings.copyWith(enabled: true),
      const ReminderSettings(enabled: true),
    );
    expect(
      settings.copyWith(hour: 20, minute: 30),
      const ReminderSettings(hour: 20, minute: 30),
    );
  });

  group('memory store', () {
    test('reads before the first write', () async {
      final store = MemoryReminderSettingsStore();
      expect(await store.read(), const ReminderSettings());
    });

    test('keeps the written settings', () async {
      final store = MemoryReminderSettingsStore();
      await store.write(
        const ReminderSettings(enabled: true, hour: 20, minute: 30),
      );
      expect(
        await store.read(),
        const ReminderSettings(enabled: true, hour: 20, minute: 30),
      );
    });
  });

  group('shared preferences store', () {
    test('reads the defaults when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(const {});
      final store = SharedPreferencesReminderSettingsStore(
        await SharedPreferences.getInstance(),
      );
      expect(await store.read(), const ReminderSettings());
    });

    test('round trips the settings', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesReminderSettingsStore(prefs);
      await store.write(
        const ReminderSettings(enabled: true, hour: 7, minute: 45),
      );
      expect(
        await store.read(),
        const ReminderSettings(enabled: true, hour: 7, minute: 45),
      );
    });
  });
}
