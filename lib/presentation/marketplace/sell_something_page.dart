import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
class SellSomethingPage extends StatefulWidget {
  const SellSomethingPage({super.key});

  @override
  State<SellSomethingPage> createState() => _SellSomethingPageState();
}

class _SellSomethingPageState extends State<SellSomethingPage> {
  List<String> _userShops = [];
  String? _selectedShop;

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    // For now, load a single shop name from SharedPreferences (simulate multiple shops for future)
    // In a real app, fetch from backend or user profile
    final prefs = await SharedPreferences.getInstance();
    final shopName = prefs.getString('shopName') ?? 'My Shop';
    setState(() {
      _userShops = [shopName];
      _selectedShop = shopName;
      _shopNameController.text = shopName;
    });
  }
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  // For dynamic table rows
  final List<Map<String, String>> _tableRows = [
    {'Size': '', 'Model': ''},
  ];

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked.take(7).toList();
      });
    }
  }

  void _addTableRow() {
    setState(() {
      _tableRows.add({'Size': '', 'Model': ''});
    });
  }

  void _removeTableRow(int index) {
    setState(() {
      if (_tableRows.length > 1) {
        _tableRows.removeAt(index);
      }
    });
  }

  void _updateTableCell(int row, String key, String value) {
    setState(() {
      _tableRows[row][key] = value;
    });
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Upload product details and images to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product posted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell Something')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _productNameController,
                        decoration: const InputDecoration(labelText: '🏷 Product Name'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter product name' : null,
                      ),
                      const SizedBox(height: 12),
                      _userShops.length > 1
                          ? DropdownButtonFormField<String>(
                              initialValue: _selectedShop,
                              items: _userShops
                                  .map((shop) => DropdownMenuItem(
                                        value: shop,
                                        child: Text(shop),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedShop = v;
                                  _shopNameController.text = v ?? '';
                                });
                              },
                              decoration: const InputDecoration(labelText: '🛍 Shop Name'),
                            )
                          : TextFormField(
                              controller: _shopNameController,
                              decoration: const InputDecoration(labelText: '🛍 Shop Name'),
                              readOnly: true,
                            ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sizeController,
                        decoration: const InputDecoration(labelText: '📦 Product Size / Quantity'),
                        validator: (v) => v == null || v.isEmpty ? 'Enter size/quantity' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📝 Product Details Table', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Table(
                        border: TableBorder.all(color: Colors.grey),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Model', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(),
                            ],
                          ),
                          ..._tableRows.asMap().entries.map((entry) {
                            final i = entry.key;
                            final row = entry.value;
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    initialValue: row['Size'],
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Size'),
                                    onChanged: (v) => _updateTableCell(i, 'Size', v),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: TextFormField(
                                    initialValue: row['Model'],
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Model'),
                                    onChanged: (v) => _updateTableCell(i, 'Model', v),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                  onPressed: () => _removeTableRow(i),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addTableRow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Row'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📝 Description (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(hintText: 'Add any extra details'),
                        minLines: 2,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🖼 Product Images (up to 7)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._images.map((img) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(img.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )),
                          if (_images.length < 7)
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save / Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
