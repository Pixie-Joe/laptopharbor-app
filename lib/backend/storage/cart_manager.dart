// lib/backend/storage/cart_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:laptopharbor/backend/models/product.dart';
import 'package:laptopharbor/backend/models/cart_item.dart';
import '../db/db_helper.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal() {
    // fire-and-forget load from DB
    _loadFromDb();
  }

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  Future<void> _loadFromDb({int userId = 0}) async {
    try {
      final db = await DBHelper().db;
      final rows = await db.query('cart_items', where: 'user_id = ?', whereArgs: [userId]);
      _cartItems.clear();
      for (var row in rows) {
        final productJson = row['product_json'] as String?;
        if (productJson == null) continue; // skip items without product data
        final Map<String, dynamic> pj = json.decode(productJson);
        final prod = Product.fromJson(pj);
        final qty = (row['quantity'] as int?) ?? 1;
        _cartItems.add(CartItem(product: prod, quantity: qty));
      }
    } catch (e) {
      // ignore DB errors for now
      debugPrint('CartManager._loadFromDb error: $e');
    }
  }

  /// Migrate any cart_items belonging to guest (user_id = 0) to the provided userId
  Future<void> migrateGuestToUser(int userId) async {
    try {
      final db = await DBHelper().db;
      await db.update('cart_items', {'user_id': userId}, where: 'user_id = ?', whereArgs: [0]);
      await _loadFromDb(userId: userId);
    } catch (e) {
      debugPrint('CartManager.migrateGuestToUser error: $e');
    }
  }

  Future<void> _persistItem(Product product, int quantity) async {
    final db = await DBHelper().db;
    final now = DateTime.now().toIso8601String();

    // Try update existing
    final existing = await db.query('cart_items', where: 'user_id = ? AND product_id = ?', whereArgs: [0, product.id], limit: 1);
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

    if (existing.isNotEmpty) {
      await db.update('cart_items', {
        'quantity': quantity,
        'product_json': productJson,
      }, where: 'user_id = ? AND product_id = ?', whereArgs: [0, product.id]);
    } else {
      await db.insert('cart_items', {
        'user_id': 0,
        'product_id': product.id,
        'quantity': quantity,
        'created_at': now,
        'product_json': productJson,
      });
    }
  }

  Future<void> addToCart(Product product) async {
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _cartItems[index].quantity += 1;
      await _persistItem(product, _cartItems[index].quantity);
    } else {
      final item = CartItem(product: product);
      _cartItems.add(item);
      await _persistItem(product, item.quantity);
    }
  }

  Future<void> removeFromCart(CartItem item) async {
    _cartItems.removeWhere((i) => i.product.id == item.product.id);
    final db = await DBHelper().db;
    await db.delete('cart_items', where: 'user_id = ? AND product_id = ?', whereArgs: [0, item.product.id]);
  }

  Future<void> increaseQuantity(CartItem item) async {
    item.quantity += 1;
    await _persistItem(item.product, item.quantity);
  }

  Future<void> decreaseQuantity(CartItem item) async {
    if (item.quantity > 1) {
      item.quantity -= 1;
      await _persistItem(item.product, item.quantity);
    } else {
      await removeFromCart(item);
    }
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    final db = await DBHelper().db;
    await db.delete('cart_items', where: 'user_id = ?', whereArgs: [0]);
  }
}
