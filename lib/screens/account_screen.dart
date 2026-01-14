import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'habor_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'my_orders_screen.dart';
import 'shipping_address_screen.dart';
import 'help_center_screen.dart';
import 'login_screen.dart';
import '../backend/storage/user_manager.dart';
import 'dart:io';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedIndex = 3;
  final Color oceanBlue = const Color(0xFF00B4D8);

  final UserManager userManager = UserManager();

  @override
  void initState() {
    super.initState();

    // Refresh screen whenever currentUser changes
    userManager.currentUser.addListener(() {
      setState(() {});
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);

    Widget screen;
    if (index == 0) {
      screen = const HomeScreen();
    } else if (index == 1) {
      screen = const HaborScreen();
    } else if (index == 2) {
      screen = const WishlistScreen();
    } else {
      screen = const AccountScreen();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = userManager.currentUser.value;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROFILE BOX
            Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      userManager.currentUser.value?.profileImage != null
                      ? (userManager.currentUser.value!.profileImage!
                                .startsWith("assets/")
                            ? AssetImage(
                                userManager.currentUser.value!.profileImage!,
                              )
                            : FileImage(
                                    File(
                                      userManager
                                          .currentUser
                                          .value!
                                          .profileImage!,
                                    ),
                                  )
                                  as ImageProvider)
                      : const AssetImage("assets/images/profile.jpg"),
                ),
                const SizedBox(height: 10),

                Text(
                  user?.name ?? "No Name",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  user?.email ?? "No Email",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: oceanBlue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen()),
                    );

                    // Refresh on return
                    setState(() {});
                  },
                  child: const Text("Edit Profile"),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildMenuItem(
              Icons.shopping_bag_outlined,
              "My Orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                );
              },
            ),

            _buildMenuItem(
              Icons.location_on_outlined,
              "Shipping Address",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShippingAddressScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              Icons.help_outline,
              "Help Center",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
            ),

            // LOGOUT
            _buildMenuItem(
              Icons.logout,
              "Logout",
              isLogout: true,
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: oceanBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
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

  // MENU TILE
  Widget _buildMenuItem(
    IconData icon,
    String title, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? oceanBlue : Colors.black),
        title: Text(
          title,
          style: TextStyle(color: isLogout ? oceanBlue : Colors.black),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  // LOGOUT DIALOG
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, color: oceanBlue, size: 40),
            const SizedBox(height: 20),
            const Text(
              "Logout",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: oceanBlue),
              onPressed: () {
                userManager.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text("Logout"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
