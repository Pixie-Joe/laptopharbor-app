// lib/backend/storage/cart_manager.dart
import 'package:laptopharbor/backend/models/product.dart';
import 'package:laptopharbor/backend/models/cart_item.dart';

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  void addToCart(Product product) {
    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      cartItems[index].quantity += 1;
    } else {
      cartItems.add(CartItem(product: product));
    }
  }

  void removeFromCart(CartItem item) {
    cartItems.remove(item);
  }

  void increaseQuantity(CartItem item) {
    item.quantity += 1;
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity -= 1;
    } else {
      removeFromCart(item); // optional: remove if quantity goes below 1
    }
  }

  void clearCart() {
    cartItems.clear();
  }
}
