import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../backend/storage/cart_manager.dart';
import 'notifications_screen.dart';
import '../backend/models/notification.dart' as model_notif;
import '../backend/db/db_helper.dart';
import '../backend/services/payment_service.dart';

final cartManager = CartManager();

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String updatedAddress = '123 Main Street, Apt 4B\nNew York, NY 10001';
  String updatedPayment = 'Visa ending in 4242';

  Future<void> _editAddress() async {
    final controller = TextEditingController(text: updatedAddress);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Address'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                updatedAddress = controller.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editPayment() async {
    final controller = TextEditingController(text: updatedPayment);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Payment Method'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                updatedPayment = controller.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Attempts to charge via the local Stripe backend and present the native PaymentSheet.
  // Returns true when the payment completed successfully. Returns false when Stripe is
  // not configured or when an error occurred - the caller should fall back to the stub.
  Future<bool> _processStripePayment(double amount) async {
    try {
      final publishableKey = Stripe.publishableKey;
      if (publishableKey == null || publishableKey.isEmpty) {
        // Stripe not configured; let the caller fall back to the stubbed flow.
        return false;
      }

      // Backend expects amount in cents
      final url = Uri.parse('http://10.0.2.2:4242/create-payment-intent');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': (amount * 100).toInt(), 'currency': 'usd'}),
      );

      if (resp.statusCode != 200) {
        print('PaymentIntent creation failed: ${resp.statusCode} ${resp.body}');
        return false;
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final clientSecret = body['clientSecret'] as String?;
      if (clientSecret == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'LaptopHarbor (Test)',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (e) {
      print('Stripe payment error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = cartManager.cartItems;
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    final shipping = 10.0;
    final tax = subtotal * 0.08;
    final total = subtotal + shipping + tax;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text('Your cart is empty', style: TextStyle(fontSize: 18)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAddressCard(),

                  const SizedBox(height: 24),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentCard(),

                  const SizedBox(height: 24),
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // --- Cart Items List ---
                  ...cartItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity} x ${item.product.name}'),
                          Text(
                            '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32, thickness: 1),
                  _buildSummaryRow(
                    'Subtotal',
                    '\$${subtotal.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow(
                    'Shipping',
                    '\$${shipping.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
                  const Divider(height: 32, thickness: 1),
                  _buildSummaryRow(
                    'Total',
                    '\$${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),

                  const SizedBox(height: 30),
                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // First try the Stripe-native flow if configured.
                        bool stripeSuccess = false;
                        try {
                          stripeSuccess = await _processStripePayment(total);
                        } catch (e) {
                          print('Stripe flow error: $e');
                          stripeSuccess = false;
                        }

                        if (!stripeSuccess) {
                          // Fall back to the existing PaymentService stub
                          final paymentResult = await PaymentService()
                              .processPayment(amount: total, method: updatedPayment);

                          if (!paymentResult.success) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Payment failed: ${paymentResult.message}'),
                              backgroundColor: Colors.red.shade400,
                            ));
                            return;
                          }
                        }

                        // Persist order to DB
                        try {
                          final db = await DBHelper().db;
                          final now = DateTime.now().toIso8601String();
                          final orderId = await db.insert('orders', {
                            'user_id': 0,
                            'total_amount': total,
                            'shipping_address': updatedAddress,
                            'status': 'placed',
                            'created_at': now,
                          });

                          // Insert order_items
                          for (var item in cartItems) {
                            await db.insert('order_items', {
                              'order_id': orderId,
                              'product_id': item.product.id,
                              'quantity': item.quantity,
                              'price': item.product.price,
                            });
                          }
                        } catch (e) {
                          print('Error persisting order: $e');
                        }

                        // Create the notification
                        final notifications = [
                          model_notif.AppNotification(
                            icon: Icons.check_circle_outline,
                            iconColor: Colors.white,
                            iconBg: const Color(0xFF00B4D8),
                            title: 'Order Placed!',
                            subtitle: 'Your order has been successfully placed.',
                            time: 'Just now',
                          ),
                        ];

                        // Clear the cart
                        await CartManager().clearCart();

                        // Navigate to NotificationsScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(
                              notifications: notifications,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Place Order (\$${total.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressCard() {
    return GestureDetector(
      onTap: _editAddress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF00B4D8)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                updatedAddress,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            const Icon(Icons.edit, color: Color(0xFF00B4D8)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return GestureDetector(
      onTap: _editPayment,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card, size: 40, color: Color(0xFF00B4D8)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                updatedPayment,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            const Icon(Icons.edit, color: Color(0xFF00B4D8)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 22 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF00B4D8) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
