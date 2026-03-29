import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../model/notification_model.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import 'notification_list_widget.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedFilterIndex = 0;
  NotificationSummary? _summary;
  final List<String> _filters = ['All', 'Unread', 'Likes', 'Comments', 'Follows', 'Messages'];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await NotificationService.getNotificationSummary();
    setState(() => _summary = summary);
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    await _loadSummary();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.deleteAllNotifications();
      await _loadSummary();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          if (_summary != null && _summary!.unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all as read',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _deleteAll,
                child: const Text('Delete all'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification summary cards
          if (_summary != null) _buildSummarySection(colorScheme),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: List.generate(_filters.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(_filters[index]),
                    selected: _selectedFilterIndex == index,
                    onSelected: (selected) {
                      setState(() => _selectedFilterIndex = index);
                    },
                  ),
                );
              }),
            ),
          ),

          // Notification list
          Expanded(
            child: NotificationListWidget(
              showOnlyUnread: _selectedFilterIndex == 1,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildSummarySection(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Unread',
                  _summary!.unreadCount.toString(),
                  Icons.mail_outline,
                  Colors.blue,
                  colorScheme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryCard(
                  'Total',
                  _summary!.totalCount.toString(),
                  Icons.notifications_active,
                  Colors.purple,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String count,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
