import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../db/db_helper.dart';

class UserService {
  final DBHelper _dbHelper = DBHelper();

  static const int _pbkdf2Iterations = 100000;
  static const int _pbkdf2KeyLength = 32;

  static String _generateSalt() {
    final saltBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(saltBytes);
  }

  static List<int> _xorBytes(List<int> a, List<int> b) {
    final out = <int>[];
    for (var i = 0; i < a.length; i++) {
      out.add(a[i] ^ b[i]);
    }
    return out;
  }

  static List<int> _intToBytesBigEndian(int value) {
    final buffer = Uint8List(4);
    buffer[0] = (value >> 24) & 0xff;
    buffer[1] = (value >> 16) & 0xff;
    buffer[2] = (value >> 8) & 0xff;
    buffer[3] = value & 0xff;
    return buffer;
  }

  static String _hashPassword(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    final mac = Hmac(sha256, passwordBytes);
    final output = <int>[];

    for (var blockIndex = 1; output.length < _pbkdf2KeyLength; blockIndex++) {
      var u = <int>[...saltBytes, ..._intToBytesBigEndian(blockIndex)];
      var t = <int>[];

      for (var i = 0; i < _pbkdf2Iterations; i++) {
        u = mac.convert(u).bytes;
        if (i == 0) {
          t = List<int>.from(u);
        } else {
          t = _xorBytes(t, u);
        }
      }

      output.addAll(t);
    }

    return base64UrlEncode(output.sublist(0, _pbkdf2KeyLength));
  }

  /// Register user — columns MUST match your DB schema exactly.
  Future<bool> registerUser(String name, String email, String password) async {
    try {
      final Database db = await _dbHelper.db;
      final normalizedEmail = email.trim().toLowerCase();

      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );

      if (existing.isNotEmpty) {
        return false;
      }

      final salt = _generateSalt();
      final hash = _hashPassword(password, salt);

      final id = await db.insert(
        'users',
        {
          'email': normalizedEmail,
          'username': name,
          'password_hash': hash,
          'password_salt': salt,
          'display_name': name,
          'phone': '',
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return id > 0;
    } catch (e, st) {
      debugPrint('ERROR registerUser: $e\n$st');
      return false;
    }
  }

  /// Login: returns user record map and session token or null
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final Database db = await _dbHelper.db;
      final normalizedEmail = email.trim().toLowerCase();

      final rows = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final userRow = rows.first;
      final storedSalt = userRow['password_salt'] as String?;
      final storedHash = userRow['password_hash'] as String?;
      if (storedSalt == null || storedHash == null) return null;

      final attemptHash = _hashPassword(password, storedSalt);
      if (attemptHash != storedHash) return null;

      final tokenBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      final token = base64UrlEncode(tokenBytes);
      final now = DateTime.now();
      final expires = now.add(const Duration(days: 7));

      await db.insert('sessions', {
        'user_id': userRow['id'],
        'token': token,
        'expires_at': expires.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      final result = Map<String, dynamic>.from(userRow);
      result['session_token'] = token;
      result['session_expires_at'] = expires.toIso8601String();
      return result;
    } catch (e, st) {
      debugPrint('ERROR login: $e\n$st');
      return null;
    }
  }

  /// Validate a session token and return the associated user row, or null if invalid
  Future<Map<String, dynamic>?> validateSession(String token) async {
    try {
      final Database db = await _dbHelper.db;
      final rows = await db.rawQuery('''
        SELECT u.* FROM users u
        JOIN sessions s ON s.user_id = u.id
        WHERE s.token = ? AND datetime(s.expires_at) > datetime('now')
        LIMIT 1
      ''', [token]);

      if (rows.isEmpty) return null;
      return rows.first;
    } catch (e, st) {
      debugPrint('ERROR validateSession: $e\n$st');
      return null;
    }
  }

  /// Logout: delete session token
  Future<bool> logout(String token) async {
    try {
      final Database db = await _dbHelper.db;
      final deleted = await db.delete('sessions', where: 'token = ?', whereArgs: [token]);
      return deleted > 0;
    } catch (e, st) {
      debugPrint('ERROR logout: $e\n$st');
      return false;
    }
  }

  /// Initiate a password reset: generate a token and save it on the user record (no email sent by default)
  Future<String?> initiatePasswordReset(String email) async {
    try {
      final Database db = await _dbHelper.db;
      final normalizedEmail = email.trim().toLowerCase();
      final rows = await db.query('users', where: 'email = ?', whereArgs: [normalizedEmail], limit: 1);
      if (rows.isEmpty) return null;
      final tokenBytes = List<int>.generate(24, (_) => Random.secure().nextInt(256));
      final token = base64UrlEncode(tokenBytes);
      final expiry = DateTime.now().add(const Duration(hours: 1));

      await db.update('users', {
        'password_reset_token': token,
        'password_reset_expiry': expiry.toIso8601String(),
      }, where: 'email = ?', whereArgs: [normalizedEmail]);

      return token;
    } catch (e, st) {
      debugPrint('ERROR initiatePasswordReset: $e\n$st');
      return null;
    }
  }

  /// Complete password reset with token
  Future<bool> resetPasswordWithToken(String email, String token, String newPassword) async {
    try {
      final Database db = await _dbHelper.db;
      final normalizedEmail = email.trim().toLowerCase();
      final rows = await db.query('users', where: 'email = ? AND password_reset_token = ?', whereArgs: [normalizedEmail, token], limit: 1);
      if (rows.isEmpty) return false;
      final row = rows.first;
      final expiryStr = row['password_reset_expiry'] as String?;
      if (expiryStr == null) return false;
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) return false;

      final salt = _generateSalt();
      final hash = _hashPassword(newPassword, salt);

      await db.update('users', {
        'password_hash': hash,
        'password_salt': salt,
        'password_reset_token': null,
        'password_reset_expiry': null,
      }, where: 'email = ?', whereArgs: [normalizedEmail]);

      return true;
    } catch (e, st) {
      debugPrint('ERROR resetPasswordWithToken: $e\n$st');
      return false;
    }
  }

  /// DEBUG helper: print all users to console
  Future<List<Map<String, Object?>>> debugListUsers() async {
    final Database db = await _dbHelper.db;
    final rows = await db.query('users');
    debugPrint('DB USERS: $rows');
    return rows;
  }
}

