// lib/backend/storage/wishlist_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../db/db_helper.dart';

class WishlistManager {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal() {
    _loadFromDb();
  }

  final List<Product> _wishlist = [];
  List<Product> get wishlist => _wishlist;

  Future<void> _loadFromDb({int userId = 0}) async {
    try {
      final db = await DBHelper().db;
      final rows = await db.query('wishlist', where: 'user_id = ?', whereArgs: [userId]);
      _wishlist.clear();
      for (var row in rows) {
        final productJson = row['product_json'] as String?;
        if (productJson == null) continue;
        final Map<String, dynamic> pj = json.decode(productJson);
        _wishlist.add(Product.fromJson(pj));
      }
    } catch (e) {
      debugPrint('WishlistManager._loadFromDb error: $e');
    }
  }

  /// Migrate wishlist rows from guest (user_id = 0) to provided userId
  Future<void> migrateGuestToUser(int userId) async {
    try {
      final db = await DBHelper().db;
      await db.update('wishlist', {'user_id': userId}, where: 'user_id = ?', whereArgs: [0]);
      await _loadFromDb(userId: userId);
    } catch (e) {
      debugPrint('WishlistManager.migrateGuestToUser error: $e');
    }
  }

  Future<void> add(Product product) async {
    if (!_wishlist.any((p) => p.id == product.id)) {
      _wishlist.add(product);
      final db = await DBHelper().db;
      final now = DateTime.now().toIso8601String();
      final productJson = json.encode({
        'id': product.id,
        'name': product.name,
        'brand': product.brand,
        'category': product.category,
        'price': product.price,
        'originalPrice': product.originalPrice,
        'discount': product.discount,
        'specs': product.specs,
        'image': product.image,
        'description': product.description,
      });
      await db.insert('wishlist', {
        'user_id': 0,
        'product_id': product.id,
        'created_at': now,
        'product_json': productJson,
      });
    }
  }

  Future<void> remove(Product product) async {
    _wishlist.removeWhere((p) => p.id == product.id);
    final db = await DBHelper().db;
    await db.delete('wishlist', where: 'user_id = ? AND product_id = ?', whereArgs: [0, product.id]);
  }

  Future<void> clear() async {
    _wishlist.clear();
    final db = await DBHelper().db;
    await db.delete('wishlist', where: 'user_id = ?', whereArgs: [0]);
  }
}
