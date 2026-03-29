import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../model/notification_model.dart';
import '../../core/services/notification_service.dart';

class NotificationListWidget extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final bool showOnlyUnread;

  const NotificationListWidget({
    super.key,
    this.onNotificationTap,
    this.showOnlyUnread = false,
  });

  @override
  State<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends State<NotificationListWidget> {
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    if (widget.showOnlyUnread) {
      _notificationsFuture = NotificationService.getUnreadNotifications();
    } else {
      _notificationsFuture = NotificationService.getNotifications();
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      NotificationService.markAsRead(notification.id);
    }
    widget.onNotificationTap?.call();
    // Navigate based on actionUrl if provided
    if (notification.actionUrl != null) {
      // Navigator.pushNamed(context, notification.actionUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<NotificationModel>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading notifications: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 48, color: colorScheme.outline),
                SizedBox(height: 2.h),
                Text(
                  'No notifications',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationTile(notification, colorScheme);
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(
    NotificationModel notification,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: notification.isRead
                ? colorScheme.surface
                : colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: notification.isRead
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon/avatar
              if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    notification.imageUrl!,
                    width: 12.w,
                    height: 12.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildNotificationIcon(notification.type, colorScheme);
                    },
                  ),
                )
              else
                _buildNotificationIcon(notification.type, colorScheme),
              SizedBox(width: 3.w),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    // Body
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    // Timestamp
                    Text(
                      _getTimeAgo(notification.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Mark as read'),
                    onTap: () => NotificationService.markAsRead(notification.id),
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () => NotificationService.deleteNotification(notification.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, ColorScheme colorScheme) {
    IconData icon = Icons.notifications;
    Color backgroundColor = colorScheme.primary;

    switch (type) {
      case NotificationType.like:
        icon = Icons.favorite;
        backgroundColor = Colors.red;
        break;
      case NotificationType.comment:
        icon = Icons.comment;
        backgroundColor = Colors.blue;
        break;
      case NotificationType.follow:
        icon = Icons.person_add;
        backgroundColor = Colors.green;
        break;
      case NotificationType.message:
        icon = Icons.mail;
        backgroundColor = Colors.purple;
        break;
      case NotificationType.mention:
        icon = Icons.alternate_email;
        backgroundColor = Colors.orange;
        break;
      case NotificationType.purchase:
        icon = Icons.shopping_bag;
        backgroundColor = Colors.teal;
        break;
      case NotificationType.enrollment:
        icon = Icons.school;
        backgroundColor = Colors.indigo;
        break;
      case NotificationType.system:
        icon = Icons.info;
        backgroundColor = Colors.grey;
        break;
      case NotificationType.alert:
        icon = Icons.warning;
        backgroundColor = Colors.amber;
        break;
      default:
        icon = Icons.notifications;
        backgroundColor = colorScheme.primary;
    }

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: backgroundColor, size: 24),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }
}
