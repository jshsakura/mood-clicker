import 'package:shared_preferences/shared_preferences.dart';

import 'locale_choice.dart';

/// Keeps the language choice in shared preferences.
class SharedPreferencesLocaleChoiceStore implements LocaleChoiceStore {
  SharedPreferencesLocaleChoiceStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'locale_choice';

  @override
  Future<LocaleChoice> read() async => _choiceFromName(_prefs.getString(_key));

  @override
  Future<void> write(LocaleChoice choice) async {
    await _prefs.setString(_key, choice.name);
  }
}

LocaleChoice _choiceFromName(String? name) {
  for (final choice in LocaleChoice.values) {
    if (choice.name == name) {
      return choice;
    }
  }
  return LocaleChoice.system;
}
