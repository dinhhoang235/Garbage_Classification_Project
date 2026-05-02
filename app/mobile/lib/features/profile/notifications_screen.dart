import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _notificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    final success = await _notificationService.markAsRead(id);
    if (success && mounted) {
      _fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              onPressed: () async {
                await _notificationService.markAllAsRead();
                _fetchNotifications();
              },
              tooltip: 'Đọc tất cả',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: 6,
                separatorBuilder: (context, index) => Divider(height: 32, color: theme.dividerColor),
                itemBuilder: (context, index) => const NotificationItemSkeleton(),
              )
            : _notifications.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(height: 32, color: theme.dividerColor),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index], theme);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 64, color: theme.disabledColor.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo nào',
            style: TextStyle(color: theme.disabledColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, ThemeData theme) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? theme.disabledColor.withAlpha(26)
                  : AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.bell, 
              color: notification.isRead ? theme.disabledColor : AppColors.primary, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold, 
                          fontSize: 14,
                          color: notification.isRead ? theme.textTheme.bodyMedium?.color?.withAlpha(120) : theme.textTheme.titleMedium?.color,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.content,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(notification.isRead ? 100 : 255), 
                    fontSize: 13,
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.timeAgo,
                  style: TextStyle(color: theme.disabledColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
