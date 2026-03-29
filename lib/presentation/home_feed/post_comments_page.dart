import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../model/social_model.dart';
import '../../model/repository/social_repository.dart';

class PostCommentsPage extends StatefulWidget {
  final Map<String, dynamic> postJson;
  const PostCommentsPage({super.key, required this.postJson});

  @override
  State<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  late final PostModel post;
  final TextEditingController _controller = TextEditingController();
  List<CommentModel> _comments = [];
  Map<String, List<CommentModel>> _repliesByComment = <String, List<CommentModel>>{};
  final Set<String> _expandedReplyThreads = <String>{};
  final Map<String, bool> _replyLikedState = <String, bool>{};
  final Map<String, int> _replyLikeCounts = <String, int>{};
  final Map<String, TextEditingController> _replyControllers = <String, TextEditingController>{};
  String? _activeReplyFor;
  bool _loading = true;
  int _newCommentsCount = 0;

  @override
  void initState() {
    super.initState();
    post = PostModel.fromJson(widget.postJson);
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final fetched = await PostRepository.getComments(postId: post.id, page: 0, size: 50);
      _buildThreadData(fetched);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load comments: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _buildThreadData(List<CommentModel> fetched) {
    final Map<String, List<CommentModel>> replyMap = <String, List<CommentModel>>{};
    final List<CommentModel> topLevel = <CommentModel>[];

    for (final comment in fetched) {
      if (comment.parentCommentId != null && comment.parentCommentId!.isNotEmpty) {
        replyMap.putIfAbsent(comment.parentCommentId!, () => <CommentModel>[]).add(comment);
      } else {
        topLevel.add(comment);
        if (comment.replies.isNotEmpty) {
          replyMap.putIfAbsent(comment.id, () => <CommentModel>[]).addAll(comment.replies);
        }
      }
    }

    _comments = topLevel;
    _repliesByComment = replyMap;

    for (final replies in replyMap.values) {
      for (final reply in replies) {
        _replyLikedState.putIfAbsent(reply.id, () => false);
        _replyLikeCounts.putIfAbsent(reply.id, () => reply.likesCount);
      }
    }
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      final newComment = await PostRepository.addComment(postId: post.id, content: text);
      setState(() {
        _comments.insert(0, newComment);
        _newCommentsCount++;
        _controller.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to comment: $e')));
    }
  }

  Future<void> _addReply(CommentModel parent) async {
    final controller = _replyControllers[parent.id];
    final text = controller?.text.trim() ?? '';
    if (text.isEmpty) return;

    try {
      final reply = await PostRepository.addReply(
        postId: post.id,
        commentId: parent.id,
        content: text,
      );

      setState(() {
        _repliesByComment.putIfAbsent(parent.id, () => <CommentModel>[]).insert(0, reply);
        _replyLikedState[reply.id] = false;
        _replyLikeCounts[reply.id] = reply.likesCount;
        _expandedReplyThreads.add(parent.id);
        controller?.clear();
        _activeReplyFor = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reply: $e')));
    }
  }

  TextEditingController _replyControllerFor(String commentId) {
    return _replyControllers.putIfAbsent(commentId, () => TextEditingController());
  }

  Future<void> _toggleReplyLike(CommentModel reply) async {
    final previousLiked = _replyLikedState[reply.id] ?? false;
    final previousCount = _replyLikeCounts[reply.id] ?? reply.likesCount;

    setState(() {
      _replyLikedState[reply.id] = !previousLiked;
      _replyLikeCounts[reply.id] = previousCount + (previousLiked ? -1 : 1);
    });

    try {
      final result = await PostRepository.toggleLikeComment(reply.id);
      if (!mounted) return;
      setState(() {
        _replyLikedState[reply.id] = result['isLiked'] as bool? ?? _replyLikedState[reply.id] ?? false;
        _replyLikeCounts[reply.id] = result['likesCount'] as int? ?? _replyLikeCounts[reply.id] ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _replyLikedState[reply.id] = previousLiked;
        _replyLikeCounts[reply.id] = previousCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to like reply: $e')));
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _newCommentsCount);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comments'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _newCommentsCount),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.all(3.w),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final c = _comments[index];
                        final replies = _repliesByComment[c.id] ?? const <CommentModel>[];
                        final isReplying = _activeReplyFor == c.id;
                        final isRepliesExpanded = _expandedReplyThreads.contains(c.id);

                        return Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          padding: EdgeInsets.all(2.5.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundImage: c.userAvatar.isNotEmpty ? NetworkImage(c.userAvatar) : null,
                                  child: c.userAvatar.isEmpty ? const Icon(Icons.person) : null,
                                ),
                                title: Text(c.username),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.content),
                                    SizedBox(height: 0.3.h),
                                    Text(
                                      _formatRelativeTime(c.createdAt),
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                                trailing: Text('${c.likesCount}'),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _activeReplyFor = isReplying ? null : c.id;
                                      });
                                    },
                                    icon: const Icon(Icons.reply, size: 16),
                                    label: Text(isReplying ? 'Cancel' : 'Reply'),
                                  ),
                                  if (replies.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          if (isRepliesExpanded) {
                                            _expandedReplyThreads.remove(c.id);
                                          } else {
                                            _expandedReplyThreads.add(c.id);
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        isRepliesExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 16,
                                      ),
                                      label: Text(isRepliesExpanded ? 'Hide replies' : 'View replies'),
                                    ),
                                  if (replies.isNotEmpty)
                                    Container(
                                      margin: EdgeInsets.only(left: 1.w),
                                      padding: EdgeInsets.symmetric(horizontal: 2.2.w, vertical: 0.35.h),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${replies.length}',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isReplying)
                                Padding(
                                  padding: EdgeInsets.only(top: 0.8.h, bottom: 0.8.h),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _replyControllerFor(c.id),
                                          decoration: InputDecoration(
                                            hintText: 'Reply to ${c.username}...',
                                            isDense: true,
                                            border: const OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      ElevatedButton(
                                        onPressed: () => _addReply(c),
                                        child: const Text('Send'),
                                      ),
                                    ],
                                  ),
                                ),
                              if (replies.isNotEmpty && isRepliesExpanded)
                                Column(
                                  children: replies
                                      .map(
                                        (reply) => Padding(
                                          padding: EdgeInsets.only(top: 0.8.h, left: 5.w),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundImage: reply.userAvatar.isNotEmpty
                                                    ? NetworkImage(reply.userAvatar)
                                                    : null,
                                                child: reply.userAvatar.isEmpty
                                                    ? const Icon(Icons.person, size: 12)
                                                    : null,
                                              ),
                                              SizedBox(width: 2.w),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.all(2.w),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10),
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHigh,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      RichText(
                                                        text: TextSpan(
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium,
                                                          children: [
                                                            TextSpan(
                                                              text: '${reply.username}  ',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            TextSpan(text: reply.content),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(height: 0.45.h),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            _formatRelativeTime(reply.createdAt),
                                                            style: Theme.of(context).textTheme.labelSmall,
                                                          ),
                                                          SizedBox(width: 3.w),
                                                          GestureDetector(
                                                            onTap: () => _toggleReplyLike(reply),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  (_replyLikedState[reply.id] ?? false)
                                                                      ? Icons.favorite
                                                                      : Icons.favorite_border,
                                                                  size: 15,
                                                                  color: (_replyLikedState[reply.id] ?? false)
                                                                      ? Colors.red
                                                                      : null,
                                                                ),
                                                                SizedBox(width: 1.w),
                                                                Text(
                                                                  '${_replyLikeCounts[reply.id] ?? reply.likesCount}',
                                                                  style: Theme.of(context).textTheme.labelSmall,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(hintText: 'Write a comment...'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(onPressed: _addComment, child: const Text('Post')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
