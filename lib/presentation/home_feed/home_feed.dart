import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/profile_avatar.dart';
import '../../model/social_model.dart';
import '../../model/repository/social_repository.dart';
import '../../core/services/conversation_service.dart';
import 'widgets/create_post_bottom_sheet.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedPostIds = <String>{};

  bool _isLoading = false;
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

  // Suggestions (users to follow)
  List<UserModel> _friendSuggestions = [];

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
    _initUserAndLoad();
  }

  Future<void> _initUserAndLoad() async {
    try {
      final currentUser = await UserRepository.getCurrentUser();
      _isPremium = currentUser.isPremium; // backend-driven flag
      _currentUserId = currentUser.id;
    } catch (_) {
      _isPremium = false;
    }
    await _loadInitialPosts();
    await _loadSuggestions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadInitialPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await PostRepository.getFeed(page: 0, size: _pageSize);
      _appendUniquePosts(posts);
      setState(() {
        _page = 1;
        _hasMorePosts = posts.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load feed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final newPosts = await PostRepository.getFeed(page: _page, size: _pageSize);
      final beforeAppendCount = _posts.length;
      _appendUniquePosts(newPosts);
      setState(() {
        _page++;
        if (newPosts.length < _pageSize || _posts.length == beforeAppendCount) {
          // If fewer than page size returned or no new unique posts, assume end
          _hasMorePosts = false;
        }
      });
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more posts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _appendUniquePosts(List<PostModel> posts) {
    for (final post in posts) {
      if (_seenPostIds.add(post.id)) {
        _posts.add(post);
      }
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      _friendSuggestions = await UserRepository.getUserSuggestions(page: 0, size: 10);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  Future<void> _refreshFeed() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _hasMorePosts = true;
      _page = 0;
      _posts.clear();
      _seenPostIds.clear();
    });
    await _loadInitialPosts();
    await _loadSuggestions();
  }

  // Interactions
  Future<void> _toggleLike(PostModel post) async {
    try {
      final updatedPost = await PostRepository.toggleLikePost(post.id);
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        setState(() {
          _posts[idx] = updatedPost;
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
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
      appBar: const CustomAppBar(title: 'ispilo'),
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

            // Feed posts with ad slots
            if (_posts.isEmpty && !_isLoading)
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
                  // Interleave ads at intervals, skip if premium
                  if (!_isPremium && index > 0 && index % _adInterval == 0) {
                    final ad = _adsPool[(index ~/ _adInterval - 1) % _adsPool.length];
                    return _buildAdCard(colorScheme, ad);
                  }

                  final feedIndex = _isPremium
                      ? index
                      : index - (index ~/ _adInterval); // adjust index if ads are inserted

                  if (feedIndex >= _posts.length) {
                    return _buildLoading(colorScheme);
                  }

                  final post = _posts[feedIndex];
                  return _buildPostCard(colorScheme, post);
                },
                childCount: _posts.length + (_isLoading ? 1 : 0) + (_isPremium ? 0 : max(0, _posts.length ~/ _adInterval)),
              ),
            ),

            // End or loading indicator
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : (!_hasMorePosts && _posts.isNotEmpty)
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

  Widget _buildLoading(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: const Center(child: CircularProgressIndicator()),
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
                                SnackBar(content: Text('Failed to follow: $e')),
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

  Widget _buildPostCard(ColorScheme colorScheme, PostModel post) {
    final textWidget = _buildExpandablePostText(post, colorScheme);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
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
        children: [
          Row(
            children: [
              // Avatar with privacy awareness
              if (post.avatarPublic && post.userAvatar.isNotEmpty)
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(post.userAvatar))
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(post.username, style: Theme.of(context).textTheme.titleSmall),
                      if (_isPremium) ...[
                        SizedBox(width: 1.w),
                        Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
                      ],
                    ]),
                    Text(
                      '${post.createdAt}',
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
                icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.red : null),
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
    );
  }

  Future<void> _openMessageWithPostOwner(PostModel post) async {
    final sellerId = post.userId;
    if (sellerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open chat for this user')),
      );
      return;
    }

    try {
      final conversation = await ConversationService.instance.getOrCreateConversation(
        sellerId: sellerId,
        sellerName: post.username,
        sellerAvatar: post.userAvatar,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: conversation,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(removed > 0 ? 'Removed $removed repeated post(s)' : 'No repeated posts found')),
      );
    }
  }

  Widget _buildExpandablePostText(PostModel post, ColorScheme colorScheme) {
    final content = post.content.trim();
    const int previewChars = 170;

    if (content.length <= previewChars) {
      return Text(content);
    }

    final isExpanded = _expandedPostIds.contains(post.id);
    final preview = '${content.substring(0, previewChars)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isExpanded ? content : preview),
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
          SizedBox(height: 1.h),
          SizedBox(
            height: 15.h,
            width: double.infinity,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
      );
    }

    // Landscape (sleeping rectangle) vs Portrait/Square (tall/thin/square)
    if (_aspectRatio! > 1.1) {
      // Landscape: text on top, image below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.textContent,
          SizedBox(height: 1.h),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 25.h), // avoid filling screen
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ],
      );
    } else {
      // Portrait / Square: text on left, image on right
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: widget.textContent),
          SizedBox(width: 3.w),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                height: 20.h, // constrained size
              ),
            ),
          ),
        ],
      );
    }
  }
}
