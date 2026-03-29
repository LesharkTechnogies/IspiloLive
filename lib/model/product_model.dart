import 'package:ispilo/model/seller_model.dart';

/// Product model for marketplace
class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String mainImage;
  final List<String> images;
  final String category;
  final String condition;
  final double rating;
  final int reviewCount;
  final String location;
  final int stockQuantity;
  final bool isAvailable;
  final SellerModel seller;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.mainImage,
    required this.images,
    required this.category,
    required this.condition,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.stockQuantity,
    required this.isAvailable,
    required this.seller,
    required this.createdAt,
  });

  /// Create from JSON API response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
  final sellerJson = (json['seller'] as Map?)?.cast<String, dynamic>() ??
    (json['user'] as Map?)?.cast<String, dynamic>() ??
    const <String, dynamic>{};

  final mainImage = json['mainImage']?.toString() ??
    json['imageUrl']?.toString() ??
    json['thumbnail']?.toString() ??
    '';

  final rawImages = json['images'] ?? json['mediaUrls'] ?? const [];

    return ProductModel(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Untitled Product',
      description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    mainImage: mainImage,
    images: (rawImages as List?)
        ?.map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList() ??
      <String>[],
      category: json['category'] as String? ?? '',
      condition: json['condition'] as String? ?? 'New',
    rating: (json['rating'] as num?)?.toDouble() ??
      (json['averageRating'] as num?)?.toDouble() ??
      0,
    reviewCount: (json['reviewCount'] as num?)?.toInt() ??
      (json['reviewsCount'] as num?)?.toInt() ??
      0,
      location: json['location'] as String? ?? '',
    stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    isAvailable: json['isAvailable'] as bool? ??
      ((json['stockQuantity'] as num?)?.toInt() ?? 0) > 0,
    seller: SellerModel.fromJson(sellerJson),
      createdAt: json['createdAt'] != null
      ? DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert to JSON for sending to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'mainImage': mainImage,
      'images': images,
      'category': category,
      'condition': condition,
      'rating': rating,
      'reviewCount': reviewCount,
      'location': location,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'seller': seller.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Compatibility getters used by UI code in several places
  String get imageUrl => mainImage.isNotEmpty ? mainImage : (images.isNotEmpty ? images.first : '');

  String get name => title;

  /// Price formatted as string for display
  String get priceFormatted => '\$${price.toStringAsFixed(2)}';
}
