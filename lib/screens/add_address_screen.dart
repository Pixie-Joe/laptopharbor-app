// lib/screens/add_address_screen.dart
import 'package:flutter/material.dart';
import '../backend/db/database.dart';
import '../backend/models/address.dart';

class AddEditAddressScreen extends StatefulWidget {
  final bool isEditing;
  final Address? address; // <- Use Address object for editing

  const AddEditAddressScreen({
    super.key,
    this.isEditing = false,
    this.address,
  });

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
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

    _titleController =
        TextEditingController(text: widget.address?.title ?? 'Home');
    selectedLabel = widget.address?.title ?? 'Home';

    _fullNameController =
        TextEditingController(text: widget.address?.fullName ?? '');
    _streetController =
        TextEditingController(text: widget.address?.street ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _zipController =
        TextEditingController(text: widget.address?.postalCode ?? '');
    _countryController =
        TextEditingController(text: widget.address?.country ?? '');
    isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

Future<void> _saveAddress() async {
  if (!_formKey.currentState!.validate()) return;

  final newAddress = Address(
    title: selectedLabel,
    fullName: _fullNameController.text.trim(),
    street: _streetController.text.trim(),
    city: _cityController.text.trim(),
    state: _stateController.text.trim(),
    postalCode: _zipController.text.trim(),
    country: _countryController.text.trim(),
    isDefault: isDefault,
  );

  if (widget.isEditing && widget.address != null) {
    // Editing
    final updatedAddress = Address(
      id: widget.address!.id,
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
  } else {
    // Adding new
    await AppDatabase.instance.insertAddress(newAddress);
  }

if (!mounted) return;
Navigator.pop(context, true); // <- important to reload the list
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
        title: Text(
          widget.isEditing ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
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
                  _buildLabelField("Full Name"),
                  _buildTextField(_fullNameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildLabelField("Street Address"),
                  _buildTextField(_streetController, Icons.location_on_outlined),
                  const SizedBox(height: 20),
                  _buildLabelField("City"),
                  _buildTextField(_cityController, Icons.location_city_outlined),
                  const SizedBox(height: 20),
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
                  _buildLabelField("Country"),
                  _buildTextField(_countryController, Icons.flag_outlined),
                  const SizedBox(height: 20),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        widget.isEditing ? 'Save Changes' : 'Save Address',
                        style: const TextStyle(
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
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
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
