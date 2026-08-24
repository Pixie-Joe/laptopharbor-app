// lib/backend/db/database.dart

import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import '../models/address.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  final DBHelper _dbHelper = DBHelper();

  Future<Database> get database async {
    return await _dbHelper.db;
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
