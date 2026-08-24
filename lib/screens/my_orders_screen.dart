// lib/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import '../backend/models/product.dart';
import '../backend/services/order_service.dart';

class Order {
  final int id;
  final String orderId;
  final List<Product> items;
  final double total;
  String status; // Active, Completed, Cancelled
  final String createdAt;

  Order({
    required this.id,
    required this.orderId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
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
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final rows = await _orderService.getOrdersForUser(0); // guest user
    setState(() {
      orders = rows
          .map((r) => Order(id: r.id, orderId: r.orderIdText, items: r.items, total: r.total, status: r.status, createdAt: r.createdAt))
          .toList();
    });
  }

  void markOrderAsCompleted(Order order) async {
    final ok = await _orderService.updateOrderStatus(order.id, 'Completed');
    if (ok) {
      setState(() {
        order.status = 'Completed';
      });
    }
  }

  void markOrderAsCancelled(Order order) async {
    final ok = await _orderService.updateOrderStatus(order.id, 'Cancelled');
    if (ok) {
      setState(() {
        order.status = 'Cancelled';
      });
    }
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
                color: Colors.black.withValues(alpha: 0.05),
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
