import 'package:flutter/material.dart';
import 'dart:async';
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
  final Set<String> _expandedReplyThreads = <String>{};
  final Map<String, bool> _replyLikedState = <String, bool>{};
  final Map<String, int> _replyLikeCounts = <String, int>{};
  String? _activeReplyFor;
  bool _loading = true;
  bool _resyncInProgress = false;
  int _newCommentsCount = 0;
  Timer? _commentsResyncTimer;

  @override
  void initState() {
    super.initState();
    post = PostModel.fromJson(widget.postJson);
    _loadComments();
    _startCommentsBackgroundResync();
  }

  void _startCommentsBackgroundResync() {
    _commentsResyncTimer?.cancel();
    _commentsResyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _resyncCommentsInBackground(),
    );
  }

  Future<void> _resyncCommentsInBackground() async {
    if (!mounted || _loading || _resyncInProgress) return;
    _resyncInProgress = true;

    try {
      final fetched =
          await PostRepository.getComments(postId: post.id, page: 0, size: 50);
      if (!mounted) return;
      setState(() {
        _buildThreadData(fetched);
      });
    } catch (e) {
      debugPrint('Comments background resync failed: $e');
    } finally {
      _resyncInProgress = false;
    }
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
    final byId = <String, CommentModel>{};
    final childrenByParent = <String, List<String>>{};

    void collect(CommentModel comment) {
      if (comment.id.isEmpty) return;
      byId[comment.id] = comment;

      final parentId = comment.parentCommentId;
      if (parentId != null && parentId.isNotEmpty) {
        childrenByParent.putIfAbsent(parentId, () => <String>[]).add(comment.id);
      }

      for (final reply in comment.replies) {
        collect(reply);
        childrenByParent.putIfAbsent(comment.id, () => <String>[]).add(reply.id);
      }
    }

    for (final comment in fetched) {
      collect(comment);
    }

    CommentModel buildNode(String id, Set<String> path) {
      final base = byId[id]!;
      if (path.contains(id)) {
        return base;
      }

      final nextPath = <String>{...path, id};
      final childIds = childrenByParent[id] ?? const <String>[];
      final dedup = <String>{};
      final children = <CommentModel>[];
      for (final childId in childIds) {
        if (!dedup.add(childId)) continue;
        final child = byId[childId];
        if (child == null) continue;
        children.add(buildNode(childId, nextPath));
      }

      children.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return CommentModel(
        id: base.id,
        postId: base.postId,
        parentCommentId: base.parentCommentId,
        userId: base.userId,
        username: base.username,
        userAvatar: base.userAvatar,
        content: base.content,
        likesCount: base.likesCount,
        createdAt: base.createdAt,
        replies: children,
      );
    }

    final rootComments = <CommentModel>[];
    for (final comment in byId.values) {
      final parentId = comment.parentCommentId;
      final isRoot = parentId == null || parentId.isEmpty || !byId.containsKey(parentId);
      if (!isRoot) continue;
      rootComments.add(buildNode(comment.id, <String>{}));
    }

    rootComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _comments = rootComments;

    void _populateLikesData(List<CommentModel> list) {
      for (final c in list) {
        _replyLikedState.putIfAbsent(c.id, () => false);
        _replyLikeCounts.putIfAbsent(c.id, () => c.likesCount);
        if (c.replies.isNotEmpty) {
          _populateLikesData(c.replies);
        }
      }
    }

    _populateLikesData(_comments);
  }

  List<CommentModel> _mergedRepliesFor(CommentModel comment) {
    final merged = comment.replies.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  CommentModel _copyWithReplies(CommentModel base, List<CommentModel> replies) {
    return CommentModel(
      id: base.id,
      postId: base.postId,
      parentCommentId: base.parentCommentId,
      userId: base.userId,
      username: base.username,
      userAvatar: base.userAvatar,
      content: base.content,
      likesCount: base.likesCount,
      createdAt: base.createdAt,
      replies: replies,
    );
  }

  bool _insertReplyIntoTree(String parentId, CommentModel reply) {
    var inserted = false;

    List<CommentModel> walk(List<CommentModel> nodes) {
      return nodes.map((node) {
        if (node.id == parentId) {
          inserted = true;
          final mergedById = <String, CommentModel>{
            for (final r in node.replies) r.id: r,
            reply.id: reply,
          };
          final sortedReplies = mergedById.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return _copyWithReplies(node, sortedReplies);
        }

        if (node.replies.isEmpty) return node;
        final updatedChildren = walk(node.replies);
        return _copyWithReplies(node, updatedChildren);
      }).toList();
    }

    _comments = walk(_comments);
    return inserted;
  }

  Widget _buildCommentNode(CommentModel c, int depth) {
    final replies = _mergedRepliesFor(c);
    final isReplying = _activeReplyFor == c.id;
    final isRepliesExpanded = _expandedReplyThreads.contains(c.id);
    final indent = depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 1.4.h),
      child: Container(
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
                backgroundImage:
                    c.userAvatar.isNotEmpty ? NetworkImage(c.userAvatar) : null,
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
              trailing: GestureDetector(
                onTap: () => _toggleReplyLike(c),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (_replyLikedState[c.id] ?? false)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: (_replyLikedState[c.id] ?? false) ? Colors.lightGreen : null,
                    ),
                    SizedBox(width: 1.w),
                    Text('${_replyLikeCounts[c.id] ?? c.likesCount}'),
                  ],
                ),
              ),
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
                    label: Text(
                      isRepliesExpanded ? 'Hide replies' : 'View replies',
                    ),
                  ),
                if (replies.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(left: 1.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.2.w, vertical: 0.35.h),
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
            if (replies.isNotEmpty && isRepliesExpanded)
              Column(
                children: replies
                    .map((reply) => _buildCommentNode(reply, depth + 1))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  CommentModel? _findCommentById(String commentId, List<CommentModel> nodes) {
    for (final node in nodes) {
      if (node.id == commentId) return node;
      if (node.replies.isEmpty) continue;
      final nested = _findCommentById(commentId, node.replies);
      if (nested != null) return nested;
    }
    return null;
  }

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final replyTargetId = _activeReplyFor;
    try {
      final newComment = await PostRepository.addComment(
        postId: post.id,
        content: text,
        parentCommentId: replyTargetId,
      );
      setState(() {
        if (newComment.parentCommentId != null && newComment.parentCommentId!.isNotEmpty) {
          _insertReplyIntoTree(newComment.parentCommentId!, newComment);
          _expandedReplyThreads.add(newComment.parentCommentId!);
        } else {
          _comments.insert(0, newComment);
        }
        _newCommentsCount++;
        _controller.clear();
        _activeReplyFor = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to comment: $e')));
    }
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
    _commentsResyncTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _newCommentsCount);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final replyTarget = _activeReplyFor == null
        ? null
        : _findCommentById(_activeReplyFor!, _comments);

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
                      itemBuilder: (context, index) =>
                          _buildCommentNode(_comments[index], 0),
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyTarget != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 1.h),
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to @${replyTarget.username}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _activeReplyFor = null;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: replyTarget == null
                                  ? 'Write a comment...'
                                  : 'Reply to ${replyTarget.username}...',
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        ElevatedButton(onPressed: _addComment, child: const Text('Post')),
                      ],
                    ),
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
