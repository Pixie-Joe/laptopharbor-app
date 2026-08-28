import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String keyName = 'userName';
  static const String keyToken = 'sessionToken';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveUserName(String name) async {
    await _storage.write(key: keyName, value: name);
  }

  static Future<String?> getUserName() async {
    try {
      return await _storage.read(key: keyName);
    } on Exception {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyName);
    }
  }

  static Future<void> saveSessionToken(String token) async {
    await _storage.write(key: keyToken, value: token);
  }

  static Future<String?> getSessionToken() async {
    try {
      return await _storage.read(key: keyToken);
    } on Exception {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyToken);
    }
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: keyToken);
    await _storage.delete(key: keyName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
    await prefs.remove(keyName);
  }
}
