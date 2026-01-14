// lib/backend/storage/wishlist_manager.dart
import '../models/product.dart';

class WishlistManager {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Product> _wishlist = [];
  List<Product> get wishlist => _wishlist;

  void add(Product product) {
    if (!_wishlist.any((p) => p.id == product.id)) {
      _wishlist.add(product);
    }
  }

  void remove(Product product) {
    _wishlist.removeWhere((p) => p.id == product.id);
  }

  void clear() {
    _wishlist.clear();
  }
}
