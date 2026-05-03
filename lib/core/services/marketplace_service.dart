import 'api_service.dart';

class MarketplaceService {
  static Future<List<dynamic>> getProducts({int page = 0, int size = 20}) async {
    final response = await ApiService.get('/products?page=$page&size=$size');
    if (response == null) return [];
    if (response is List) return response;
    if (response is Map) {
      // support common envelopes used by different backends
      return (response['data'] as List<dynamic>?) ?? (response['content'] as List<dynamic>?) ?? (response['items'] as List<dynamic>?) ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getProductsByCategory(String category, {int page = 0, int size = 20}) async {
    final response = await ApiService.get('/products/category/$category?page=$page&size=$size');
    if (response == null) return [];
    if (response is List) return response;
    if (response is Map) {
      return (response['data'] as List<dynamic>?) ?? (response['content'] as List<dynamic>?) ?? (response['items'] as List<dynamic>?) ?? [];
    }
    return [];
  }

  static Future<dynamic> getProductDetails(String productId) async {
    return await ApiService.get('/products/$productId');
  }
  
  static Future<List<dynamic>> searchProducts(String query) async {
    final response = await ApiService.get('/products/search?query=$query');
    return response['content'] ?? [];
  }

  static Future<dynamic> createProduct(Map<String, dynamic> productData) async {
    return await ApiService.post('/products', productData);
  }
}
