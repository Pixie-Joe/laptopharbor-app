// lib/screens/shipping_address_screen.dart

import 'package:flutter/material.dart';
import '../backend/db/database.dart';
import '../backend/models/address.dart';
import 'add_address_screen.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  List<Address> addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // Load all addresses from database
  Future<void> _loadAddresses() async {
    final list = await AppDatabase.instance.getAllAddresses();
    setState(() {
      addresses = list;
    });
  }

  // Delete address
  Future<void> _deleteAddress(int id) async {
    await AppDatabase.instance.deleteAddress(id);
    await _loadAddresses();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address deleted')),
    );
  }

  // Navigate to Add/Edit screen and reload list after
  Future<void> _navigateToAddEdit({Address? address}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(
          isEditing: address != null,
          address: address,
        ),
      ),
    );
    if (result == true) {
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Shipping Address',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87, size: 28),
            onPressed: () => _navigateToAddEdit(),
            tooltip: 'Add new address',
          ),
        ],
      ),
      body: addresses.isEmpty
          ? const Center(child: Text("No addresses added yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Default Badge
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF00B4D8)),
                          const SizedBox(width: 8),
                          Text(
                            address.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4D8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: Color(0xFF00B4D8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(address.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(address.street),
                      Text('${address.city}, ${address.state} ${address.postalCode}'),
                      Text(address.country),
                      const SizedBox(height: 16),
                      // Edit / Delete Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _navigateToAddEdit(address: address),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B4D8)),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteAddress(address.id!),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
