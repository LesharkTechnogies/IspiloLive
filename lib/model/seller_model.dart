/// Canonical SellerModel used across the marketplace UI.
/// All files should import this instead of relying on product_model.dart re-exports.
class SellerModel {
  final String id;
  final String businessName;
  final String? businessLogo;
  final bool isVerified;
  final String? phone;
  final String? countryCode;

  SellerModel({
    required this.id,
    required this.businessName,
    this.businessLogo,
    required this.isVerified,
    this.phone,
    this.countryCode,
  });

  /// UI getters — used widely across seller_profile_page, product cards etc.
  String get name => businessName;
  String get avatar => businessLogo ?? '';

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] as String? ?? json['sellerId'] as String? ?? '',
      businessName:
          (json['businessName'] as String?) ?? (json['name'] as String?) ?? '',
      businessLogo:
          (json['businessLogo'] as String?) ?? (json['avatar'] as String?),
      isVerified:
          json['isVerified'] as bool? ?? json['verified'] as bool? ?? false,
      phone: json['phone'] as String? ?? json['contact'] as String?,
      countryCode:
          json['countryCode'] as String? ?? json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'isVerified': isVerified,
      'phone': phone,
      'countryCode': countryCode,
    };
  }
}
