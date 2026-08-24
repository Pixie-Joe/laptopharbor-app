import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../db/db_helper.dart';

class UserService {
  final DBHelper _dbHelper = DBHelper();

  /// Register user — columns MUST match your DB schema exactly.
  Future<bool> registerUser(String name, String email, String password) async {
    try {
      final Database db = await _dbHelper.db; // your getter is named `db`

      final normalizedEmail = email.trim().toLowerCase();

      // Check if email already exists
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );

      if (existing.isNotEmpty) {
        // email already present
        return false;
      }

      // Generate a random salt and compute a SHA-256(salt + password)
      final saltBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final salt = base64UrlEncode(saltBytes);
      final hash = sha256.convert(utf8.encode(salt + password)).toString();

      // Insert using exact column names from your DB schema
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

      // Fetch user by email
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

      final attemptHash = sha256.convert(utf8.encode(storedSalt + password)).toString();
      if (attemptHash != storedHash) return null;

      // Create a session token valid for 7 days
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

      // Return user data plus token
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

      // Compute new salt+hash
      final saltBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      final salt = base64UrlEncode(saltBytes);
      final hash = sha256.convert(utf8.encode(salt + newPassword)).toString();

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

