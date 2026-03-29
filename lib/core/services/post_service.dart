import 'api_service.dart';

class PostService {
  static Future<List<dynamic>> getFeed({int page = 0, int size = 20}) async {
    final response = await ApiService.get('/posts/feed?page=$page&size=$size');
    return response['content'] ?? [];
  }

  static Future<void> createPost(String description, List<String> mediaUrls) async {
    await ApiService.post('/posts', {
      'description': description,
      'mediaUrls': mediaUrls,
    });
  }

  static Future<void> likePost(String postId) async {
    await ApiService.post('/posts/$postId/like', {});
  }

  static Future<void> trackView(String postId, double percentage, int durationMs) async {
    await ApiService.post('/posts/$postId/track-view', {
      'viewPercentage': percentage,
      'viewDurationMs': durationMs,
    });
  }
}
