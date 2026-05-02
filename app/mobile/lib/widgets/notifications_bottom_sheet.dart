import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/services/notification_service.dart';
import '../models/notification_model.dart';
import 'skeleton.dart';

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  @override
  State<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
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

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success && mounted) {
      _fetchNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông báo',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_notifications.any((n) => !n.isRead))
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(LucideIcons.checkCheck, size: 16),
                        label: const Text('Đọc tất cả', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, color: theme.iconTheme.color),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? _buildSkeletonList()
              : _notifications.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(height: 32, color: theme.dividerColor),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index], theme);
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 32),
      itemBuilder: (context, index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: 150, height: 16),
                const SizedBox(height: 8),
                const Skeleton(width: double.infinity, height: 12),
                const SizedBox(height: 4),
                const Skeleton(width: 200, height: 12),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Skeleton(width: 80, height: 10),
                    Skeleton(width: 16, height: 16, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              size: 18
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.timeAgo,
                      style: TextStyle(color: theme.textTheme.bodySmall?.color?.withAlpha(128), fontSize: 12),
                    ),
                    Icon(
                      notification.isRead ? LucideIcons.checkCircle2 : LucideIcons.circle,
                      size: 16,
                      color: notification.isRead ? AppColors.primary : theme.disabledColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
