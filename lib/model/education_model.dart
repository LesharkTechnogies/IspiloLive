/// Education video model
class EducationVideoModel {
  final String id;
  final String title;
  final String channel;
  final String thumbnail;
  final String videoUrl;
  final String duration;
  final int views;
  final String category;
  final double rating;

  EducationVideoModel({
    required this.id,
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.videoUrl,
    required this.duration,
    required this.views,
    required this.category,
    required this.rating,
  });

  factory EducationVideoModel.fromJson(Map<String, dynamic> json) {
    return EducationVideoModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'channel': channel,
      'thumbnail': thumbnail,
      'videoUrl': videoUrl,
      'duration': duration,
      'views': views,
      'category': category,
      'rating': rating,
    };
  }
}

/// Education course model
class CourseModel {
  final String id;
  final String title;
  final String instructor;
  final String thumbnail;
  final String description;
  final String category;
  final int enrollmentCount;
  final double rating;
  final int durationHours;
  final int totalLessons;
  final List<String> topics;

  CourseModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.thumbnail,
    required this.description,
    required this.category,
    required this.enrollmentCount,
    required this.rating,
    required this.durationHours,
    required this.totalLessons,
    required this.topics,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      instructor: json['instructor'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      durationHours: json['durationHours'] as int? ?? 0,
      totalLessons: json['totalLessons'] as int? ?? 0,
      topics: json['topics'] != null
          ? List<String>.from(json['topics'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructor': instructor,
      'thumbnail': thumbnail,
      'description': description,
      'category': category,
      'enrollmentCount': enrollmentCount,
      'rating': rating,
      'durationHours': durationHours,
      'totalLessons': totalLessons,
      'topics': topics,
    };
  }
}

/// User course enrollment model
class CourseEnrollmentModel {
  final String id;
  final String courseId;
  final String title;
  final double progress;
  final int completedLessons;
  final bool isCompleted;
  final String thumbnail;
  final String instructor;

  CourseEnrollmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.progress,
    required this.completedLessons,
    required this.isCompleted,
    required this.thumbnail,
    required this.instructor,
  });

  factory CourseEnrollmentModel.fromJson(Map<String, dynamic> json) {
    final courseJson = json['course'] as Map<String, dynamic>? ?? {};
    return CourseEnrollmentModel(
      id: json['id'] as String,
      courseId: courseJson['id'] as String? ?? '',
      title: courseJson['title'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedLessons: json['completedLessons'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      thumbnail: courseJson['thumbnail'] as String? ?? '',
      instructor: courseJson['instructor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'progress': progress,
      'completedLessons': completedLessons,
      'isCompleted': isCompleted,
      'thumbnail': thumbnail,
      'instructor': instructor,
    };
  }

  /// Get progress percentage (0-100)
  int get progressPercentage => (progress * 100).toInt();
}
