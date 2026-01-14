// lib/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import '../backend/models/product.dart';

class Order {
  final String orderId;
  final List<Product> items;
  final double total;
  String status; // Active, Completed, Cancelled

  Order({
    required this.orderId,
    required this.items,
    required this.total,
    required this.status,
  });
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateDemoOrders();
  }

  void markOrderAsCompleted(Order order) {
    setState(() {
      order.status = "Completed";
    });
  }

  void markOrderAsCancelled(Order order) {
    setState(() {
      order.status = "Cancelled";
    });
  }

  void _generateDemoOrders() {
    orders = [
      Order(
        orderId: "#12345",
        items: [
          Product(
            id: 1,
            name: "ASUS ROG Strix G15",
            brand: "ASUS",
            category: "Gaming",
            price: 1499.0,
            originalPrice: 1799.0,
            discount: "17%",
            specs: ["16GB RAM", "1TB SSD", "RTX Graphics"],
            image: "ASUSROGStrixG15.jpg",
            description: "Dominate every game...",
          ),
        ],
        total: 1499.0,
        status: "Active",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders =
        orders.where((o) => o.status == "Active").toList();
    final completedOrders =
        orders.where((o) => o.status == "Completed").toList();
    final cancelledOrders =
        orders.where((o) => o.status == "Cancelled").toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // TABS
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00B4D8),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF00B4D8),
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Completed"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(activeOrders, isActiveTab: true),
                _buildOrderList(completedOrders),
                _buildOrderList(cancelledOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> list, {bool isActiveTab = false}) {
    if (list.isEmpty) {
      return const Center(child: Text("No orders here"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        final item = order.items.first;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ORDER HEADER
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/${item.image}',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Order ${order.orderId}\n\$${order.total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (isActiveTab)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => markOrderAsCompleted(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Received"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => markOrderAsCancelled(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  order.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: order.status == "Completed"
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
