import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/services/seller_service.dart';

class ShopRegistrationStep1Page extends StatefulWidget {
  const ShopRegistrationStep1Page({super.key});

  @override
  State<ShopRegistrationStep1Page> createState() => _ShopRegistrationStep1PageState();
}

class _ShopRegistrationStep1PageState extends State<ShopRegistrationStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final seller = await SellerService.createSellerProfile(
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
      );
      
      setState(() => _isLoading = false);
      
      if (seller != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller profile created successfully!')),
        );
        // Go to marketplace or seller profile
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create seller profile.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Seller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Become a Seller',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Enter your business details below to start selling.'),
            const SizedBox(height: 24),
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
                          Text('Business Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          hintText: 'e.g. SmartElectronics KE',
                          prefixIcon: Icon(Icons.storefront),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter business name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _businessAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Business Address',
                          hintText: 'e.g. Nairobi, Kenya',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Enter business address' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _businessDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Business Description',
                          hintText: 'Describe your products/services (10-1000 characters)',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        minLines: 3,
                        maxLines: 5,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter business description';
                          if (v.length < 10) return 'Description must be at least 10 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Iconsax.arrow_right_1),
                          label: Text(_isLoading ? 'Submitting...' : 'Complete Registration'),
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
