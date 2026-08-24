// lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:laptopharbor/screens/cart_screen.dart';
import '../backend/models/notification.dart' as model_notif;
import 'notifications_screen.dart';
import '../backend/models/product.dart';
import 'checkout_screen.dart' hide cartManager;
import '../backend/storage/wishlist_manager.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Details', style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? Color(0xFF00B4D8) : Colors.grey,
            ),
            onPressed: () {
              setState(() => isWishlisted = !isWishlisted);
              final wishlistManager = WishlistManager();
              if (isWishlisted) {
                wishlistManager.add(product);
              } else {
                wishlistManager.remove(product);
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with scroll
          SingleChildScrollView(
            child: Column(
              children: [
                // Hero Image
                Hero(
                  tag: 'product-${product.id}',
                  child: Image.asset(
                    'assets/images/${product.image}',
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                ),

                // Details Card
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.category,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (product.discount.isNotEmpty)
                              Text(
                                '\$${product.originalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 120), // Space for bottom buttons
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Buttons — Fixed at bottom like your screenshot
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Add To Cart
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Add product to shared cart
                          cartManager.addToCart(product);

                          // Optional: create a notification for this addition
                          final notification = model_notif.AppNotification(
                            icon: Icons.shopping_cart_outlined,
                            iconColor: Colors.white,
                            iconBg: const Color(0xFF00B4D8),
                            title: '${product.name} added to cart!',
                            subtitle: 'Your item was successfully added.',
                            time: 'Just now',
                          );

                          // Navigate to notifications page with this notification
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(
                                notifications: [notification],
                              ),
                            ),
                          );

                          // Optionally show a quick SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              backgroundColor: const Color(0xFF00B4D8),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: const BorderSide(
                            color: Color(0xFF00B4D8),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Add To Cart',
                          style: TextStyle(
                            color: Color(0xFF00B4D8),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Buy Now
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          cartManager.clearCart();
                          cartManager.addToCart(product);

                          // Navigate directly to CheckoutScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );

                          // Optional: show a small SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} is ready for checkout!',
                              ),
                              backgroundColor: const Color(0xFF00B4D8),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4D8),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
