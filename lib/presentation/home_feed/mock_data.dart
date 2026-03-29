// Lightweight module to hold sample/mock data shared by HomeFeed.
// Moving large mock lists here reduces allocations during rebuilds.

// -----------------------------------------------------------------------------
// Current User Profile (userId = 0)
// -----------------------------------------------------------------------------
final Map<String, dynamic> kCurrentUser = {
  'id': 0,
  'username': 'collins_network',
  'name': 'Collins Muthomi',
  'email': 'lesharkTechnologies@gmail.com',
  'bio':
      'Network Engineer passionate about ISP infrastructure and fiber optics. Building reliable connections for communities. 🚀',
  'avatar':
      'https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400',
  'coverImage':
      'https://images.pexels.com/photos/159304/network-cable-ethernet-computer-159304.jpeg?auto=compress&cs=tinysrgb&w=800',
  'role': 'Network Engineer',
  'company': 'Leshark Technologies',
  'location': 'Machakos, Kenya',
  'website': 'lesharktechnologies.com',
  'verified': true,
  'isOnline': true,
  'isVerified': true,
  'joinDate': 'September 2025',
  'followers': 1247,
  'following': 342,
  'posts': 86,
  'connections': 523,
};

// -----------------------------------------------------------------------------
// Core user data — used by both Messages and HomeFeed
// -----------------------------------------------------------------------------
final List<Map<String, dynamic>> kUsers = [
  {
    'id': 1,
    'username': 'wima net',
    'name': 'wima net',
    'avatar':
        'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=400',
    'isOnline': true,
    'isVerified': true,
  },
  {
    'id': 2,
    'username': 'home max core',
    'name': 'home max core',
    'avatar':
        'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400',
    'isOnline': false,
    'isVerified': false,
  },
  {
    'id': 3,
    'username': 'mike_admin',
    'name': 'Mike Rodriguez',
    'avatar':
        'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400',
    'isOnline': true,
    'isVerified': false,
  },
  {
    'id': 4,
    'username': 'lisa_isp',
    'name': 'Lisa Park',
    'avatar':
        'https://images.pexels.com/photos/1239288/pexels-photo-1239288.jpeg?auto=compress&cs=tinysrgb&w=400',
    'isOnline': false,
    'isVerified': false,
  },
  {
    'id': 5,
    'username': 'netgear_pro',
    'name': 'Netgear Pro',
    'avatar':
        'https://images.pixabay.com/photo/2017/03/12/02/57/logo-2136735_1280.png',
    'isOnline': false,
    'isVerified': true,
  },
];

// Stories now derive from kUsers to ensure consistency across Messages and HomeFeed.
// First entry is "Your Story" (current user's own story), rest are friend stories.
final List<Map<String, dynamic>> kStories = [
  {
    "id": 0,
    "userId": 0,
    "username": "Your Story",
    "avatar":
        "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
    "isViewed": false,
    "isOwn": true,
  },
  ...kUsers.map((user) => {
        'id': user['id'],
        'userId': user['id'],
        'username': user['username'],
        'avatar': user['avatar'],
        'isViewed': (user['id'] == 2 || user['id'] == 4), // sample viewed state
        'isOnline': user['isOnline'],
      }),
];

