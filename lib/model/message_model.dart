/// Conversation model for messaging
class ConversationModel {
  final String id;
  final String name;
  final List<ConversationParticipant> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? encryptionKey;
  final bool isGroup;

  ConversationModel({
    required this.id,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.encryptionKey,
    required this.isGroup,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ConversationParticipant.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      encryptionKey: json['encryptionKey'] as String?,
      isGroup: json['isGroup'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'encryptionKey': encryptionKey,
      'isGroup': isGroup,
    };
  }
}

/// Conversation participant model
class ConversationParticipant {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;

  ConversationParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.isOnline,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isOnline': isOnline,
    };
  }
}

/// Message model for chat
class MessageModel {
  final String id;
  final String clientMsgId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? encryptedContent;
  final String? encryptionIv;
  final MessageType type;
  final String? mediaUrl;
  final bool isRead;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.clientMsgId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.encryptedContent,
    this.encryptionIv,
    required this.type,
    this.mediaUrl,
    required this.isRead,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      clientMsgId: json['clientMsgId'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String? ?? '',
      encryptedContent: json['encryptedContent'] as String?,
      encryptionIv: json['encryptionIv'] as String?,
      type: _parseMessageType(json['type'] as String? ?? 'TEXT'),
      mediaUrl: json['mediaUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientMsgId': clientMsgId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'encryptedContent': encryptedContent,
      'encryptionIv': encryptionIv,
      'type': type.toString().split('.').last,
      'mediaUrl': mediaUrl,
      'isRead': isRead,
      'createdAt': timestamp.toIso8601String(),
    };
  }

  static MessageType _parseMessageType(String type) {
    switch (type.toUpperCase()) {
      case 'TEXT':
        return MessageType.text;
      case 'IMAGE':
        return MessageType.image;
      case 'VIDEO':
        return MessageType.video;
      case 'FILE':
        return MessageType.file;
      case 'LOCATION':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }
}

enum MessageType { text, image, video, file, location }
