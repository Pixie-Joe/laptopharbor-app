import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../db/db_helper.dart';
import '../models/product.dart';
import 'package:sqflite/sqflite.dart';

class ProductService {
  final DBHelper _dbHelper = DBHelper();

  /// Seed products from assets/products.json into the products table.
  /// If force is true, existing matching products will be updated.
  Future<int> seedProductsFromAssets({bool force = false}) async {
    final db = await _dbHelper.db;
    final String raw = await rootBundle.loadString('assets/products.json');
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
    final filters = data['filters'] as Map<String, dynamic>;

    int inserted = 0;

    for (final categoryEntry in filters.entries) {
      final category = categoryEntry.key;
      final brands = categoryEntry.value as Map<String, dynamic>;

      for (final brandEntry in brands.entries) {
        final brand = brandEntry.key;
        final productList = brandEntry.value as List<dynamic>;

        for (var p in productList) {
          final Map<String, dynamic> pj = p as Map<String, dynamic>;

          final String name = (pj['name'] as String).trim();
          final double price = (pj['price'] as num).toDouble();
          final double originalPrice = (pj['originalPrice'] as num?)?.toDouble() ?? price;
          final String discount = (pj['discount'] as String?) ?? '';
          final List<dynamic> specsList = pj['specs'] ?? [];

          final Map<String, dynamic> productRow = {
            'name': name,
            'brand': brand,
            'category': category,
            'price': price,
            'original_price': originalPrice,
            'discount': discount,
            'specs': json.encode(specsList),
            'image': pj['image'] ?? '',
            'description': pj['description'] ?? '',
          };

          final rows = await db.query(
            'products',
            where: 'name = ? AND brand = ? AND category = ?',
            whereArgs: [name, brand, category],
            limit: 1,
          );

          if (rows.isEmpty) {
            await db.insert('products', productRow, conflictAlgorithm: ConflictAlgorithm.abort);
            inserted += 1;
          } else if (force) {
            await db.update('products', productRow, where: 'id = ?', whereArgs: [rows.first['id']]);
          }
        }
      }
    }

    return inserted;
  }

  /// Return all products from the DB as a list of product models.
  /// This reads every product row from the products table.
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.db;
    final rows = await db.query('products');
    final List<Product> products = [];

    for (var row in rows) {
      final specsJson = row['specs'] as String?;
      final specs = specsJson != null ? List<String>.from(json.decode(specsJson)) : <String>[];

      products.add(Product(
        id: (row['id'] as int),
        name: row['name'] as String? ?? '',
        brand: row['brand'] as String? ?? '',
        category: row['category'] as String? ?? '',
        price: (row['price'] as num?)?.toDouble() ?? 0.0,
        originalPrice: (row['original_price'] as num?)?.toDouble() ?? ((row['price'] as num?)?.toDouble() ?? 0.0),
        discount: row['discount'] as String? ?? '',
        specs: specs,
        image: row['image'] as String? ?? '',
        description: row['description'] as String? ?? '',
      ));
    }

    return products;
  }
}
