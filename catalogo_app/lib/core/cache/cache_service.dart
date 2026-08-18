import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _prefix = "cache_";
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  String _key(String key) => _prefix + key;

  String? getString(String key) => _prefs.getString(_key(key));

  Future<void> putString(String key, String value) async {
    await _prefs.setString(_key(key), value);
  }

  List<dynamic>? getJsonList(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> putJsonList(String key, List<dynamic> value) async {
    await putString(key, jsonEncode(value));
  }

  Future<void> remove(String key) async {
    await _prefs.remove(_key(key));
  }
}