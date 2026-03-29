import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_widget.dart';
import '../home_feed/widgets/story_item_widget.dart';
import '../chat/chat_page.dart';
import '../home_feed/mock_data.dart' show kConversations, kMessages, markConversationRead;

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Use shared conversations from mock data
  List<Map<String, dynamic>> get _conversations => kConversations;

  // Filtered conversations based on search query
  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }

    final query = _searchQuery.toLowerCase();
    return _conversations.where((conversation) {
      // Search by name
      final name = (conversation['name'] as String? ?? '').toLowerCase();
      if (name.contains(query)) return true;

      // Search by username (if available)
      final username = (conversation['username'] as String? ?? '').toLowerCase();
      if (username.contains(query)) return true;

      // Search by last message content
      final lastMessage = (conversation['lastMessage'] as String? ?? '').toLowerCase();
      if (lastMessage.contains(query)) return true;

      // Search through all messages in the conversation
      final userId = conversation['userId'] as int?;
      if (userId != null && kMessages.containsKey(userId)) {
        final messages = kMessages[userId] ?? [];
        return messages.any((msg) {
          final text = (msg['text'] as String? ?? '').toLowerCase();
          return text.contains(query);
        });
      }

      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleConversationTap(Map<String, dynamic> conversation) {
    HapticFeedback.lightImpact();
    // Update mock data to mark the conversation as read so the UI updates.
    try {
      final uid = conversation['userId'] as int;
      markConversationRead(uid);
    } catch (_) {}

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: conversation,
          initialMessages: kMessages[conversation['userId'] as int],
        ),
      ),
    ).then((_) {
      // When returning, refresh state so badges reflect changes.
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get screen width to detect desktop vs mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1877F2),
        elevation: 1,
        title: Text(
          'Messages',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick Search Bar
          Container(
            margin: EdgeInsets.fromLTRB(
              isDesktop ? 16 : 4.w,
              isDesktop ? 12 : 1.h,
              isDesktop ? 16 : 4.w,
              isDesktop ? 12 : 1.h,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or message...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.grey[600],
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey[600],
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
                  horizontal: isDesktop ? 16 : 4.w,
                  vertical: isDesktop ? 12 : 1.2.h,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),

          // Active Status Bar - hide when searching
          if (_searchQuery.isEmpty)
            Container(
              height: isDesktop ? 120 : 12.h.clamp(80, 120),
              margin: EdgeInsets.symmetric(
                vertical: isDesktop ? 12 : 1.h,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 4.w,
                ),
                itemCount: _conversations.where((c) => c['isOnline']).length,
                itemBuilder: (context, index) {
                  final onlineUsers =
                      _conversations.where((c) => c['isOnline']).toList();
                  final user = onlineUsers[index];

                  final bool hasUnread = (user['unreadCount'] as int? ?? 0) > 0;

                  return StoryItemWidget(
                    story: {
                      'username': (user['name'] as String).split(' ')[0],
                      'avatar': user['avatar'],
                      'isViewed': !hasUnread,
                      'comments': hasUnread ? (user['unreadCount'] as int) : 0,
                      'isOnline': user['isOnline'],
                    },
                    diameter: isDesktop ? 64 : 10.w,
                    onTap: () => _handleConversationTap(user),
                  );
                },
              ),
            ),

          if (_searchQuery.isEmpty)
            Divider(
              height: isDesktop ? 1 : 0.5.h,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),

          // Search results count
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 4.w,
                vertical: isDesktop ? 12 : 1.h,
              ),
              child: Text(
                '${_filteredConversations.length} result${_filteredConversations.length != 1 ? 's' : ''} found',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Conversations List
          Expanded(
            child: _filteredConversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No results found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          SizedBox(height: 1.h),
                          Text(
                            'Try searching for a different name or message',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _filteredConversations[index];
                      final hasUnread = conversation['unreadCount'] > 0;

                      // Responsive sizing
                      final avatarSize = (isDesktop ? 56.0 : 14.w.clamp(50.0, 60.0)).toDouble();
                      final onlineDotSize = (isDesktop ? 14.0 : 4.w.clamp(12.0, 16.0)).toDouble();

                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 8 : 2.w,
                          vertical: isDesktop ? 4 : 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _handleConversationTap(conversation),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 16 : 4.w,
                            vertical: isDesktop ? 12 : 1.2.h,
                          ),
                          leading: Stack(
                            children: [
                              ClipOval(
                                child: CustomImageWidget(
                                  imageUrl: conversation['avatar'],
                                  width: avatarSize,
                                  height: avatarSize,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (conversation['isOnline'])
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: onlineDotSize,
                                    height: onlineDotSize,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF00D84A), // WhatsApp green
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['name'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation['isVerified']) ...[
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF1877F2),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 0.5.h),
                      child: Text(
                        conversation['lastMessage'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: hasUnread ? Colors.black54 : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          conversation['timestamp'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: hasUnread
                                ? const Color(0xFF1877F2)
                                : Colors.grey[500],
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (hasUnread) ...[
                          SizedBox(height: isDesktop ? 8 : 0.8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 8 : 2.w,
                              vertical: isDesktop ? 4 : 0.4.h,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1877F2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation['unreadCount'].toString(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
