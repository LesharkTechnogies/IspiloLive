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

List<Map<String, dynamic>> getUserPosts(int userId) {
  return kUserPosts[userId] ?? [];
}


