import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/shop_registration_storage.dart';

class ShopRegistrationStep1Page extends StatefulWidget {
  const ShopRegistrationStep1Page({super.key});

  @override
  State<ShopRegistrationStep1Page> createState() => _ShopRegistrationStep1PageState();
}

class _ShopRegistrationStep1PageState extends State<ShopRegistrationStep1Page> {
  List<PlatformFile> _uploadedFiles = [];

  Future<void> _customUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
    );
    if (result != null) {
      setState(() {
        _uploadedFiles = result.files;
      });
    }
  }
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _kraPinController = TextEditingController();
  final TextEditingController _permitController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _logoPath;
  String? _selectedProvider;
  final List<String> _providers = ['Safaricom', 'Airtel', 'Telkom'];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await ShopRegistrationStorage.load();
    if (saved != null) {
      setState(() {
        _shopNameController.text = saved.shopName ?? '';
        _ownerNameController.text = saved.ownerName ?? '';
        _phoneController.text = saved.phone ?? '';
        _emailController.text = saved.email ?? '';
        _categoryController.text = saved.category ?? '';
        _locationController.text = saved.location ?? '';
        _logoPath = saved.logoPath;
        _nationalIdController.text = saved.nationalId ?? '';
        _kraPinController.text = saved.kraPin ?? '';
        _descController.text = saved.description ?? '';
      });
    }
  }

  Future<void> _saveStepData() async {
    final data = await ShopRegistrationStorage.load() ?? ShopRegistrationData();
    data.shopName = _shopNameController.text;
    data.ownerName = _ownerNameController.text;
    data.phone = _phoneController.text;
    data.email = _emailController.text;
    data.category = _categoryController.text;
    data.location = _locationController.text;
    data.logoPath = _logoPath;
    data.nationalId = _nationalIdController.text;
    data.kraPin = _kraPinController.text;
    data.description = _descController.text;
    await ShopRegistrationStorage.save(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Shop - Step 1')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                const Text('🇰🇪', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                const Text('Step 1 of 4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.store, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Mandatory Shop Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name',
                          hintText: 'e.g. SmartElectronics KE',
                          prefixIcon: Icon(Icons.storefront),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter shop name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Owner’s Full Name',
                          hintText: 'As per national ID',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter owner name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '07XXXXXXXX',
                          prefixIcon: Icon(Icons.phone),
                        ),
                         keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter phone number';
                              }

                              // Kenyan number pattern: allows +2547XXXXXXXX or 07XXXXXXXX
                              final reg = RegExp(r'^(?:\+254|0)?7\d{8}$');

                              if (!reg.hasMatch(v)) {
                                return 'Enter a valid Kenyan phone number';
                              }

                              return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address (optional)',
                          hintText: 'For communication & recovery',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final reg = RegExp(r'^.+@.+\..+$');
                          if (!reg.hasMatch(v)) return 'Enter valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProvider,
                        items: _providers
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProvider = v),
                        decoration: const InputDecoration(
                          labelText: 'Choose Provider',
                          prefixIcon: Icon(Icons.sim_card),
                        ),
                        validator: (v) => v == null ? 'Select provider' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Category / Type',
                          hintText: 'e.g. Electronics, Fashion',
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter category/type' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location / Address',
                          hintText: 'e.g. Nairobi CBD',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter location/address' : null,
                      ),
                      const SizedBox(height: 12),
                      // Custom upload for images, pdfs, and all file types
                      Row(
                        children: [
                          const Icon(Icons.upload_file, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Upload Files:'),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _customUpload,
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload'),
                          ),
                        ],
                      ),
                      if (_uploadedFiles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            children: _uploadedFiles.map((file) {
                              if (file.extension == 'jpg' || file.extension == 'jpeg' || file.extension == 'png') {
                                return Image.file(
                                  File(file.path!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                );
                              } else {
                                return Chip(
                                  label: Text(file.name),
                                  avatar: const Icon(Icons.insert_drive_file, size: 18),
                                );
                              }
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nationalIdController,
                        decoration: const InputDecoration(
                          labelText: 'National ID / Business Permit Number',
                          hintText: 'Match with eCitizen or KRA data',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter ID or permit number' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _kraPinController,
                        decoration: const InputDecoration(
                          labelText: 'KRA PIN (optional)',
                          hintText: 'For tax compliance',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Description',
                          hintText: 'Build trust with buyers',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        minLines: 2,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _saveStepData();
                              Navigator.pushNamed(context, '/shop-registration-step2');
                            }
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
