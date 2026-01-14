import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'habor_screen.dart';
import 'account_screen.dart';
import '../backend/storage/wishlist_manager.dart';
import '../backend/storage/cart_manager.dart';
import 'notifications_screen.dart';
import '../backend/models/product.dart';
import '../backend/models/notification.dart' as model_notif;

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _selectedIndex = 2;
  final wishlistManager = WishlistManager();
  final cartManager = CartManager();
  final Color oceanBlue = const Color(0xFF00B4D8);

  @override
  Widget build(BuildContext context) {
    final wishlist = wishlistManager.wishlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  "${wishlist.length} Items",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "in your wishlist",
                  style: TextStyle(color: Colors.black54),
                ),
                const Spacer(),

                // Add All to Cart
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oceanBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: wishlist.isEmpty
                      ? null
                      : () {
                          final notifications = <model_notif.AppNotification>[];
                          for (var product in wishlist) {
                            cartManager.addToCart(product);
                            notifications.add(
                              model_notif.AppNotification(
                                icon: Icons.shopping_cart_outlined,
                                iconColor: Colors.white,
                                iconBg: oceanBlue,
                                title: '${product.name} added to cart!',
                                subtitle: 'Your item was successfully added.',
                                time: 'Just now',
                              ),
                            );
                          }

                          // Optional: navigate to notification screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationsScreen(
                                notifications: notifications,
                              ),
                            ),
                          );

                          setState(() => wishlistManager.clear());
                        },
                  child: const Text("Add All to Cart"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: wishlist.isEmpty
                ? const Center(child: Text("Your wishlist is empty"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      final item = wishlist[index];
                      return _buildWishlistItem(item);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: oceanBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          Widget? screen;
          if (index == 0) screen = const HomeScreen();
          if (index == 1) screen = const HaborScreen();
          if (index == 2) screen = const WishlistScreen();
          if (index == 3) screen = const AccountScreen();
          if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.laptop_mac_sharp),
            label: "Shop",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.asset(
                "assets/images/${product.image}",
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        "\$${product.price}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),

                      // Add to cart button
                      IconButton(
                        onPressed: () {
                          cartManager.addToCart(product);

                          final notification = model_notif.AppNotification(
                            icon: Icons.shopping_cart_outlined,
                            iconColor: Colors.white,
                            iconBg: oceanBlue,
                            title: '${product.name} added to cart!',
                            subtitle: 'Your item was successfully added.',
                            time: 'Just now',
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationsScreen(
                                notifications: [notification],
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          color: oceanBlue,
                        ),
                      ),

                      // Remove from wishlist
                      IconButton(
                        onPressed: () =>
                            setState(() => wishlistManager.remove(product)),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
