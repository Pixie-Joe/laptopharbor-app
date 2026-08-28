import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../db/db_helper.dart';
import '../models/product.dart';

class OrderItemData {
  final int productId;
  final int quantity;
  final double price;

  OrderItemData({required this.productId, required this.quantity, required this.price});
}

class OrderData {
  final int id;
  final String orderIdText;
  final List<Product> items;
  final double total;
  String status;
  final String createdAt;

  OrderData({required this.id, required this.orderIdText, required this.items, required this.total, required this.status, required this.createdAt});
}

class OrderService {
  final DBHelper _dbHelper = DBHelper();

  Future<List<OrderData>> getOrdersForUser(int userId) async {
    final db = await _dbHelper.db;
    final orderRows = await db.query('orders', where: 'user_id = ?', whereArgs: [userId], orderBy: 'id DESC');

    final List<OrderData> orders = [];
    for (var row in orderRows) {
      final orderId = row['id'] as int;
      final total = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      final status = row['status'] as String? ?? 'Unknown';
      final createdAt = row['created_at'] as String? ?? '';

      final itemRows = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
      final List<Product> products = [];

      for (var it in itemRows) {
        final prodId = it['product_id'] as int;
        // Fetch product row
        final prodRows = await db.query('products', where: 'id = ?', whereArgs: [prodId], limit: 1);
        if (prodRows.isNotEmpty) {
          final prow = prodRows.first;
          final specsJson = prow['specs'] as String?;
          final specs = specsJson != null ? List<String>.from(json.decode(specsJson)) : <String>[];

          products.add(Product(
            id: prow['id'] as int,
            name: prow['name'] as String? ?? '',
            brand: prow['brand'] as String? ?? '',
            category: prow['category'] as String? ?? '',
            price: (prow['price'] as num?)?.toDouble() ?? 0.0,
            originalPrice: (prow['original_price'] as num?)?.toDouble() ?? ((prow['price'] as num?)?.toDouble() ?? 0.0),
            discount: prow['discount'] as String? ?? '',
            specs: specs,
            image: prow['image'] as String? ?? '',
            description: prow['description'] as String? ?? '',
          ));
        } else {
          // product missing from table; try product_json in order_items (not present in current schema)
        }
      }

      orders.add(OrderData(id: orderId, orderIdText: '#${orderId.toString().padLeft(5, '0')}', items: products, total: total, status: status, createdAt: createdAt));
    }

    return orders;
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final db = await _dbHelper.db;
      final updated = await db.update('orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
      return updated > 0;
    } catch (e) {
      debugPrint('OrderService.updateOrderStatus error: $e');
      return false;
    }
  }
}
