import 'dart:async';

import '../domain/day_key.dart';
import '../domain/day_record.dart';
import '../domain/mood.dart';
import '../domain/mood_journal.dart';
import '../l10n/app_localizations.g.dart';
import 'mood_label.dart';
import 'mood_links.dart';
import 'shortcut_order.dart';
import 'surfaces_ports.dart';
import 'widget_snapshot.dart';

/// Connects the app to what the web cannot reach: the home screen widget and the shortcuts of a
/// long press on the app icon. It only reads the day record and tells the app which mood to open.
class NativeSurfaces {
  NativeSurfaces({
    required this.widget,
    required this.shortcuts,
    required this.links,
    required this.onLaunchMood,
  });

  final WidgetPublisher widget;
  final IconShortcuts shortcuts;
  final LaunchLinks links;

  /// Opens the tap screen of this mood.
  final void Function(Mood mood) onLaunchMood;

  WidgetSnapshot? _lastPublished;
  StreamSubscription<Uri?>? _subscription;

  /// Starts listening for widget links and shortcut picks. Call once at startup.
  Future<void> start() async {
    await shortcuts.start(_launchShortcut);
    _subscription = links.uris.listen(_launchLink);
    _launchLink(await links.initialUri());
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Updates the widget with today's record. An unchanged snapshot is not sent again, and a
  /// failed send is tried again on the next call.
  Future<void> publishToday(DayRecord today) async {
    final snapshot = WidgetSnapshot.fromRecord(today);
    if (snapshot == _lastPublished) return;
    await widget.publish(snapshot);
    _lastPublished = snapshot;
  }

  /// Sets the long press shortcuts in the language of [l]: the four moods picked most in the last
  /// 14 days (see [shortcutOrder]). Call it every time the app opens and when the language changes,
  /// so the menu follows what the user picks.
  Future<void> registerShortcuts(
    AppLocalizations l,
    MoodJournal journal,
    DateTime now,
  ) => shortcuts.register([
    for (final mood in shortcutOrder(journal, DayKey.of(now)))
      ShortcutEntry(type: shortcutTypeFor(mood), title: moodLabel(l, mood)),
  ]);

  void _launchShortcut(String type) {
    final mood = moodFromShortcutType(type);
    if (mood != null) onLaunchMood(mood);
  }

  void _launchLink(Uri? uri) {
    final mood = moodFromUri(uri);
    if (mood != null) onLaunchMood(mood);
  }
}
