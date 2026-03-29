import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/profile_avatar.dart';
import '../../../widgets/fullscreen_image_viewer.dart';
import '../../chat/chat_page.dart';
import '../mock_data.dart' show getUserByUsername, kMessages, markConversationRead;

class PostCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final VoidCallback? onReport;

  const PostCardWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.onReport,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  bool isLiked = false;
  bool isSaved = false;
  bool isFollowing = false;
  bool showLearnMore = false;
  int likeCount = 0;
  bool showComments = false;
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    isLiked = widget.post['isLiked'] as bool? ?? false;
    isSaved = widget.post['isSaved'] as bool? ?? false;
    likeCount = widget.post['likes'] as int? ?? 0;

    // Load initial sample comments
    final commentCount = widget.post['comments'] as int? ?? 0;
    _comments.addAll(
      List.generate(
        commentCount.clamp(0, 3),
        (i) => {
          'id': 'comment_$i',
          'user': 'User ${i + 1}',
          'avatar': '',
          'text': 'This is a sample comment #${i + 1} 👍',
          'time': '${i + 1}h ago',
          'likes': (3 - i) * 2,
          'isLiked': false,
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });
    widget.onLike?.call();
  }

  void _handleSave() {
    HapticFeedback.lightImpact();
    setState(() {
      isSaved = !isSaved;
    });
    widget.onSave?.call();
  }

  void _handleFollow() {
    HapticFeedback.lightImpact();
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _comments.insert(0, {
        'id': 'comment_${DateTime.now().millisecondsSinceEpoch}',
        'user': 'You',
        'avatar': '',
        'text': text,
        'time': 'Just now',
        'likes': 0,
        'isLiked': false,
      });
      _commentController.clear();
    });
  }

  void _likeComment(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      final comment = _comments[index];
      final isLiked = comment['isLiked'] as bool;
      comment['isLiked'] = !isLiked;
      comment['likes'] = (comment['likes'] as int) + (isLiked ? -1 : 1);
    });
  }

  Widget _buildCommentItem(
      Map<String, dynamic> comment, int index, ThemeData theme) {
    final isCommentLiked = comment['isLiked'] as bool;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              comment['user'][0],
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['user'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        comment['text'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Padding(
                  padding: EdgeInsets.only(left: 3.w),
                  child: Row(
                    children: [
                      Text(
                        comment['time'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () => _likeComment(index),
                        child: Text(
                          'Like',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isCommentLiked
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isCommentLiked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Reply',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      if ((comment['likes'] as int) > 0) ...[
                        SizedBox(width: 4.w),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 0.5.w),
                            Text(
                              '${comment['likes']}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Cache commonly used TextStyle to avoid multiple GoogleFonts calls
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = theme.textTheme.bodyMedium;
    final username = widget.post['username'] as String? ?? 'Unknown User';
    final timestamp = widget.post['timestamp'] as String? ?? '1h ago';
    final description = widget.post['content'] as String? ??
        widget.post['description'] as String? ??
        '';
    final imageUrl = widget.post['imageUrl'] as String?;
    final isSponsored = widget.post['isSponsored'] as bool? ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.post['userAvatar'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(
                            imageUrl: widget.post['userAvatar'],
                            heroTag: 'avatar_$username',
                          ),
                        ),
                      );
                    }
                  },
                  child: ProfileAvatar(
                    imageUrl: widget.post['userAvatar'],
                    size: 10.w,
                    isOnline: widget.post['isOnline'] as bool? ?? false,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                              Text(
                                username,
                                style: titleStyle,
                              ),
                          if (widget.post['isVerified'] as bool? ?? false) ...[
                            SizedBox(width: 1.w),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                          if (isSponsored) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Sponsored',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showQuickActions,
                  icon: Icon(
                    Icons.more_horiz,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Post Description
          if (description.isNotEmpty)
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 3.w).copyWith(bottom: 2.h),
                child: Text(
                showLearnMore || description.length <= 200
                    ? description
                    : '${description.substring(0, 200)}...',
                style: bodyStyle,
              ),
            ),

          // Post Image
          if (imageUrl != null && imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      imageUrl: imageUrl,
                      heroTag:
                          'post_${widget.post['id'] ?? widget.post.hashCode}',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'post_${widget.post['id'] ?? widget.post.hashCode}',
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: 100.w,
                  height: 50.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Post Actions
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _handleLike,
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: isLiked ? 'favorite' : 'favorite_border',
                            color: isLiked
                                ? Colors.red
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                            size: 24,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            likeCount.toString(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showComments = !showComments;
                        });
                        widget.onComment?.call();
                      },
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'chat_bubble_outline',
                            color: showComments
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                            size: 24,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _comments.length.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: showComments
                                  ? theme.colorScheme.primary
                                  : null,
                              fontWeight: showComments ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: widget.onShare,
                      child: CustomIconWidget(
                        iconName: 'share',
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    // Message the post owner privately
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        
                        final username = widget.post['username'] as String? ?? '';
                        if (username.isEmpty) return;
                        
                        // Get user from unified mock data
                        final user = getUserByUsername(username);
                        if (user == null) {
                          // Show error if user not found
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User not found'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        final userId = user['id'] as int;
                        
                        // Mark conversation as read
                        markConversationRead(userId);
                        
                        // Create conversation object
                        final conversation = {
                          'id': userId,
                          'userId': userId,
                          'name': user['name'],
                          'avatar': user['avatar'],
                          'lastMessage': kMessages[userId]?.last['text'] ?? '',
                          'timestamp': kMessages[userId]?.last['timestamp'] ?? 'Now',
                          'isOnline': user['isOnline'],
                          'unreadCount': 0,
                          'isVerified': user['isVerified'] ?? false,
                        };
                        
                        // Navigate to ChatPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              conversation: conversation,
                              initialMessages: kMessages[userId],
                            ),
                          ),
                        );
                      },
                      child: CustomIconWidget(
                        iconName: '💬',
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _handleSave,
                      child: CustomIconWidget(
                        iconName: isSaved ? 'bookmark' : 'bookmark_border',
                        color: isSaved
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                  ],
                ),

                // Learn More Button with Degree Icon
                if (description.length > 200) ...[
                  SizedBox(height: 1.h),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showLearnMore = !showLearnMore;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'school',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          showLearnMore ? 'Show Less' : 'Learn More',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Icon(
                          showLearnMore ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],

                // Facebook-style Inline Comments Section
                if (showComments) ...[
                  SizedBox(height: 2.h),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Comments List
                        if (_comments.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            itemCount:
                                _comments.length > 5 ? 5 : _comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentItem(
                                  _comments[index], index, theme);
                            },
                          ),

                        // View more comments
                        if (_comments.length > 5)
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View ${_comments.length - 5} more comments',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),

                        // Comment Input
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.2.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 0.8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Write a comment...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: GoogleFonts.inter(fontSize: 14),
                                    maxLines: null,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _addComment(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              GestureDetector(
                                onTap: _addComment,
                                child: Container(
                                  padding: EdgeInsets.all(1.5.w),
                                  decoration: BoxDecoration(
                                    color: _commentController.text.isEmpty
                                        ? Colors.transparent
                                        : colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    color: _commentController.text.isEmpty
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.3)
                                        : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // CTA Buttons for Sponsored Posts
                if (isSponsored && widget.post['ctaButtons'] != null) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      for (final cta
                          in (widget.post['ctaButtons'] as List)) ...[
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              // Handle CTA action
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: cta == 'Shop Now'
                                ? Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 8),
                                    child: CustomIconWidget(
                                      iconName: 'shopping_cart',
                                      color: theme.colorScheme.onPrimary,
                                      size: 18,
                                    ),
                                  )
                                : Text(
                                    cta as String,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        if (cta != (widget.post['ctaButtons'] as List).last)
                          SizedBox(width: 2.w),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                },
              ),
              ListTile(
                leading:
                    Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                title: Text(isFollowing ? 'Unfollow' : 'Follow'),
                onTap: () {
                  Navigator.pop(context);
                  _handleFollow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title:
                    const Text('Report', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReport?.call();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
