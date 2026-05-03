import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/fullscreen_image_viewer.dart';
import '../../model/social_model.dart';
import '../../model/repository/social_repository.dart';
import 'widgets/create_post_bottom_sheet.dart';
import '../../core/services/media_download_service.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> with TickerProviderStateMixin {
  // Runtime-only cache: survives widget rebuild/navigation while app is alive.
  static bool _hasBootstrappedOnce = false;
  static List<PostModel> _cachedPosts = <PostModel>[];
  static Set<String> _cachedSeenPostIds = <String>{};
  static List<UserModel> _cachedSuggestions = <UserModel>[];
  static List<Map<String, dynamic>> _cachedGroups = <Map<String, dynamic>>[];
  static int _cachedPage = 0;
  static bool _cachedHasMorePosts = true;

  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedPostIds = <String>{};

  bool _isLoading = true;
  bool _hasMorePosts = true;
  int _currentBottomIndex = 0;
  int _page = 0;
  final int _pageSize = 20;
  final int _adInterval = 6; // Insert ad after every 6 posts
  bool _isPremium = false; // Premium users see no ads
  String? _currentUserId; // Check ownership of post for edit/delete

  // Feed data
  final List<PostModel> _posts = [];
  final Set<String> _seenPostIds = <String>{};
  final List<_FeedEntry> _feedEntries = <_FeedEntry>[];

  // Suggestions (users to follow)
  List<UserModel> _friendSuggestions = [];
  List<Map<String, dynamic>> _groups = [];
  Timer? _backgroundResyncTimer;

  // Ads (can be fetched from API later). Each ad contains: title, image, advertiserId, cta
  final List<Map<String, dynamic>> _adsPool = [
    {
      'id': 'ad-1',
      'title': 'Upgrade your network with FiberPro',
      'imageUrl': 'https://images.unsplash.com/photo-1518770660439-4636190af475',
      'advertiserId': 'seller-123',
      'cta': 'Learn more',
    },
    {
      'id': 'ad-2',
      'title': 'Get 20% off on Cisco CCNA Course',
      'imageUrl': 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31',
      'advertiserId': 'instructor-456',
      'cta': 'Learn more',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _restoreFromRuntimeCache();
    _initUserAndLoad();
    _startBackgroundResync();
  }

  void _restoreFromRuntimeCache() {
    if (_cachedPosts.isNotEmpty) {
      _posts
        ..clear()
        ..addAll(_cachedPosts);
      _seenPostIds
        ..clear()
        ..addAll(_cachedSeenPostIds);
      _friendSuggestions = List<UserModel>.from(_cachedSuggestions);
      _groups = List<Map<String, dynamic>>.from(_cachedGroups);
      _page = _cachedPage;
      _hasMorePosts = _cachedHasMorePosts;
      _isLoading = false;
      _rebuildFeedEntries();
    } else {
      // Show skeleton only before first successful feed bootstrap in app runtime.
      _isLoading = !_hasBootstrappedOnce;
    }
  }

  void _updateRuntimeCache() {
    _cachedPosts = List<PostModel>.from(_posts);
    _cachedSeenPostIds = Set<String>.from(_seenPostIds);
    _cachedSuggestions = List<UserModel>.from(_friendSuggestions);
    _cachedGroups = List<Map<String, dynamic>>.from(_groups);
    _cachedPage = _page;
    _cachedHasMorePosts = _hasMorePosts;
  }

  Future<void> _initUserAndLoad() async {
    try {
      final currentUser = await UserRepository.getCurrentUser();
      _isPremium = currentUser.isPremium; // backend-driven flag
      _currentUserId = currentUser.id;
    } catch (_) {
      _isPremium = false;
    }
    if (_posts.isEmpty) {
      await _loadInitialPosts(showSkeleton: !_hasBootstrappedOnce);
      await _loadSuggestions();
    } else {
      // Already hydrated from cache: skip background resync to prevent auto-reloads.
      // The user will tap the logo or pull to refresh to update the feed.
      unawaited(_loadSuggestions());
    }
  }

  @override
  void dispose() {
    _backgroundResyncTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startBackgroundResync() {
    _backgroundResyncTimer?.cancel();
    _backgroundResyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _resyncAppDataInBackground(),
    );
  }

  Future<void> _resyncAppDataInBackground() async {
    if (!mounted || _isLoading) return;

    try {
      final results = await Future.wait([
        PostRepository.getFeed(page: 0, size: _pageSize),
        PostRepository.getGroupFeed(page: 0, size: _pageSize),
      ]);
      final latestPosts = results[0];
      final latestGroupPosts = results[1];
      final combinedLatest = [...latestPosts, ...latestGroupPosts];
      final latestSuggestions =
          await UserRepository.getUserSuggestions(page: 0, size: 10);
      final latestGroups = await PostRepository.getGroups(page: 0, size: 10);

      if (!mounted) return;

      final currentById = <String, PostModel>{for (final p in _posts) p.id: p};
      for (final post in latestPosts) {
        currentById[post.id] = post;
      }

      final ordered = <PostModel>[];
      final seen = <String>{};

      for (final post in combinedLatest) {
        if (seen.add(post.id)) ordered.add(currentById[post.id]!);
      }
      for (final post in _posts) {
        if (seen.add(post.id)) ordered.add(currentById[post.id]!);
      }

      setState(() {
        _posts
          ..clear()
          ..addAll(ordered);
        _seenPostIds
          ..clear()
          ..addAll(_posts.map((p) => p.id));
        _friendSuggestions = latestSuggestions;
        _groups = latestGroups;
        _rebuildFeedEntries();
      });
      _hasBootstrappedOnce = true;
      _updateRuntimeCache();
    } catch (e) {
      debugPrint('Background resync failed: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadInitialPosts({bool showSkeleton = false}) async {
    if (showSkeleton) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        PostRepository.getFeed(page: 0, size: _pageSize),
        PostRepository.getGroupFeed(page: 0, size: _pageSize),
      ]);
      final posts = results[0];
      final groupPosts = results[1];
      await _appendUniquePosts([...posts, ...groupPosts]);

      if (!mounted) return;
      setState(() {        _page = 1;
        _hasMorePosts = (posts.length + groupPosts.length) >= _pageSize;
        _isLoading = false;
        _rebuildFeedEntries();
      });
      _hasBootstrappedOnce = true;
      _updateRuntimeCache();
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load feed. Please try again.')),
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        PostRepository.getFeed(page: _page, size: _pageSize),
        PostRepository.getGroupFeed(page: _page, size: _pageSize),
      ]);
      final newPosts = results[0];
      final newGroupPosts = results[1];
      final combinedNewPosts = [...newPosts, ...newGroupPosts];
      final beforeAppendCount = _posts.length;
      await _appendUniquePosts(combinedNewPosts);

      if (!mounted) return;      setState(() {
        _page++;
        if (combinedNewPosts.length < _pageSize || _posts.length == beforeAppendCount) {
          // If fewer than page size returned or no new unique posts, assume end
          _hasMorePosts = false;
        }
        _rebuildFeedEntries();
      });
      _hasBootstrappedOnce = true;
      _updateRuntimeCache();
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load more posts.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _appendUniquePosts(List<PostModel> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final likedPosts = prefs.getStringList('liked_posts') ?? [];

    for (final post in posts) {
      if (_seenPostIds.add(post.id)) {
        final isLiked = post.isLiked || likedPosts.contains(post.id);
        _posts.add(post.copyWith(isLiked: isLiked));
      }
    }
    _rebuildFeedEntries();
  }

  void _rebuildFeedEntries() {
    _feedEntries
      ..clear();

    final shuffled = List<PostModel>.from(_posts);
    shuffled.shuffle(Random());

    var adIndex = 0;
    for (var i = 0; i < shuffled.length; i++) {
      if (!_isPremium && i > 0 && i % _adInterval == 0) {
        final ad = _adsPool[adIndex % _adsPool.length];
        _feedEntries.add(_FeedEntry.ad(ad));
        adIndex++;
      }
      _feedEntries.add(_FeedEntry.post(shuffled[i]));
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      _friendSuggestions = await UserRepository.getUserSuggestions(page: 0, size: 10);
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }

    try {
      _groups = await PostRepository.getGroups(page: 0, size: 10);
    } catch (e) {
      debugPrint('Error loading groups: $e');
    }

    if (mounted) {
      setState(() {});
    }
    _updateRuntimeCache();
  }

  Future<void> _refreshFeed() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _hasMorePosts = true;
      _page = 0;
      _seenPostIds.clear();
    });

    // Keep currently visible posts while refreshing to avoid skeleton flicker.
    final latestPosts = await PostRepository.getFeed(page: 0, size: _pageSize);
    if (!mounted) return;

    setState(() {
      _posts
        ..clear()
        ..addAll(latestPosts);
      _seenPostIds
        ..clear()
        ..addAll(latestPosts.map((p) => p.id));
      _page = 1;
      _hasMorePosts = latestPosts.length >= _pageSize;
      _isLoading = false;
    });

    _hasBootstrappedOnce = true;
    _updateRuntimeCache();
    await _loadSuggestions();
  }

  final Set<String> _likingPosts = <String>{};

  // Interactions
  Future<void> _toggleLike(PostModel post) async {
    if (_likingPosts.contains(post.id)) return;
    _likingPosts.add(post.id);

    final bool previousLikeState = post.isLiked;
    final int previousLikesCount = post.likesCount;
    final int newLikesCount = previousLikeState ? (previousLikesCount - 1) : (previousLikesCount + 1);

    // Optimistic UI Update
    setState(() {
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        _posts[idx] = post.copyWith(
          isLiked: !previousLikeState,
          likesCount: newLikesCount >= 0 ? newLikesCount : 0,
        );
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> likedPosts = prefs.getStringList('liked_posts') ?? [];
      
      if (!previousLikeState) {
        if (!likedPosts.contains(post.id)) likedPosts.add(post.id);
      } else {
        likedPosts.remove(post.id);
      }
      await prefs.setStringList('liked_posts', likedPosts);

      final updatedPost = await PostRepository.toggleLikePost(post.id);
      
      // Update with server response if needed (to sync counts accurately)
      if (mounted) {
        setState(() {
          final idx = _posts.indexWhere((p) => p.id == post.id);
          if (idx != -1) {
            // Keep local liked state if the server's boolean is missing or incorrect
            // but use the server's count
            _posts[idx] = _posts[idx].copyWith(
              likesCount: updatedPost.likesCount,
              isLiked: updatedPost.isLiked || likedPosts.contains(post.id),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          final idx = _posts.indexWhere((p) => p.id == post.id);
          if (idx != -1) {
            _posts[idx] = post.copyWith(
              isLiked: previousLikeState,
              likesCount: previousLikesCount,
            );
          }
        });
      }
    } finally {
      _likingPosts.remove(post.id);
    }
  }

  Future<void> _savePost(PostModel post) async {
    try {
      await PostRepository.savePost(post.id);
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        _posts[idx] = _posts[idx].copyWith(isSaved: true);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error saving post: $e');
    }
  }

  Future<void> _unsavePost(PostModel post) async {
    try {
      await PostRepository.unsavePost(post.id);
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        _posts[idx] = _posts[idx].copyWith(isSaved: false);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error unsaving post: $e');
    }
  }

  Future<void> _openComments(PostModel post) async {
    final result = await Navigator.pushNamed(context, '/post-comments', arguments: post.toJson());

    if (result is int && result > 0) {
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        setState(() {
          _posts[idx] = _posts[idx].copyWith(
            commentsCount: _posts[idx].commentsCount + result,
          );
        });
      }
    }
  }

  Future<void> _editPost(PostModel post) async {
    // We launch the bottom sheet but pass the existing post to signify edit mode
    CreatePostBottomSheet.show(
      context, 
      existingPost: post,
      onPostCreated: _refreshFeed,
    );
  }

  Future<void> _deletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to permanently delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PostRepository.deletePost(post.id);
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
          _seenPostIds.remove(post.id);
        });
        _updateRuntimeCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post.')),
          );
        }
      }
    }
  }

  void _sharePost(PostModel post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shared: ${post.content.substring(0, post.content.length > 20 ? 20 : post.content.length)}...')),
    );
  }

  // Ads rendering
  Widget _buildAdCard(ColorScheme colorScheme, Map<String, dynamic> ad) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ad['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ad['imageUrl'] as String,
                height: 18.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(height: 1.h),
          Text(
            ad['title'] as String? ?? 'Sponsored',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 0.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sponsored',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to advertiser profile/page
                  Navigator.pushNamed(
                    context,
                    '/profile',
                    arguments: {'userId': ad['advertiserId']},
                  );
                },
                child: const Text('Learn more'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'ispilo',
        isTitleLoading: _isLoading && _posts.isNotEmpty,
        onTitleTap: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          _refreshFeed();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Suggestions to follow
            SliverToBoxAdapter(
              child: _friendSuggestions.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: _buildSuggestionsRow(colorScheme),
                    ),
            ),

            // Groups to join
            SliverToBoxAdapter(
              child: _groups.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: _buildGroupsRow(colorScheme),
                    ),
            ),

            // Feed posts with ad slots
            if (_posts.isEmpty && _isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostSkeleton(colorScheme),
                  childCount: 6,
                ),
              )
            else if (_posts.isEmpty && !_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.post_add_outlined, size: 64, color: colorScheme.outline.withAlpha(150)),
                      SizedBox(height: 2.h),
                      Text(
                        'No posts yet.',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'There are no posts to show right now.\nBe the first to share something!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Post'),
                        onPressed: () {
                          CreatePostBottomSheet.show(
                            context,
                            onPostCreated: _refreshFeed,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                  if (index >= _feedEntries.length) {
                    return _buildPostSkeleton(colorScheme);
                  }

                  final entry = _feedEntries[index];
                  if (entry.isAd) {
                    return _buildAdCard(colorScheme, entry.ad!);
                  }

                  return _buildPostCard(colorScheme, entry.post!);
                },
                childCount: _feedEntries.length + (_isLoading ? 1 : 0),
              ),
            ),

            // End or loading indicator
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Center(
                  child: (!_hasMorePosts && _posts.isNotEmpty)
                          ? Text(
                              'No more posts',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        variant: CustomBottomBarVariant.standard,
        onTap: (i) {
          setState(() => _currentBottomIndex = i);
          // ...existing code...
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CreatePostBottomSheet.show(context, onPostCreated: _refreshFeed);
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildPostSkeleton(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    Container(
                      height: 8,
                      width: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.8.h),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: 0.8.h),
          Container(
            height: 10,
            width: 70.w,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: 1.8.h),
          Container(
            height: 20.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Friends to follow', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/discover'),
              child: const Text('See all'),
            ),
          ],
        ),
        SizedBox(
          height: 20.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _friendSuggestions.length,
            itemBuilder: (context, index) {
              final user = _friendSuggestions[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile', arguments: {'userId': user.id}),
                child: Container(
                  width: 34.w,
                  margin: EdgeInsets.only(right: 3.w),
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ProfileAvatar(
                        imageUrl: user.avatar,
                        size: 34,
                        isOnline: false,
                      ),
                      SizedBox(height: 0.6.h),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 4.h,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            try {
                              await UserRepository.followUser(user.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Following ${user.name}')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to follow user.')),
                              );
                            }
                          },
                          child: const Text('Follow'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsRow(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Suggested Groups', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ],
        ),
        SizedBox(
          height: 20.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return Container(
                width: 36.w,
                margin: EdgeInsets.only(right: 3.w),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: group['avatar'] != null && group['avatar'].toString().isNotEmpty 
                        ? NetworkImage(group['avatar']) 
                        : null,
                      child: group['avatar'] == null || group['avatar'].toString().isEmpty
                        ? Icon(Icons.group, color: colorScheme.onPrimaryContainer, size: 28)
                        : null,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      group['name'] ?? 'Group',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 4.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          try {
                            await PostRepository.joinGroup(group['id']?.toString() ?? '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Joined ${group['name']}')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to join group.')),
                            );
                          }
                        },
                        child: const Text('Join'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatPostTime(DateTime createdAt) {
    final now = DateTime.now();
    var diff = now.difference(createdAt);
    if (diff.isNegative) {
      diff = Duration.zero;
    }

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    final dt = createdAt;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildPostCard(ColorScheme colorScheme, PostModel post) {
    final textWidget = _buildExpandablePostText(post, colorScheme);
    final topBorderColor = Theme.of(context).brightness == Brightness.dark ? Colors.lightGreen.shade800 : Colors.lightGreen.shade300;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.lightGreen.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            color: topBorderColor,
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
              // Avatar with privacy awareness
              GestureDetector(
                onTap: () {
                  if (post.avatarPublic && post.userAvatar.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => FullScreenImageViewer(
                          imageUrl: post.userAvatar, heroTag: 'avatar_${post.id}_${post.userAvatar}'),
                    );
                  } else {
                    Navigator.pushNamed(context, '/profile', arguments: {'userId': post.userId});
                  }
                },
                child: post.avatarPublic && post.userAvatar.isNotEmpty
                    ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(post.userAvatar))
                    : CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          post.username.isNotEmpty ? post.username[0].toUpperCase() : 'U',
                          style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile', arguments: {'userId': post.userId}),
                      child: Row(children: [
                        Text(post.username, style: Theme.of(context).textTheme.titleSmall),
                        if (_isPremium) ...[
                          SizedBox(width: 1.w),
                          Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
                        ],
                      ]),
                    ),
                    if (post.isGroupPost && (post.groupName?.trim().isNotEmpty ?? false))
                      Padding(
                        padding: EdgeInsets.only(top: 0.2.h),
                        child: GestureDetector(
                          onTap: () {
                            if (post.groupId != null && post.groupId!.isNotEmpty) {
                              Navigator.pushNamed(context, '/group-profile', arguments: {
                                'groupId': post.groupId,
                                'groupName': post.groupName,
                              });
                            }
                          },
                          child: Text(
                            'Group • ${post.groupName}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    Text(
                      _formatPostTime(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  final isOwner = _currentUserId == post.userId;
                  
                  // Post actions: save, share, report, edit, delete
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          if (isOwner) ...[
                            ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: const Text('Edit post'),
                              onTap: () {
                                Navigator.pop(context);
                                _editPost(post);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.delete_outline, color: colorScheme.error),
                              title: Text('Delete post', style: TextStyle(color: colorScheme.error)),
                              onTap: () {
                                Navigator.pop(context);
                                _deletePost(post);
                              },
                            ),
                            const Divider(),
                          ],
                          ListTile(
                            leading: const Icon(Icons.bookmark_add_outlined),
                            title: Text(post.isSaved ? 'Unsave' : 'Save'),
                            onTap: () {
                              Navigator.pop(context);
                              post.isSaved ? _unsavePost(post) : _savePost(post);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.share_outlined),
                            title: const Text('Share'),
                            onTap: () {
                              Navigator.pop(context);
                              _sharePost(post);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: const Text('Report'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.filter_alt_off_outlined),
                            title: const Text('Remove repeated posts'),
                            subtitle: const Text('Clean up any duplicates in your feed'),
                            onTap: () {
                              Navigator.pop(context);
                              _removeRepeatedPosts();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 1.h),
          
          if (post.images.isNotEmpty || (post.imageUrl != null && post.imageUrl!.isNotEmpty))
            AdaptivePostMediaLayout(
              imageUrl: post.images.isNotEmpty ? post.images.first : post.imageUrl!,
              textContent: textWidget,
            )
          else
            textWidget,

          SizedBox(height: 1.h),
          Row(
            children: [
              IconButton(
                icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.lightGreen : null),
                onPressed: () => _toggleLike(post),
              ),
              Text('${post.likesCount}'),
              SizedBox(width: 4.w),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => _openComments(post),
              ),
              Text('${post.commentsCount}'),
              IconButton(
                icon: const Icon(Icons.message_outlined),
                tooltip: 'Message seller',
                onPressed: () => _openMessageWithPostOwner(post),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () => post.isSaved ? _unsavePost(post) : _savePost(post),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _sharePost(post),
              ),
            ],
          ),
        ],
      ),
    ),
          ],
        ),
    );
  }

  Future<void> _openMessageWithPostOwner(PostModel post) async {
    final targetUserId = post.userId;
    if (targetUserId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open chat for this user')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'id': 'conv_$targetUserId',
        'userId': targetUserId,
        'name': post.username,
        'avatar': post.userAvatar,
        'isOnline': false,
        'isVerified': false,
        'isGroup': false,
        'unreadCount': 0,
        'encryptionKey': null,
      },
    );
  }

  void _removeRepeatedPosts() {
    final before = _posts.length;
    final unique = <String>{};
    _posts.removeWhere((p) => !unique.add(p.id));
    _seenPostIds
      ..clear()
      ..addAll(_posts.map((p) => p.id));
    final removed = before - _posts.length;
    if (mounted) {
      setState(() {});
      _updateRuntimeCache();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(removed > 0 ? 'Removed $removed repeated post(s)' : 'No repeated posts found')),
      );
    }
  }

  Widget _buildExpandablePostText(PostModel post, ColorScheme colorScheme) {
    final content = post.content.trim();
    const int previewChars = 150;

    if (content.length <= previewChars) {
      return Text(content);
    }

    final isExpanded = _expandedPostIds.contains(post.id);
    final preview = '${content.substring(0, previewChars)}...';
    final expandedContent = content.length > 1500 ? '${content.substring(0, 1500)}...\n(Text truncated due to length)' : content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isExpanded ? expandedContent : preview),
        SizedBox(height: 0.6.h),
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedPostIds.remove(post.id);
              } else {
                _expandedPostIds.add(post.id);
              }
            });
          },
          child: Text(
            isExpanded ? 'See less' : 'See more',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class AdaptivePostMediaLayout extends StatefulWidget {
  final String? imageUrl;
  final Widget textContent;

  const AdaptivePostMediaLayout({super.key, this.imageUrl, required this.textContent});

  @override
  State<AdaptivePostMediaLayout> createState() => _AdaptivePostMediaLayoutState();
}

class _AdaptivePostMediaLayoutState extends State<AdaptivePostMediaLayout> {
  double? _aspectRatio;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _resolveImage();
    }
  }

  @override
  void didUpdateWidget(covariant AdaptivePostMediaLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _aspectRatio = null;
      _hasError = false;
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        _resolveImage();
      }
    }
  }

  void _resolveImage() {
    final ImageStream stream = NetworkImage(widget.imageUrl!).resolve(const ImageConfiguration());
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _aspectRatio = info.image.width / info.image.height;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      },
    );
    stream.addListener(listener);
  }

  Widget _buildDownloadButton(BuildContext context, String url) {
    return GestureDetector(
      onTap: () async {
        final ext = url.split('.').last.split('?').first;
        final name = 'ispilo_post_image_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
        await MediaDownloadService.downloadFile(url, name, context);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.download, color: Colors.white, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty || _hasError) {
      return widget.textContent;
    }

    if (_aspectRatio == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.textContent,
          SizedBox(height: 1.5.h),
          SizedBox(
            height: 25.h,
            width: double.infinity,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      );
    }

    // Enforce aspect ratio limits
    // Portrait max: 4:5 = 0.8
    // Landscape max: 1.91:1 = 1.91
    // Square 1:1 falls between these limits naturally
    double clampedAspectRatio = _aspectRatio!;
    if (clampedAspectRatio < 0.8) {
      clampedAspectRatio = 0.8;
    } else if (clampedAspectRatio > 1.91) {
      clampedAspectRatio = 1.91;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.textContent,
        SizedBox(height: 1.5.h),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 65.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: clampedAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover, // Crop edges to fit while preserving aspect ratio
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                    ),
                  ),
                  if (widget.imageUrl!.startsWith('http'))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildDownloadButton(context, widget.imageUrl!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedEntry {
  final PostModel? post;
  final Map<String, dynamic>? ad;

  const _FeedEntry._({this.post, this.ad});

  bool get isAd => ad != null;

  factory _FeedEntry.post(PostModel post) => _FeedEntry._(post: post);

  factory _FeedEntry.ad(Map<String, dynamic> ad) => _FeedEntry._(ad: ad);
}
