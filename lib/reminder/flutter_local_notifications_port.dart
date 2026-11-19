/// NotificationPort on top of flutter_local_notifications 23.
///
/// Android uses inexact repeating alarms, so the reminder lands close to
/// the chosen minute without an exact-alarm permission. iOS and macOS
/// repeat by calendar time. The receivers that keep the schedule across a
/// reboot live in the app manifest.
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_port.dart';

class FlutterLocalNotificationsPort implements NotificationPort {
  FlutterLocalNotificationsPort([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController.broadcast();

  tz.Location? _localZone;

  @override
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    _localZone = tz.getLocation(timezone.identifier);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked only when the user turns the reminder on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _taps.add(payload);
        }
      },
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (_plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
        case final android?) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (_plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
        case final ios?) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: false,
          ) ??
          false;
    }
    if (_plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
        case final macos?) {
      return await macos.requestPermissions(
            alert: true,
            badge: false,
            sound: false,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<void> scheduleDaily(int id, DateTime at, ReminderText text) async {
    final zone = _localZone ?? tz.local;
    await _plugin.zonedSchedule(
      id: id,
      title: text.title,
      body: text.body,
      payload: moodSelectPayload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_reminder',
          text.title,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      scheduledDate: tz.TZDateTime.from(at, zone),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(int id) {
    return _plugin.cancel(id: id);
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> initialTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}
