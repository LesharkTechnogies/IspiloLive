import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../model/social_model.dart';
import '../../model/repository/social_repository.dart';
import '../home_feed/widgets/post_card_widget.dart';
import '../../core/services/cloudinary_service.dart';

class GroupProfilePage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupProfilePage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends State<GroupProfilePage> {
  final List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await PostRepository.getPostsByGroup(
        groupId: widget.groupId,
        page: 0,
        size: _pageSize,
      );
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _page = 1;
        _hasMore = posts.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load group posts: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final posts = await PostRepository.getPostsByGroup(
        groupId: widget.groupId,
        page: _page,
        size: _pageSize,
      );
      setState(() {
        _posts.addAll(posts);
        _page++;
        if (posts.length < _pageSize) {
          _hasMore = false;
        }
      });
    } catch (e) {
      debugPrint('Failed to load more posts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreatePostDialog() {
    final TextEditingController contentController = TextEditingController();
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 4.w,
                right: 4.w,
                top: 2.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Post in ${widget.groupName}',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  SwitchListTile(
                    title: const Text('Post Anonymously'),
                    value: isAnonymous,
                    onChanged: (val) => setModalState(() => isAnonymous = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final content = contentController.text.trim();
                        if (content.isEmpty) return;

                        Navigator.pop(context); // Close modal
                        
                        setState(() => _isLoading = true);
                        try {
                          await PostRepository.createGroupPost(
                            groupId: widget.groupId,
                            content: content,
                            isAnonymous: isAnonymous,
                          );
                          _loadPosts(); // Refresh list
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to post: $e')),
                          );
                          setState(() => _isLoading = false);
                        }
                      },
                      child: Text(
                        'Post',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            );
          },
        );
      },
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
          widget.groupName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _isLoading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: 80.h,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group, size: 64, color: colorScheme.onSurfaceVariant),
                          SizedBox(height: 2.h),
                          Text(
                            'No posts in this group yet.',
                            style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return PostCardWidget(
                        post: _posts[index].toJson(),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
      ),
    );
  }
}