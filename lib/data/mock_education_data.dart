/// Centralized mock data for Education Hub (videos, courses, categories, etc.)
library;

final List<Map<String, String>> mockEducationVideos = [
  {
    'id': 'v1',
    'title': 'Understanding Fiber Optics Basics',
    'channel': 'ISPilo Academy',
    'thumbnail':
        'https://images.unsplash.com/photo-1551290130-577c3b3d21df?q=80&w=1628&auto=format&fit=crop',
    'duration': '12:34',
    'views': '12.3k',
  },
  {
    'id': 'v2',
    'title': 'Cisco CCNA: Subnetting Made Easy',
    'channel': 'NetPro Tutorials',
    'thumbnail':
        'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?q=80&w=1635&auto=format&fit=crop',
    'duration': '18:02',
    'views': '45.1k',
  },
  {
    'id': 'v3',
    'title': 'Wireless Network Planning Essentials',
    'channel': 'Wireless Lab',
    'thumbnail':
        'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?q=80&w=1632&auto=format&fit=crop',
    'duration': '09:12',
    'views': '8.4k',
  },
  {
    'id': 'v4',
    'title': 'Secure Your Router: Best Practices',
    'channel': 'Security Hub',
    'thumbnail':
        'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1632&auto=format&fit=crop',
    'duration': '14:27',
    'views': '23.9k',
  },
];

final List<Map<String, dynamic>> mockEnrolledCourses = [
  {
    "id": 1,
    "title": "Advanced Network Security Fundamentals",
    "instructor": "Dr. Sarah Chen",
    "thumbnail":
        "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    "progress": 0.65,
    "isEnrolled": true,
  },
  {
    "id": 2,
    "title": "Cisco CCNA Routing and Switching Complete Course",
    "instructor": "Michael Rodriguez",
    "thumbnail":
        "https://images.unsplash.com/photo-1451187580459-43490279c0fa?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    "progress": 0.32,
    "isEnrolled": true,
  },
];

final List<String> mockTrendingCategories = [
  'All',
  'Network Security',
  'Routing & Switching',
  'Wireless Tech',
  'Cloud Networking',
  'VoIP',
  'Fiber Optics',
  'Network Management',
];