final List<Map<String, dynamic>> kPosts = [
  {
    "id": 1,
    "username": "wima net",
    "userAvatar":
        "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=400",
    "timestamp": "2 hours ago",
    "content":
        "Just finished setting up a new fiber network for our community! The speeds are incredible - 1Gbps up and down. ISP life is rewarding when you see the impact on people's daily lives. 🚀",
    "imageUrl":
        "https://images.pexels.com/photos/159304/network-cable-ethernet-computer-159304.jpeg?auto=compress&cs=tinysrgb&w=800",
    "likes": 42,
    "comments": 8,
    "isLiked": false,
    "isSaved": false,
    "isSponsored": false,
    "hasVerification": true,
  },
  {
    "id": 2,
    "username": "home max core",
    "userAvatar":
        "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400",
    "timestamp": "4 hours ago",
    "content":
        "Excited to share my latest certification in network security! Always learning and growing in this field. What certifications are you working on?",
    "likes": 28,
    "comments": 12,
    "isLiked": true,
    "isSaved": false,
    "isSponsored": false,
    "hasVerification": false,
  },
  {
    "id": 3,
    "username": "cisco_learning",
    "userAvatar":
        "https://images.pixabay.com/photo/2016/12/27/13/10/logo-1933884_1280.png",
    "timestamp": "6 hours ago",
    "content":
        "Master the fundamentals of network routing and switching with our comprehensive CCNA course. Join thousands of professionals who have advanced their careers.",
    "imageUrl":
        "https://images.pexels.com/photos/1181263/pexels-photo-1181263.jpeg?auto=compress&cs=tinysrgb&w=800",
    "likes": 156,
    "comments": 23,
    "isLiked": false,
    "isSaved": true,
    "isSponsored": true,
    "hasVerification": true,
    "ctaButtons": ["Learn More", "Enroll Now"],
  },
  {
    "id": 4,
    "username": "mike_admin",
    "userAvatar":
        "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
    "timestamp": "8 hours ago",
    "content":
        "Server maintenance completed successfully! Zero downtime migration to our new data center. Proud of the team's coordination and planning.",
    "likes": 67,
    "comments": 15,
    "isLiked": false,
    "isSaved": false,
    "isSponsored": false,
    "hasVerification": false,
  },
  {
    "id": 5,
    "username": "lisa_isp",
    "userAvatar":
        "https://images.pexels.com/photos/1239288/pexels-photo-1239288.jpeg?auto=compress&cs=tinysrgb&w=400",
    "timestamp": "10 hours ago",
    "content":
        "Customer satisfaction survey results are in - 98% satisfaction rate! Thank you to everyone who participated. Your feedback helps us improve our services.",
    "likes": 89,
    "comments": 31,
    "isLiked": true,
    "isSaved": false,
    "isSponsored": false,
    "hasVerification": false,
  },
  {
    "id": 6,
    "username": "netgear_pro",
    "userAvatar":
        "https://images.pixabay.com/photo/2017/03/12/02/57/logo-2136735_1280.png",
    "timestamp": "12 hours ago",
    "content":
        "Upgrade your network infrastructure with our latest Wi-Fi 6E routers. Experience blazing fast speeds and reduced latency for your business operations.",
    "imageUrl":
        "https://images.pexels.com/photos/4219654/pexels-photo-4219654.jpeg?auto=compress&cs=tinysrgb&w=800",
    "likes": 203,
    "comments": 45,
    "isLiked": false,
    "isSaved": false,
    "isSponsored": true,
    "hasVerification": true,
    "ctaButtons": ["Shop Now"],
  },
];

final List<Map<String, dynamic>> kFriendSuggestions = [
  {
    "id": 101,
    "name": "David Chen",
    "avatar":
        "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
    "role": "Network Engineer",
    "mutualFriends": 5,
  },
  {
    "id": 102,
    "name": "Emma Wilson",
    "avatar":
        "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
    "role": "ISP Manager",
    "mutualFriends": 3,
  },
  {
    "id": 103,
    "name": "James Rodriguez",
    "avatar":
        "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
    "role": "System Admin",
    "mutualFriends": 8,
  },
  {
    "id": 104,
    "name": "Sophie Taylor",
    "avatar":
        "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400",
    "role": "Tech Support",
    "mutualFriends": 2,
  },
];

