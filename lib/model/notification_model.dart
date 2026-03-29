/// Notification model for push notifications
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? imageUrl;
  final NotificationType type;
  final String? actionUrl;
  final String? relatedId; // ID of related object (post, message, etc.)
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.type,
    this.actionUrl,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      type: _parseNotificationType(json['type'] as String? ?? 'general'),
      actionUrl: json['actionUrl'] as String?,
      relatedId: json['relatedId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': type.toString().split('.').last,
      'actionUrl': actionUrl,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? imageUrl,
    NotificationType? type,
    String? actionUrl,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Notification types
enum NotificationType {
  like,           // Someone liked your post
  comment,        // Someone commented on your post
  follow,         // Someone followed you
  message,        // Direct message
  mention,        // You were mentioned
  purchase,       // Purchase notification
  enrollment,     // Course enrollment confirmation
  general,        // General notification
  system,         // System notification
  alert,          // Alert notification
}

/// Parse notification type from string
NotificationType _parseNotificationType(String type) {
  switch (type.toLowerCase()) {
    case 'like':
      return NotificationType.like;
    case 'comment':
      return NotificationType.comment;
    case 'follow':
      return NotificationType.follow;
    case 'message':
      return NotificationType.message;
    case 'mention':
      return NotificationType.mention;
    case 'purchase':
      return NotificationType.purchase;
    case 'enrollment':
      return NotificationType.enrollment;
    case 'system':
      return NotificationType.system;
    case 'alert':
      return NotificationType.alert;
    default:
      return NotificationType.general;
  }
}

/// Notification summary for badge counts
class NotificationSummary {
  final int unreadCount;
  final int totalCount;
  final DateTime lastFetchTime;
  final Map<NotificationType, int> countByType;

  NotificationSummary({
    required this.unreadCount,
    required this.totalCount,
    required this.lastFetchTime,
    required this.countByType,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      unreadCount: json['unreadCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      lastFetchTime: json['lastFetchTime'] != null
          ? DateTime.parse(json['lastFetchTime'] as String)
          : DateTime.now(),
      countByType: (json['countByType'] as Map<String, dynamic>? ?? {})
          .map(
            (key, value) => MapEntry(
              _parseNotificationType(key),
              value as int,
            ),
          ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unreadCount': unreadCount,
      'totalCount': totalCount,
      'lastFetchTime': lastFetchTime.toIso8601String(),
      'countByType': countByType
          .map((key, value) => MapEntry(key.toString().split('.').last, value)),
    };
  }
}
