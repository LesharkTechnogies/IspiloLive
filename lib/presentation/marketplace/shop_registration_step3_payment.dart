import 'package:flutter/material.dart';
import '../../core/shop_registration_storage.dart';

class ShopRegistrationStep3PaymentPage extends StatefulWidget {
  const ShopRegistrationStep3PaymentPage({super.key});

  @override
  State<ShopRegistrationStep3PaymentPage> createState() => _ShopRegistrationStep3PaymentPageState();
}

class _ShopRegistrationStep3PaymentPageState extends State<ShopRegistrationStep3PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mpesaController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await ShopRegistrationStorage.load();
    if (saved != null) {
      setState(() {
        _mpesaController.text = saved.mpesaTill ?? '';
        _bankController.text = saved.bankAccount ?? '';
        _deliveryController.text = saved.deliveryOptions ?? '';
        _descController.text = saved.description ?? '';
      });
    }
  }

  Future<void> _saveStepData() async {
    final data = await ShopRegistrationStorage.load() ?? ShopRegistrationData();
    data.mpesaTill = _mpesaController.text;
    data.bankAccount = _bankController.text;
    data.deliveryOptions = _deliveryController.text;
    data.description = _descController.text;
    await ShopRegistrationStorage.save(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Shop - Step 3')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💰 Optional Business & Payment Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mpesaController,
                decoration: const InputDecoration(labelText: 'Mpesa Till / Paybill Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'Bank Account (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliveryController,
                decoration: const InputDecoration(labelText: 'Delivery Options'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Shop Description / About'),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await _saveStepData();
                      Navigator.pushNamed(context, '/shop-registration-step4');
                    }
                  },
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