// Lightweight conversations summary used by the Messages list (one item per
// conversation). We use the user id as the conversation id for simple one-to-one
// chats here; a real backend can expose a separate conversation id.
final List<Map<String, dynamic>> kConversations = kUsers.map((user) {
  final int id = user['id'] as int;
  
  // Get the latest message from this conversation
  final messages = kMessages[id] ?? [];
  final lastMsg = messages.isNotEmpty ? messages.last : null;
  final lastMessageText = lastMsg?['text'] as String? ?? 'No messages yet';
  final lastMessageTime = lastMsg != null 
      ? _formatMessageTime(lastMsg['timestamp'] as String?) 
      : '—';
  
  return {
    'id': id,
    'userId': id,
    'name': user['name'],
    'avatar': user['avatar'],
    'lastMessage': lastMessageText,
    'timestamp': lastMessageTime,
    'isOnline': user['isOnline'],
    // sample unread counts to demonstrate badges; vary by id
    'unreadCount': id == 1 ? 2 : (id == 3 ? 1 : 0),
    'isVerified': user['isVerified'] as bool? ?? false,
  };
}).toList();

// Helper to format message timestamps for conversations list
String _formatMessageTime(String? timestamp) {
  if (timestamp == null) return '—';
  // For mock data, the timestamps are already formatted strings
  return timestamp;
}

// Per-conversation message history keyed by the conversation id (user id).
// Each message contains senderId (1 = alex_network, 0 = current user) to let
// the UI determine alignment. The timestamp values are small strings for demo.
final Map<int, List<Map<String, dynamic>>> kMessages = {
  1: [
    {
      'id': 1001,
      'senderId': 1,
      'text': 'Hey, did you see the new fiber layout I shared?',
      'timestamp': '09:32',
      'isRead': false,
    },
    {
      'id': 1002,
      'senderId': 0,
      'text': 'Yes — looks great. We can deploy next week.',
      'timestamp': '09:35',
      'isRead': true,
    },
  ],
  2: [
    {
      'id': 2001,
      'senderId': 2,
      'text': 'Can you review my security checklist?',
      'timestamp': '08:10',
      'isRead': true,
    },
    {
      'id': 2002,
      'senderId': 0,
      'text': 'On it, I will send comments by EOD.',
      'timestamp': '08:12',
      'isRead': true,
    },
  ],
  3: [
    {
      'id': 3001,
      'senderId': 3,
      'text': 'Quick question: did the migration finish?',
      'timestamp': 'Yesterday',
      'isRead': false,
    },
  ],
  4: [
    {
      'id': 4001,
      'senderId': 4,
      'text': 'Thanks for the help earlier, much appreciated!',
      'timestamp': '2d',
      'isRead': true,
    },
  ],
  5: [
    {
      'id': 5001,
      'senderId': 5,
      'text': 'New firmware released for the routers — check compatibility.',
      'timestamp': '3d',
      'isRead': true,
    },
  ],
};

// Map userId -> list of posts by that user.
// This lets us show a user's posts when tapping their story in HomeFeed.
final Map<int, List<Map<String, dynamic>>> kUserPosts = {
  1: kPosts.where((p) => p['username'] == 'wima net').toList(),
  2: kPosts.where((p) => p['username'] == 'home max core').toList(),
  3: kPosts.where((p) => p['username'] == 'mike_admin').toList(),
  4: kPosts.where((p) => p['username'] == 'lisa_isp').toList(),
  5: kPosts.where((p) => p['username'] == 'netgear_pro').toList(),
};

// Helper utilities for interacting with the in-memory mock data.
Map<String, dynamic>? getUserById(int id) {
  try {
    return kUsers.firstWhere((u) => u['id'] == id);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? getUserByUsername(String username) {
  try {
    return kUsers.firstWhere((u) => u['username'] == username);
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> getUserPosts(int userId) {
  return kUserPosts[userId] ?? [];
}

void markConversationRead(int userId) {
  try {
    final conv = kConversations.firstWhere((c) => c['userId'] == userId);
    conv['unreadCount'] = 0;
  } catch (_) {
    // ignore if not found
  }

  final msgs = kMessages[userId];
  if (msgs != null) {
    for (final m in msgs) {
      m['isRead'] = true;
    }
  }
}


