/// Post model for social feed
DateTime _parseServerDateTimeToLocal(dynamic raw) {
  final rawText = raw?.toString().trim() ?? '';
  if (rawText.isEmpty) return DateTime.now();

  // If server omits timezone (common in some serializers), treat as UTC.
  final hasZone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(rawText);
  final normalized = hasZone ? rawText : '${rawText}Z';

  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return DateTime.now();
  return parsed.toLocal();
}

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final bool avatarPublic;
  final String content;
  final String? imageUrl;
  final List<String> images;
  final int likesCount;
  final int commentsCount;
  final int viewCount;
  final bool isLiked;
  final bool isSaved;
  final bool isSponsored;
  final bool hasVerification;
  final DateTime createdAt;
  final List<String>? ctaButtons;
  final String? groupId;
  final String? groupName;
  final String? groupAvatar;
  final bool isGroupPost;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.avatarPublic,
    required this.content,
    this.imageUrl,
    required this.images,
    required this.likesCount,
    required this.commentsCount,
    required this.viewCount,
    required this.isLiked,
    required this.isSaved,
    required this.isSponsored,
    required this.hasVerification,
    required this.createdAt,
    this.ctaButtons,
    this.groupId,
    this.groupName,
    this.groupAvatar,
    this.isGroupPost = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final group = (json['group'] as Map?)?.cast<String, dynamic>() ?? const {};
    final groupId = json['groupId']?.toString() ?? group['id']?.toString();
    final groupName = json['groupName']?.toString() ?? group['name']?.toString();
    final groupAvatar = json['groupAvatar']?.toString() ??
        group['avatar']?.toString() ??
        group['image']?.toString();
    final isGroupPost = json['isGroup'] as bool? ??
        json['groupPost'] as bool? ??
        (groupId != null && groupId.toString().trim().isNotEmpty);

    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: json['user']?['id']?.toString() ?? '',
      username: json['user']?['name']?.toString() ?? 'Unknown',
      userAvatar: json['user']?['avatar']?.toString() ?? '',
      avatarPublic: json['user']?['avatarPublic'] as bool? ?? true,
      content: json['description']?.toString() ?? json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      images: json['mediaUrls'] != null ? List<String>.from(json['mediaUrls']) : [],
      likesCount: _parseInt(json['likesCount']),
      commentsCount: _parseInt(json['commentsCount']),
      viewCount: _parseInt(json['viewCount']),
  isLiked: json['isLiked'] as bool? ?? json['likedByCurrentUser'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      isSponsored: json['isSponsored'] as bool? ?? false,
      hasVerification: json['hasVerification'] as bool? ?? false,
    createdAt: _parseServerDateTimeToLocal(json['createdAt']),
      ctaButtons: json['ctaButtons'] != null
          ? List<String>.from(json['ctaButtons'] as List)
          : null,
      groupId: groupId?.toString(),
      groupName: groupName?.toString(),
      groupAvatar: groupAvatar?.toString(),
      isGroupPost: isGroupPost,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'avatarPublic': avatarPublic,
      'content': content,
      'imageUrl': imageUrl,
      'mediaUrls': images,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewCount': viewCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isSponsored': isSponsored,
      'hasVerification': hasVerification,
      'createdAt': createdAt.toIso8601String(),
      'ctaButtons': ctaButtons,
      'groupId': groupId,
      'groupName': groupName,
      'groupAvatar': groupAvatar,
      'isGroup': isGroupPost,
    };
  }

  /// Create a copy with modified fields
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    bool? avatarPublic,
    String? content,
    String? imageUrl,
    List<String>? images,
    int? likesCount,
    int? commentsCount,
    int? viewCount,
    bool? isLiked,
    bool? isSaved,
    bool? isSponsored,
    bool? hasVerification,
    DateTime? createdAt,
    List<String>? ctaButtons,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      avatarPublic: avatarPublic ?? this.avatarPublic,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewCount: viewCount ?? this.viewCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isSponsored: isSponsored ?? this.isSponsored,
      hasVerification: hasVerification ?? this.hasVerification,
      createdAt: createdAt ?? this.createdAt,
      ctaButtons: ctaButtons ?? this.ctaButtons,
    );
  }
}

