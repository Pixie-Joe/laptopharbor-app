// lib/screens/edit_address_screen.dart
import 'package:flutter/material.dart';
import '../backend/models/address.dart';
import '../backend/db/database.dart';

class EditAddressScreen extends StatefulWidget {
  final Address address; // Use Address object for editing

  const EditAddressScreen({super.key, required this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _countryController;

  String selectedLabel = 'Home';
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;

    selectedLabel = address.title;
    isDefault = address.isDefault;

    _fullNameController = TextEditingController(text: address.fullName);
    _streetController = TextEditingController(text: address.street);
    _cityController = TextEditingController(text: address.city);
    _stateController = TextEditingController(text: address.state);
    _zipController = TextEditingController(text: address.postalCode);
    _countryController = TextEditingController(text: address.country);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedAddress = Address(
      id: widget.address.id,
      title: selectedLabel,
      fullName: _fullNameController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _zipController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: isDefault,
    );

    await AppDatabase.instance.updateAddress(updatedAddress);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true); // Return true to refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Address',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Selection
                  _buildLabelField("Label (Home, Office)"),
                  Wrap(
                    spacing: 12,
                    children: ['Home', 'Office'].map((label) {
                      final isSelected = selectedLabel == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selectedLabel = label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  _buildLabelField("Full Name"),
                  _buildTextField(_fullNameController, Icons.person),

                  const SizedBox(height: 20),

                  // Street Address
                  _buildLabelField("Street Address"),
                  _buildTextField(_streetController, Icons.location_on_outlined),

                  const SizedBox(height: 20),

                  // City
                  _buildLabelField("City"),
                  _buildTextField(_cityController, Icons.location_city_outlined),

                  const SizedBox(height: 20),

                  // State & ZIP
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelField("State"),
                            _buildTextField(_stateController, Icons.map_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelField("ZIP Code"),
                            _buildTextField(_zipController, Icons.pin_drop_outlined,
                                keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Country
                  _buildLabelField("Country"),
                  _buildTextField(_countryController, Icons.flag_outlined),

                  const SizedBox(height: 20),

                  // Default Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: isDefault,
                        onChanged: (value) => setState(() => isDefault = value!),
                      ),
                      const Text('Set as default address'),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelField(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
        ),
      ),
      validator: (value) => value?.isEmpty == true ? 'Required' : null,
    );
  }
}
