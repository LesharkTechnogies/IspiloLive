import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller.dart';
import '../../model/seller_model.dart';
import 'api_service.dart';

/// Seller service integrated with API backend
class SellerService {
  SellerService._internal();

  static final SellerService instance = SellerService._internal();

  // Cache key for storing sellers locally
  static const String _sellerCacheKey = 'cached_sellers';
  static const String _lastFetchKey = 'seller_last_fetch';

  /// Get seller by ID from API — returns [SellerModel] (UI-friendly model)
  static Future<SellerModel?> getSellerById(String id) async {
    try {
      final response = await ApiService.get('/sellers/$id');
      if (response != null) {
        return SellerModel.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching seller: $e');
      return null;
    }
  }

  /// Get seller by ID — returns raw [Seller] domain object (used internally)
  static Future<Seller?> getSellerRaw(String id) async {
    try {
      final response = await ApiService.get('/sellers/$id');
      if (response != null) {
        return Seller.fromJson(response as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching seller: $e');
      return await _getCachedSeller(id);
    }
  }

  /// Get all sellers with pagination
  static Future<List<Seller>> getAllSellers({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get('/sellers?page=$page&size=$size');
      final List<dynamic> content = response['content'] as List? ?? [];
      final sellers = content
          .map((json) => Seller.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache sellers
      await _cacheSellers(sellers);

      return sellers;
    } catch (e) {
      debugPrint('Error fetching sellers: $e');
      return await _getCachedSellers();
    }
  }

  /// Search sellers by name or category
  static Future<List<Seller>> searchSellers(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '/sellers/search?q=${Uri.encodeComponent(query)}&page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => Seller.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching sellers: $e');
      return [];
    }
  }

  /// Get featured/verified sellers
  static Future<List<Seller>> getFeaturedSellers({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '/sellers/featured?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => Seller.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching featured sellers: $e');
      return [];
    }
  }

  /// Create a new seller (for registration)
  static Future<Seller?> createSeller({
    required String name,
    required String email,
    required String phone,
    required String countryCode,
    required String category,
    String? avatar,
    String? description,
  }) async {
    try {
      final payload = {
        'name': name,
        'email': email,
        'phone': phone,
        'countryCode': countryCode,
        'category': category,
        if (avatar != null) 'avatar': avatar,
        if (description != null) 'description': description,
      };

      final response = await ApiService.post('/sellers', payload);
      return Seller.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating seller: $e');
      return null;
    }
  }

  /// Update seller information
  static Future<Seller?> updateSeller(
    String sellerId, {
    String? name,
    String? avatar,
    String? description,
    String? phone,
    bool? isVerified,
  }) async {
    try {
      final payload = {
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (isVerified != null) 'isVerified': isVerified,
      };

      final response = await ApiService.put('/sellers/$sellerId', payload);
      return Seller.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error updating seller: $e');
      return null;
    }
  }

  /// Get seller ratings and reviews
  static Future<Map<String, dynamic>?> getSellerRatings(String sellerId) async {
    try {
      final response = await ApiService.get('/sellers/$sellerId/ratings');
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching seller ratings: $e');
      return null;
    }
  }

  /// Create or update a seller from a loosely typed map
  static Future<Seller?> upsertSellerFromMap(Map<String, dynamic> m) async {
    try {
      final id = m['id'] as String? ??
          m['sellerId'] as String? ??
          'seller_${DateTime.now().millisecondsSinceEpoch}';

      final name = m['name'] as String? ??
          m['sellerName'] as String? ??
          'Seller';
      final avatar = m['avatar'] as String? ??
          m['sellerAvatar'] as String? ??
          '';

      final payload = {
        'name': name,
        'avatar': avatar,
        'isVerified': m['isVerified'] as bool? ?? false,
        if (m['phone'] != null) 'phone': m['phone'],
        if (m['sellerPhone'] != null) 'phone': m['sellerPhone'],
        'countryCode': m['countryCode'] as String? ?? m['sellerCountryCode'],
      };

      // If ID doesn't exist, create new; otherwise update
      if (id.startsWith('seller_new_')) {
        return await createSeller(
          name: name,
          email: m['email'] as String? ?? '',
          phone: m['phone'] as String? ?? '',
          countryCode: m['countryCode'] as String? ?? '',
          category: m['category'] as String? ?? 'general',
          avatar: avatar,
        );
      } else {
        return await updateSeller(id, name: name, avatar: avatar);
      }
    } catch (e) {
      debugPrint('Error upserting seller: $e');
      return null;
    }
  }

  /// Cache sellers locally
  static Future<void> _cacheSellers(List<Seller> sellers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sellers.map((s) => s.toJson()).toList();
      await prefs.setString(_sellerCacheKey, jsonList.toString());
      await prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching sellers: $e');
    }
  }

  /// Get cached sellers
  static Future<List<Seller>> _getCachedSellers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_sellerCacheKey);
      if (cached != null && cached.isNotEmpty) {
        // In production, properly parse JSON
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error retrieving cached sellers: $e');
      return [];
    }
  }

  /// Get cached seller by ID
  static Future<Seller?> _getCachedSeller(String id) async {
    try {
      final sellers = await _getCachedSellers();
      return sellers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
