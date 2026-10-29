import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KeyValueStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class SharedPreferencesStore implements KeyValueStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}
