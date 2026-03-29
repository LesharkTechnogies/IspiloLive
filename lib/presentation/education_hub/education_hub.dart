import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/category_chip_widget.dart';
import './widgets/course_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/my_learning_section_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/video_card_widget.dart';
import '../../data/mock_education_data.dart';

class EducationHub extends StatefulWidget {
  const EducationHub({super.key});

  @override
  State<EducationHub> createState() => _EducationHubState();
}

class _EducationHubState extends State<EducationHub>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  Map<String, dynamic> _filters = {
    'category': 'All Categories',
    'skillLevel': 'All Levels',
    'duration': 'Any Duration',
    'priceRange': 'Any Price',
  };

  bool _isLoading = false;
  bool _isSearching = false;

  // Trending categories (mocked)
  final List<String> _trendingCategories = mockTrendingCategories;

  // Enrolled courses (mocked)
  final List<Map<String, dynamic>> _enrolledCourses = mockEnrolledCourses;

  // Education hub videos (mocked)
  final List<Map<String, String>> _videos = mockEducationVideos;

  // Mock data for course catalog
  final List<Map<String, dynamic>> _allCourses = [
    {
      "id": 1,
      "title": "Advanced Network Security Fundamentals",
      "instructor": "Dr. Sarah Chen",
      "thumbnail":
          "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "rating": 4.8,
      "reviewCount": 1247,
      "price": "\$89.99",
      "originalPrice": "\$129.99",
      "duration": "12h 30m",
      "isNew": false,
      "isEnrolled": true,
      "progress": 0.65,
      "category": "Network Security",
    },
    {
      "id": 2,
      "title": "Cisco CCNA Routing and Switching Complete Course",
      "instructor": "Michael Rodriguez",
      "thumbnail":
          "https://images.unsplash.com/photo-1451187580459-43490279c0fa?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "rating": 4.9,
      "reviewCount": 2156,
      "price": "\$149.99",
      "duration": "25h 45m",
      "isNew": false,
      "isEnrolled": true,
      "progress": 0.32,
      "category": "Routing & Switching",
    },
    {
      "id": 3,
      "title": "Wireless Network Design and Implementation",
      "instructor": "Jennifer Park",
      "thumbnail":
          "https://images.unsplash.com/photo-1544197150-b99a580bb7a8?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "rating": 4.7,
      "reviewCount": 892,
      "price": "\$79.99",
      "duration": "8h 15m",
      "isNew": true,
      "isEnrolled": false,
      "progress": 0.0,
      "category": "Wireless Tech",
    },
    {
      "id": 4,
      "title": "Cloud Networking with AWS and Azure",
      "instructor": "David Thompson",
      "thumbnail":
          "https://images.unsplash.com/photo-1451187580459-43490279c0fa?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "rating": 4.6,
      "reviewCount": 1543,
      "price": "\$199.99",
      "duration": "18h 20m",
      "isNew": true,
      "isEnrolled": false,
      "progress": 0.0,
      "category": "Cloud Networking",
    },
    {
      "id": 5,
      "title": "VoIP Systems Administration and Troubleshooting",
      "instructor": "Lisa Wang",
      "thumbnail":
          "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "rating": 4.5,
      "reviewCount": 678,
      "price": "Free",
      "duration": "6h 30m",
      "isNew": false,
      "isEnrolled": false,
      "progress": 0.0,
      "category": "VoIP",
    },
    {
      "id": 6,
      "title": "Fiber Optic Network Installation and Maintenance",
      "instructor": "Robert Kim",
      "thumbnail":
          "https://images.unsplash.com/photo-1544197150-b99a580bb7a8?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "rating": 4.8,
      "reviewCount": 1089,
      "price": "\$119.99",
      "duration": "14h 10m",
      "isNew": false,
      "isEnrolled": false,
      "progress": 0.0,
      "category": "Fiber Optics",
    },
  ];

  List<Map<String, dynamic>> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    _filteredCourses = List.from(_allCourses);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more courses if needed
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      _filterCourses();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filterCourses();
    });
  }

  void _filterCourses() {
    _filteredCourses = _allCourses.where((course) {
      final matchesSearch = _searchQuery.isEmpty ||
          (course["title"] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (course["instructor"] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          (course["category"] as String) == _selectedCategory ||
          (_selectedCategory == 'Wireless Tech' &&
              (course["category"] as String) == 'Wireless Tech');

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      // Apply additional filtering logic based on filters
      _filterCourses();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    _refreshController.refreshCompleted();
  }

  void _onCourseCardTap(Map<String, dynamic> course) {
    // Navigate to course detail with shared element transition
    Navigator.pushNamed(context, '/course-detail', arguments: course);
  }

  void _onContinueCourse(Map<String, dynamic> course) {
    // Navigate to course player/lesson
    Navigator.pushNamed(context, '/course-player', arguments: course);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _filters,
        onFiltersApplied: _onFiltersApplied,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Education Hub',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to notifications
            },
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              size: 24,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: CustomIconWidget(
              iconName: 'settings_outlined',
              size: 24,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: SearchBarWidget(
                hintText: 'Search courses, instructors...',
                onChanged: _onSearchChanged,
                onFilterTap: _showFilterBottomSheet,
                onSubmitted: () {
                  // Handle search submission
                },
              ),
            ),

            // Trending Categories
            if (!_isSearching) ...[
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 1.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          'Trending Categories',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        height: 5.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _trendingCategories.length,
                          itemBuilder: (context, index) {
                            final category = _trendingCategories[index];
                            return CategoryChipWidget(
                              category: category,
                              isSelected: category == _selectedCategory,
                              onTap: () => _onCategorySelected(category),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Featured Videos (Horizontal grid 2 up)
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.only(top: 1.h, bottom: 1.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          'Featured Videos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        height: 28.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: (_videos.length / 3).ceil(),
                          itemBuilder: (context, colIndex) {
                            final firstIndex = colIndex * 3;
                            final secondIndex = firstIndex + 1;
                            final thirdIndex = firstIndex + 2;
                            final first = _videos[firstIndex];
                            final second = secondIndex < _videos.length ? _videos[secondIndex] : null;
                            final third = thirdIndex < _videos.length ? _videos[thirdIndex] : null;

                            return Container(
                              width: 30.w + 30.w + 30.w + 31 * 2,
                              margin: const EdgeInsets.only(right: 31),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 30.w,
                                    height: 27.h,
                                    child: VideoCardWidget(
                                      thumbnailUrl: first['thumbnail']!,
                                      title: first['title']!,
                                      subtitle: first['channel'],
                                      duration: first['duration'],
                                      views: first['views'],
                                      onTap: () {
                                        // TODO: Navigate to video player/details
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 31),
                                  if (second != null)
                                    SizedBox(
                                      width: 30.w,
                                      height: 27.h,
                                      child: VideoCardWidget(
                                        thumbnailUrl: second['thumbnail']!,
                                        title: second['title']!,
                                        subtitle: second['channel'],
                                        duration: second['duration'],
                                        views: second['views'],
                                        onTap: () {
                                          // TODO: Navigate to video player/details
                                        },
                                      ),
                                    )
                                  else
                                    SizedBox(width: 30.w, height: 27.h),
                                  const SizedBox(width: 31),
                                  if (third != null)
                                    SizedBox(
                                      width: 30.w,
                                      height: 27.h,
                                      child: VideoCardWidget(
                                        thumbnailUrl: third['thumbnail']!,
                                        title: third['title']!,
                                        subtitle: third['channel'],
                                        duration: third['duration'],
                                        views: third['views'],
                                        onTap: () {
                                          // TODO: Navigate to video player/details
                                        },
                                      ),
                                    )
                                  else
                                    SizedBox(width: 30.w, height: 27.h),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // My Learning Section (with videos)
              SliverToBoxAdapter(
                child: MyLearningSectionWidget(
                  enrolledCourses: _enrolledCourses,
                  onContinueCourse: _onContinueCourse,
                  enrolledVideos: _videos,
                ),
              ),
            ],

            // Course Catalog Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSearching
                          ? 'Search Results (${_filteredCourses.length})'
                          : 'Course Catalog',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!_isSearching)
                      TextButton(
                        onPressed: () {
                          // Navigate to full catalog
                        },
                        child: Text(
                          'View All',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Course List or Empty State
            _filteredCourses.isEmpty
                ? SliverFillRemaining(
                    child: EmptyStateWidget(
                      title: _isSearching
                          ? 'No courses found'
                          : 'No courses available',
                      subtitle: _isSearching
                          ? 'Try adjusting your search or browse categories'
                          : 'Check back later for new courses',
                      suggestions: _isSearching
                          ? [
                              'Network Security',
                              'Cisco CCNA',
                              'Wireless',
                              'Cloud Networking',
                            ]
                          : null,
                      actionText:
                          _isSearching ? 'Browse Categories' : 'Refresh',
                      onActionPressed: () {
                        if (_isSearching) {
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                            _selectedCategory = 'All';
                            _filterCourses();
                          });
                        } else {
                          _onRefresh();
                        }
                      },
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _filteredCourses.length) {
                          return _isLoading
                              ? Container(
                                  padding: EdgeInsets.all(4.w),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final course = _filteredCourses[index];
                        return CourseCardWidget(
                          course: course,
                          onTap: () => _onCourseCardTap(course),
                          onSave: () {
                            // Handle save for later
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Course saved for later'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onShare: () {
                            // Handle share
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Course shared'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onWishlist: () {
                            // Handle add to wishlist
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to wishlist'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                      childCount:
                          _filteredCourses.length + (_isLoading ? 1 : 0),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}

// Helper class for refresh controller
class RefreshController {
  void refreshCompleted() {
    // Implementation for refresh completion
  }

  void dispose() {
    // Cleanup resources
  }
}
