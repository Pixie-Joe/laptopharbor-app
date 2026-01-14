// lib/backend/db/database.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/address.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('app_database.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        fullName TEXT NOT NULL,
        street TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        postalCode TEXT NOT NULL,
        country TEXT NOT NULL,
        isDefault INTEGER NOT NULL
      )
    ''');
  }

  // ---------------------------------------------
  // ADDRESS CRUD
  // ---------------------------------------------

  Future<int> insertAddress(Address address) async {
    final db = await database;

    // If this address is default, remove default from others
    if (address.isDefault) {
      await db.update(
        'addresses',
        {'isDefault': 0},
      );
    }

    return await db.insert('addresses', address.toMap());
  }

  Future<List<Address>> getAllAddresses() async {
    final db = await database;
    final maps = await db.query('addresses');

    return maps.map((map) => Address.fromMap(map)).toList();
  }

  Future<Address?> getDefaultAddress() async {
    final db = await database;

    final maps = await db.query(
      'addresses',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Address.fromMap(maps.first);
    }

    return null;
  }

  Future<int> updateAddress(Address address) async {
    final db = await database;

    // If this one is default, remove default from others
    if (address.isDefault) {
      await db.update('addresses', {'isDefault': 0});
    }

    return await db.update(
      'addresses',
      address.toMap(),
      where: 'id = ?',
      whereArgs: [address.id],
    );
  }

  Future<int> deleteAddress(int id) async {
    final db = await database;
    return await db.delete(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
