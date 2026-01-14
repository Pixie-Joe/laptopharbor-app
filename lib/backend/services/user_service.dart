import 'package:sqflite/sqflite.dart';
import '../db/db_helper.dart';

class UserService {
  final DBHelper _dbHelper = DBHelper();

  /// Register user — columns MUST match your DB schema exactly.
  Future<bool> registerUser(String name, String email, String password) async {
    try {
      final Database db = await _dbHelper.db; // your getter is named `db`

      final normalizedEmail = email.trim().toLowerCase();
      print('DEBUG: trying register -> $normalizedEmail');

      // Check if email already exists
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );
      print('DEBUG: existing users -> $existing');

      if (existing.isNotEmpty) {
        // email already present
        return false;
      }

      // Insert using exact column names from your DB schema
      final id = await db.insert(
        'users',
        {
          'email': normalizedEmail,
          'username': name,
          'password_hash': password,      // plain text for now (not secure)
          'display_name': name,
          'phone': '',
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      print('DEBUG: insert id -> $id');
      return id > 0;
    } catch (e, st) {
      print('ERROR registerUser: $e\n$st');
      return false;
    }
  }

  /// Login: returns user record map or null
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final Database db = await _dbHelper.db;
      final normalizedEmail = email.trim().toLowerCase();

      final rows = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [normalizedEmail, password],
        limit: 1,
      );

      print('DEBUG login rows -> $rows');
      if (rows.isNotEmpty) return rows.first;
      return null;
    } catch (e, st) {
      print('ERROR login: $e\n$st');
      return null;
    }
  }

  /// DEBUG helper: print all users to console
  Future<List<Map<String, Object?>>> debugListUsers() async {
    final Database db = await _dbHelper.db;
    final rows = await db.query('users');
    print('DB USERS: $rows');
    return rows;
  }
}
