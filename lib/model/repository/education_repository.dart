import 'package:ispilo/core/services/api_service.dart';
import 'package:ispilo/model/education_model.dart';

/// Repository for education API calls
class EducationRepository {
  static const String _baseEndpoint = '/education';

  // ==================== VIDEOS ====================

  /// Get all education videos with pagination
  static Future<List<EducationVideoModel>> getVideos({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/videos?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => EducationVideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  /// Get trending videos
  static Future<List<EducationVideoModel>> getTrendingVideos({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/videos/trending?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => EducationVideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch trending videos: $e');
    }
  }

  /// Get top-rated videos
  static Future<List<EducationVideoModel>> getTopRatedVideos({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/videos/top-rated?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => EducationVideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top-rated videos: $e');
    }
  }

  /// Search videos by keyword
  static Future<List<EducationVideoModel>> searchVideos(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/videos/search?keyword=$keyword&page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => EducationVideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search videos: $e');
    }
  }

  /// Get videos by category
  static Future<List<EducationVideoModel>> getVideosByCategory(
    String category, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/videos/category/$category?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => EducationVideoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch videos by category: $e');
    }
  }

  /// Get video categories
  static Future<List<String>> getVideoCategories() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/videos/categories');
      if (response is List) {
        return response.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all channels
  static Future<List<String>> getChannels() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/videos/channels');
      if (response is List) {
        return response.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== COURSES ====================

  /// Get all courses with pagination
  static Future<List<CourseModel>> getCourses({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/courses?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  /// Get popular courses
  static Future<List<CourseModel>> getPopularCourses({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/courses/popular?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch popular courses: $e');
    }
  }

  /// Get top-rated courses
  static Future<List<CourseModel>> getTopRatedCourses({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/courses/top-rated?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top-rated courses: $e');
    }
  }

  /// Search courses by keyword
  static Future<List<CourseModel>> searchCourses(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/courses/search?keyword=$keyword&page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  /// Get courses by category
  static Future<List<CourseModel>> getCoursesByCategory(
    String category, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/courses/category/$category?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses by category: $e');
    }
  }

  /// Get course categories
  static Future<List<String>> getCourseCategories() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/courses/categories');
      if (response is List) {
        return response.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all instructors
  static Future<List<String>> getInstructors() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/courses/instructors');
      if (response is List) {
        return response.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== ENROLLMENTS ====================

  /// Get user's enrolled courses
  static Future<List<CourseEnrollmentModel>> getMyEnrolledCourses({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/my-courses?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseEnrollmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch my courses: $e');
    }
  }

  /// Get user's in-progress courses
  static Future<List<CourseEnrollmentModel>> getMyInProgressCourses({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/my-courses/in-progress?page=$page&size=$size',
      );
      final List<dynamic> content = response['content'] as List? ?? [];
      return content
          .map((json) => CourseEnrollmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch in-progress courses: $e');
    }
  }

  /// Get user's completed courses
  static Future<List<CourseEnrollmentModel>> getMyCompletedCourses() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/my-courses/completed');
      final List<dynamic> content = response as List? ?? [];
      return content
          .map((json) => CourseEnrollmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed courses: $e');
    }
  }

  /// Enroll in a course
  static Future<CourseEnrollmentModel> enrollInCourse(String courseId) async {
    try {
      final response = await ApiService.post(
        '$_baseEndpoint/courses/$courseId/enroll',
        {},
      );
      return CourseEnrollmentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to enroll in course: $e');
    }
  }

  /// Update course progress
  static Future<CourseEnrollmentModel> updateCourseProgress({
    required String enrollmentId,
    required double progress,
    int? completedLessons,
  }) async {
    try {
      final response = await ApiService.put(
        '$_baseEndpoint/enrollments/$enrollmentId/progress?progress=$progress${completedLessons != null ? '&completedLessons=$completedLessons' : ''}',
        {},
      );
      return CourseEnrollmentModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  /// Check if user is enrolled in a course
  static Future<bool> isUserEnrolledInCourse(String courseId) async {
    try {
      final response = await ApiService.get(
        '$_baseEndpoint/courses/$courseId/enrolled-status',
      );
      return response['enrolled'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
