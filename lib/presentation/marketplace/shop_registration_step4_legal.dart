import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/shop_registration_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ShopRegistrationStep4LegalPage extends StatefulWidget {
  const ShopRegistrationStep4LegalPage({super.key});

  @override
  State<ShopRegistrationStep4LegalPage> createState() => _ShopRegistrationStep4LegalPageState();
}

class _ShopRegistrationStep4LegalPageState extends State<ShopRegistrationStep4LegalPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initShopRegState();
  }

  Future<void> _initShopRegState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('shopregidtered')) {
      await prefs.setInt('shopregidtered', 0);
    }
  }
  bool _consentGiven = false;
  File? _ownerProfileImage;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await ShopRegistrationStorage.load();
    if (saved != null) {
      setState(() {
        _consentGiven = saved.consentGiven;
        if (saved.ownerProfileImagePath != null && saved.ownerProfileImagePath!.isNotEmpty) {
          _ownerProfileImage = File(saved.ownerProfileImagePath!);
        }
      });
    }
  }

  Future<void> _saveStepData() async {
    final data = await ShopRegistrationStorage.load() ?? ShopRegistrationData();
    data.consentGiven = _consentGiven;
    if (_ownerProfileImage != null) {
      data.ownerProfileImagePath = _ownerProfileImage!.path;
    }
    await ShopRegistrationStorage.save(data);
  }

  Future<void> _captureOwnerProfileImage() async {
    // Only allow camera capture on mobile (Android/iOS)
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Not Supported'),
          content: const Text('Camera capture is only available on mobile devices for security and privacy reasons.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final picked = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
      if (picked != null) {
        setState(() {
          _ownerProfileImage = File(picked.path);
        });
        await _saveStepData();
      }
    } else {
      // Desktop platforms: show info dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Not Supported'),
          content: const Text('Camera capture is only available on mobile devices for security and privacy reasons.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
        // ...existing code...

  Future<void> _submitRegistration() async {
    await _saveStepData();
    // Set shop registration state to 1
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shopregidtered', 1);
    // TODO: If online, post to backend. If offline, keep data and retry later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop registration submitted! wait  for shop aproval from our team')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Shop - Step 4')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚖️ Legal & Policy Requirements (Kenya)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              const Text('Data Protection Act, 2019 (Kenya): Data must be used only for identification, not exposed publicly.'),
              const SizedBox(height: 8),
              const Text('Consumer Protection Act, 2012: Sellers must display accurate info and honor refunds / warranties.'),
              const SizedBox(height: 8),
              const Text('Electronic Transactions Act: Requires proper records of online transactions.'),
              const SizedBox(height: 8),
              const Text('Cybercrime & Computer Misuse Act: Mandates data security, prohibits fake accounts.'),
              const SizedBox(height: 16),
              const Divider(),
              const Text('📸 Owner Profile Image (Required)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ownerProfileImage != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: FileImage(_ownerProfileImage!),
                        )
                      : const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person, size: 40),
                        ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _captureOwnerProfileImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Photo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _consentGiven,
                onChanged: (v) => setState(() => _consentGiven = v ?? false),
                title: const Text('I consent to the above policies and confirm my shop details are accurate.'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _consentGiven && _ownerProfileImage != null
                      ? () async {
                          await _submitRegistration();
                        }
                      : null,
                  child: const Text('Submit Registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