/// Comment model
class CommentModel {
  final String id;
  final String postId;
  final String? parentCommentId;
  final String userId;
  final String username;
  final String userAvatar;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    this.replies = const <CommentModel>[],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final post = (json['post'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parent = (json['parentComment'] as Map?)?.cast<String, dynamic>() ??
        (json['parent'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final rawReplies = json['replies'] as List? ?? const [];

    return CommentModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? post['id']?.toString() ?? '',
      parentCommentId: json['parentCommentId']?.toString() ??
          json['parentId']?.toString() ??
          parent['id']?.toString(),
      userId: user['id']?.toString() ?? '',
      username: user['name']?.toString() ?? 'Unknown',
      userAvatar: user['avatar']?.toString() ?? '',
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      likesCount: PostModel._parseInt(json['likesCount'] ?? json['likes']),
    createdAt: _parseServerDateTimeToLocal(json['createdAt']),
      replies: rawReplies
          .whereType<Map>()
          .map((reply) => CommentModel.fromJson(reply.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'parentCommentId': parentCommentId,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'content': content,
      'likesCount': likesCount,
      'createdAt': createdAt.toIso8601String(),
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}

/// User model for social feed
class UserModel {
  final String id;
  final String username;
  final String name;
  final String avatar;
  final String? bio;
  final bool isVerified;
  final bool isOnline;
  final bool isPremium;
  final bool avatarPublic;
  final String? company;
  final String? town;
  final String? quote;
  final String? coverImage;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    this.bio,
    required this.isVerified,
    required this.isOnline,
    required this.isPremium,
    required this.avatarPublic,
    this.company,
    this.town,
    this.quote,
    this.coverImage,
    this.createdAt,
    this.lastSeenAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
  final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final profile = (json['profile'] as Map?)?.cast<String, dynamic>() ?? const {};
  final resolvedId =
    json['id']?.toString() ??
    json['userId']?.toString() ??
    json['authorId']?.toString() ??
    user['id']?.toString() ??
    user['userId']?.toString() ??
    profile['id']?.toString() ??
    '';
  final resolvedName =
    json['name']?.toString() ??
    user['name']?.toString() ??
    json['displayName']?.toString() ??
    user['displayName']?.toString() ??
    json['username']?.toString() ??
    user['username']?.toString() ??
    'Unknown';
  final resolvedUsername =
    json['email']?.toString() ??
    json['username']?.toString() ??
    user['email']?.toString() ??
    user['username']?.toString() ??
    '';
    final avatarUrl = json['avatar']?.toString() ??
    user['avatar']?.toString() ??
        json['avatarUrl']?.toString() ??
    user['avatarUrl']?.toString() ??
        json['profileImage']?.toString() ??
        json['profilePicture']?.toString() ??
        profile['avatar']?.toString() ??
        profile['avatarUrl']?.toString() ??
        '';

    return UserModel(
    id: resolvedId,
    username: resolvedUsername,
    name: resolvedName,
      avatar: avatarUrl,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      avatarPublic: json['avatarPublic'] as bool? ?? true,
      company: json['company'] as String?,
      town: json['town'] as String?,
      quote: json['quote'] as String?,
      coverImage: json['coverImage'] as String?,
      createdAt: json['createdAt'] != null
          ? _parseServerDateTimeToLocal(json['createdAt'])
          : null,
      lastSeenAt: json['lastSeenAt'] != null
          ? _parseServerDateTimeToLocal(json['lastSeenAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'isPremium': isPremium,
      'avatarPublic': avatarPublic,
      'company': company,
      'town': town,
      'quote': quote,
      'coverImage': coverImage,
      'createdAt': createdAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }
}

/// Story model
class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String avatar;
  final bool isViewed;
  final bool isOwn;
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.isViewed,
    required this.isOwn,
    required this.createdAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String,
      isViewed: json['isViewed'] as bool? ?? false,
      isOwn: json['isOwn'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? _parseServerDateTimeToLocal(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'isViewed': isViewed,
      'isOwn': isOwn,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
