import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShopRegistrationData {
  String? shopName;
  String? ownerName;
  String? phone;
  String? email;
  String? category;
  String? location;
  String? logoPath;
  String? nationalId;
  String? kraPin;
  String? description;
  List<String> verificationDocs = [];
  String? mpesaTill;
  String? bankAccount;
  String? deliveryOptions;
  bool consentGiven = false;
  String? ownerProfileImagePath;

  ShopRegistrationData();

  Map<String, dynamic> toJson() => {
    'shopName': shopName,
    'ownerName': ownerName,
    'phone': phone,
    'email': email,
    'category': category,
    'location': location,
    'logoPath': logoPath,
    'nationalId': nationalId,
    'kraPin': kraPin,
    'description': description,
    'verificationDocs': verificationDocs,
    'mpesaTill': mpesaTill,
    'bankAccount': bankAccount,
    'deliveryOptions': deliveryOptions,
    'consentGiven': consentGiven,
    'ownerProfileImagePath': ownerProfileImagePath,
  };

  static ShopRegistrationData fromJson(Map<String, dynamic> json) {
    final data = ShopRegistrationData();
    data.shopName = json['shopName'];
    data.ownerName = json['ownerName'];
    data.phone = json['phone'];
    data.email = json['email'];
    data.category = json['category'];
    data.location = json['location'];
    data.logoPath = json['logoPath'];
    data.nationalId = json['nationalId'];
    data.kraPin = json['kraPin'];
    data.description = json['description'];
    data.verificationDocs = List<String>.from(json['verificationDocs'] ?? []);
    data.mpesaTill = json['mpesaTill'];
    data.bankAccount = json['bankAccount'];
    data.deliveryOptions = json['deliveryOptions'];
    data.consentGiven = json['consentGiven'] ?? false;
    data.ownerProfileImagePath = json['ownerProfileImagePath'];
    return data;
  }
}

class ShopRegistrationStorage {
  static const String _key = 'shop_registration_data';

  static Future<void> save(ShopRegistrationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  static Future<ShopRegistrationData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    return ShopRegistrationData.fromJson(jsonDecode(jsonStr));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
