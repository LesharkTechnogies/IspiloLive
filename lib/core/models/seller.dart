class Seller {
  final String id;
  final String name;
  final String avatar;
  final bool isVerified;
  final String? phone;
  final bool phonePrivacyPublic;
  final String? countryCode;

  Seller({
    required this.id,
    required this.name,
    required this.avatar,
    this.isVerified = false,
    this.phone,
    this.phonePrivacyPublic = false,
    this.countryCode,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'isVerified': isVerified,
        'phone': phone,
        'phonePrivacyPublic': phonePrivacyPublic,
        'countryCode': countryCode,
      };

  factory Seller.fromMap(Map<String, dynamic> m) => Seller(
        id: m['id'] as String,
        name: m['name'] as String,
        avatar: m['avatar'] as String,
        isVerified: m['isVerified'] as bool? ?? false,
        phone: m['phone'] as String?,
        phonePrivacyPublic: m['phonePrivacyPublic'] as bool? ?? false,
        countryCode: m['countryCode'] as String?,
      );

  /// Alias used by SellerService (API responses use 'fromJson' convention)
  factory Seller.fromJson(Map<String, dynamic> json) => Seller(
        id: json['id'] as String? ?? '',
        name: (json['name'] as String?) ?? (json['businessName'] as String?) ?? '',
        avatar: (json['avatar'] as String?) ?? (json['businessLogo'] as String?) ?? '',
        isVerified: json['isVerified'] as bool? ?? false,
        phone: json['phone'] as String?,
        phonePrivacyPublic: json['phonePrivacyPublic'] as bool? ?? false,
        countryCode: json['countryCode'] as String?,
      );

  Map<String, dynamic> toJson() => toMap();
}
