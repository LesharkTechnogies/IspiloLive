import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/services/message_service.dart';
import '../../model/message_model.dart';
import '../chat/chat_page.dart';
import '../../routes/app_routes.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<ConversationModel> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await MessageService.getConversations(size: 50);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load conversations')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  List<ConversationModel> _filterConversations(List<ConversationModel> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final query = _searchQuery.toLowerCase();
    return source
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.lastMessage.toLowerCase().contains(query))
        .toList();
  }

  String _formatTimestamp(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd MMM').format(value);
  }

  String? _resolveConversationUserId(ConversationModel conversation) {
    if (conversation.participants.isEmpty) return null;

    for (final participant in conversation.participants) {
      if (participant.id.trim().isNotEmpty) {
        return participant.id;
      }
    }

    return null;
  }

  void _openUserProfile(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not available for this chat yet')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'userId': userId},
    );
  }

  void _handleConversationTap(ConversationModel conversation) {
    HapticFeedback.lightImpact();

    final userId = _resolveConversationUserId(conversation);
    final participant =
        conversation.participants.isNotEmpty ? conversation.participants.first : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: {
            'id': conversation.id,
            'userId': userId,
            'name': conversation.name,
            'avatar': participant?.avatar,
            'isOnline': participant?.isOnline ?? false,
            'isVerified': false,
            'unreadCount': conversation.unreadCount,
            'isGroup': conversation.isGroup,
            'encryptionKey': conversation.encryptionKey,
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final chats = _filterConversations(
      _conversations.where((c) => !c.isGroup).toList(),
    );
    final groups = _filterConversations(
      _conversations.where((c) => c.isGroup).toList(),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 1,
        title: Text(
          'Messages',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: const TabBar(
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Chats'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF075E54).withValues(alpha: 0.15),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or message...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: const Color(0xFF075E54),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.2.h,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildConversationList(chats),
                      _buildConversationList(groups, isGroup: true),
                    ],
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildConversationList(
    List<ConversationModel> source, {
    bool isGroup = false,
  }) {
    if (source.isEmpty) {
      return Center(
        child: Text(
          isGroup ? 'No group conversations' : 'No conversations yet',
          style: GoogleFonts.inter(fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: source.length,
        itemBuilder: (context, index) {
          final conversation = source[index];
          final participant =
              conversation.participants.isNotEmpty ? conversation.participants.first : null;
          final userId = _resolveConversationUserId(conversation);
          final hasUnread = conversation.unreadCount > 0;

          return ListTile(
            onTap: () => _handleConversationTap(conversation),
            leading: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isGroup ? null : () => _openUserProfile(userId),
              child: CircleAvatar(
                radius: 23,
                backgroundImage: participant?.avatar != null
                    ? NetworkImage(participant!.avatar!)
                    : null,
                child: participant?.avatar == null
                    ? Icon(isGroup ? Icons.groups : Icons.person)
                    : null,
              ),
            ),
            title: Text(
              conversation.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(conversation.lastMessageTime),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: hasUnread ? const Color(0xFF075E54) : Colors.grey,
                  ),
                ),
                if (hasUnread) ...[
                  SizedBox(height: 0.4.h),
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: const Color(0xFF25D366),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
