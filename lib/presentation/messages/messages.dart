import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/message_service.dart';
import '../../model/message_model.dart';
import '../../model/social_model.dart';
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
  bool _isSearchingUsers = false;
  String? _currentUserId;
  Timer? _searchDebounce;
  List<ConversationModel> _conversations = [];
  List<UserModel> _userSearchResults = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadConversations();
    _searchController.addListener(_handleSearchChanged);
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileRaw = prefs.getString('user_profile');
      if (profileRaw == null || profileRaw.isEmpty) return;

  final decoded = jsonDecode(profileRaw);
  if (decoded is! Map<String, dynamic>) return;
  final id = decoded['id']?.toString().trim();
      if (id == null || id.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _currentUserId = id;
      });
    } catch (_) {
      // Best effort only.
    }
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await MessageService.getConversations(size: 50);
      conversations.sort(
        (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
      );
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
    _searchDebounce?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim();

    if (_searchQuery != query) {
      setState(() {
        _searchQuery = query;
      });
    }

    _searchDebounce?.cancel();
    if (query.isEmpty) {
      if (_userSearchResults.isNotEmpty || _isSearchingUsers) {
        setState(() {
          _isSearchingUsers = false;
          _userSearchResults = [];
        });
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() {
        _isSearchingUsers = true;
      });

      final startedWith = query;
      final results = await MessageService.searchUsersByName(startedWith, size: 20);
      if (!mounted) return;
      if (_searchController.text.trim() != startedWith) return;

      setState(() {
        _userSearchResults = results;
        _isSearchingUsers = false;
      });
    });
  }

  List<ConversationModel> _filterConversations(List<ConversationModel> source) {
    if (_searchQuery.trim().isEmpty) return source;
    final query = _searchQuery.trim();
    return source
        .where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.lastMessage.toLowerCase().contains(query.toLowerCase()) ||
            c.participants.any(
              (participant) => MessageService.matchesUserSearch(
                UserModel(
                  id: participant.id,
                  username: participant.name,
                  name: participant.name,
                  avatar: participant.avatar ?? '',
                  isVerified: false,
                  isOnline: participant.isOnline,
                  isPremium: false,
                  avatarPublic: true,
                  lastSeenAt: participant.lastSeenAt,
                ),
                query,
              ),
            ))
        .toList();
  }

  String _formatTimestamp(DateTime value) {
    final now = DateTime.now();
    var diff = now.difference(value);
    if (diff.isNegative) {
      diff = Duration.zero;
    }
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd MMM').format(value);
  }

  String _formatPresenceStatus(bool isOnline, DateTime? lastSeenAt) {
    if (isOnline) return 'Online';
    if (lastSeenAt == null) return 'Offline';
    return 'Last seen ${_formatTimestamp(lastSeenAt)}';
  }

  String? _resolveConversationUserId(ConversationModel conversation) {
    final participant = _resolveOtherParticipant(conversation);
    return participant?.id.trim().isNotEmpty == true ? participant!.id : null;
  }

  ConversationParticipant? _resolveOtherParticipant(ConversationModel conversation) {
    if (conversation.participants.isEmpty) return null;

    final currentId = _currentUserId?.trim();
    if (currentId != null && currentId.isNotEmpty) {
      for (final participant in conversation.participants) {
        final participantId = participant.id.trim();
        if (participantId.isNotEmpty && participantId != currentId) {
          return participant;
        }
      }
    }

    for (final participant in conversation.participants) {
      if (participant.id.trim().isNotEmpty) {
        return participant;
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
  final participant = _resolveOtherParticipant(conversation);
  final displayName = isNullOrEmpty(conversation.name)
    ? (participant?.name ?? 'Chat')
    : conversation.name;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: {
            'id': conversation.id,
            'userId': userId,
            'name': displayName,
            'avatar': participant?.avatar,
            'isOnline': participant?.isOnline ?? false,
            'lastSeenAt': participant?.lastSeenAt?.toUtc().toIso8601String(),
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

  Future<void> _handleUserSearchResultTap(UserModel user) async {
    HapticFeedback.lightImpact();

    ConversationModel? existing;
    for (final conversation in _conversations) {
      final hasUser = conversation.participants.any((p) => p.id == user.id);
      if (hasUser) {
        existing = conversation;
        break;
      }
    }

    if (existing != null) {
      _handleConversationTap(existing);
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: {
            'id': 'conv_${user.id}',
            'userId': user.id,
            'name': user.name,
            'avatar': user.avatar,
            'isOnline': user.isOnline,
            'lastSeenAt': user.lastSeenAt?.toUtc().toIso8601String(),
            'isVerified': user.isVerified,
            'isGroup': false,
            'unreadCount': 0,
            'encryptionKey': null,
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
    final showUserSearch = _searchQuery.trim().isNotEmpty;

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
                ? _buildMessagesSkeleton()
                : showUserSearch
                    ? _buildSearchResults(chats, groups)
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

  Widget _buildSearchResults(
    List<ConversationModel> chats,
    List<ConversationModel> groups,
  ) {
    final conversationUserIds = <String>{
      for (final c in _conversations)
        for (final p in c.participants)
          if (p.id.trim().isNotEmpty) p.id,
    };

    final users = _userSearchResults
        .where((user) => user.id.trim().isNotEmpty)
        .toList();

    return ListView(
      children: [
        if (chats.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.8.h),
            child: Text(
              'Chats',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          ...chats.map((c) => _buildConversationTile(c)),
        ],
        if (groups.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.8.h),
            child: Text(
              'Groups',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          ...groups.map((c) => _buildConversationTile(c, isGroup: true)),
        ],
        if (_isSearchingUsers)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.4.h),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 2.5.w),
                Text(
                  'Searching users...',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ),
          ),
        if (users.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.8.h),
            child: Text(
              'Users',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          ...users.map(
            (user) => ListTile(
              onTap: () => _handleUserSearchResultTap(user),
              leading: _buildPresenceAvatar(
                imageUrl: user.avatar,
                isOnline: user.isOnline,
                fallbackIcon: Icons.person,
              ),
              title: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                conversationUserIds.contains(user.id)
                    ? 'Open existing conversation • ${_formatPresenceStatus(user.isOnline, user.lastSeenAt)}'
                    : 'Start new conversation • ${_formatPresenceStatus(user.isOnline, user.lastSeenAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chat_bubble_outline),
            ),
          ),
        ],
        if (!_isSearchingUsers && chats.isEmpty && groups.isEmpty && users.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Center(
              child: Text(
                'No users or conversations found',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationTile(
    ConversationModel conversation, {
    bool isGroup = false,
  }) {
    final participant = _resolveOtherParticipant(conversation);
    final userId = _resolveConversationUserId(conversation);
    final hasUnread = conversation.unreadCount > 0;
    final displayName = isGroup
        ? conversation.name
        : (isNullOrEmpty(conversation.name)
            ? (participant?.name ?? 'Chat')
            : conversation.name);

    return ListTile(
      onTap: () => _handleConversationTap(conversation),
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isGroup ? null : () => _openUserProfile(userId),
        child: _buildPresenceAvatar(
          imageUrl: participant?.avatar,
          isOnline: isGroup ? false : (participant?.isOnline ?? false),
          fallbackIcon: isGroup ? Icons.groups : Icons.person,
        ),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isGroup
            ? conversation.lastMessage
            : '${conversation.lastMessage} • ${_formatPresenceStatus(
                participant?.isOnline ?? false,
                participant?.lastSeenAt,
              )}',
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
  }

  bool isNullOrEmpty(String? value) => value == null || value.trim().isEmpty;

  Widget _buildPresenceAvatar({
    required String? imageUrl,
    required bool isOnline,
    required IconData fallbackIcon,
  }) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
          child: hasImage ? null : Icon(fallbackIcon),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF25D366) : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesSkeleton() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            radius: 23,
            backgroundColor: Colors.grey.withValues(alpha: 0.25),
          ),
          title: Container(
            height: 12,
            margin: const EdgeInsets.only(right: 70),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          subtitle: Container(
            height: 10,
            margin: const EdgeInsets.only(top: 8, right: 120),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          trailing: Container(
            width: 34,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
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
          return _buildConversationTile(conversation, isGroup: isGroup);
        },
      ),
    );
  }
}
