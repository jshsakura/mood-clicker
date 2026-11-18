import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../design/theme_choice.dart';
import '../domain/cheer.dart';
import '../domain/cheer_picker.dart';
import '../domain/feel_settings.dart';
import '../domain/json_file_mood_repository.dart';
import '../domain/mood.dart';
import '../feedback/feedback_controller.dart';
import '../feedback/soloud_sound.dart';
import '../feedback/system_haptics.dart';
import '../l10n/asset_paths.dart';
import '../surfaces/home_widget_adapters.dart';
import '../surfaces/native_surfaces.dart';
import 'app_services.dart';
import 'journal_store.dart';

/// The tilt of the phone as an angle: 0 upright, positive when the right edge leans down.
/// The accelerometer reads the direction opposite to gravity, so a right edge that goes down
/// makes x negative. The sign needs a check on a real device.
Stream<double> phoneTilt() =>
    accelerometerEventStream().map((event) => atan2(-event.x, event.y));

/// Builds the real services: files in the app's own folder, the phone's haptics, sound and tilt.
Future<AppServices> createServices({WidgetBuilder? settingsBuilder}) async {
  final folder = await getApplicationSupportDirectory();
  final journal = JournalStore(
    JsonFileMoodRepository(File('${folder.path}/journal.json')),
  );
  final deckStore = JsonFileCheerDeckStore(
    File('${folder.path}/cheer_decks.json'),
  );
  final sound = SoloudSound();
  // The sound engine starts on its own; a failure leaves the app silent, never stuck.
  unawaited(sound.init());

  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets().toSet();
  final books = <String, Future<CheerBook>>{};

  return AppServices(
    journal: journal,
    feedback: FeedbackController(haptics: SystemHaptics(), sound: sound),
    loadCheers: (code) => books.putIfAbsent(code, () async {
      final path = cheersAssetPath(code, assets.contains);
      final text = await rootBundle.loadString(path);
      return (await CheerBook.parseInBackground(text)).book;
    }),
    cheerPicker: await CheerPicker.open(Random(), deckStore),
    deckStore: deckStore,
    feel: ValueNotifier(const FeelSettings()),
    tilt: phoneTilt,
    theme: ValueNotifier(const ThemeChoice.named('light')),
    settingsBuilder: settingsBuilder,
    surfaces: NativeSurfaces(
      widget: HomeWidgetPublisher(),
      shortcuts: QuickActionsShortcuts(),
      links: HomeWidgetLaunchLinks(),
      // The app replaces this once it is running (see SurfaceSync).
      onLaunchMood: (Mood _) {},
    ),
  );
}
