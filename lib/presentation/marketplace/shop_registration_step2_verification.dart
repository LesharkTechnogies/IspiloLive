import 'package:flutter/material.dart';
import '../../core/shop_registration_storage.dart';

class ShopRegistrationStep2VerificationPage extends StatefulWidget {
  const ShopRegistrationStep2VerificationPage({super.key});

  @override
  State<ShopRegistrationStep2VerificationPage> createState() => _ShopRegistrationStep2VerificationPageState();
}

class _ShopRegistrationStep2VerificationPageState extends State<ShopRegistrationStep2VerificationPage> {
  List<String> _uploadedDocs = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await ShopRegistrationStorage.load();
    if (saved != null) {
      setState(() {
        _uploadedDocs = List<String>.from(saved.verificationDocs);
      });
    }
  }

  Future<void> _saveStepData() async {
    final data = await ShopRegistrationStorage.load() ?? ShopRegistrationData();
    data.verificationDocs = _uploadedDocs;
    await ShopRegistrationStorage.save(data);
  }

  void _pickDocument(String type) async {
    // TODO: Implement file picker for images/docs
    setState(() {
      _uploadedDocs.add(type);
    });
    await _saveStepData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Shop - Step 2')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📸 Recommended Verification Uploads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('National ID (Front + Back)'),
              subtitle: const Text('Confirms real person'),
              trailing: ElevatedButton(
                onPressed: () => _pickDocument('National ID'),
                child: const Text('Upload'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.green),
              title: const Text('Business Permit / License'),
              subtitle: const Text('Confirms legitimacy'),
              trailing: ElevatedButton(
                onPressed: () => _pickDocument('Business Permit'),
                child: const Text('Upload'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.orange),
              title: const Text('Shop Photo / Logo'),
              subtitle: const Text('Visual identity for listings'),
              trailing: ElevatedButton(
                onPressed: () => _pickDocument('Shop Photo'),
                child: const Text('Upload'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveStepData();
                  Navigator.pushNamed(context, '/shop-registration-step3');
                },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
