import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';

class HomeHeader extends StatelessWidget {
  final User? currentUser;
  final bool isLoggedIn;
  final int unreadCount;
  final Future<void> Function()? onNotificationRequested;
  final VoidCallback? onNotificationClosed;

  const HomeHeader({
    super.key,
    required this.isLoggedIn,
    required this.unreadCount,
    this.currentUser,
    this.onNotificationRequested,
    this.onNotificationClosed,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Chào buổi sáng,';
    if (hour >= 12 && hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 18) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                ),
                const SizedBox(width: 4),
                Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 14)),
              ],
            ),
            Row(
              children: [
                Text(
                  isLoggedIn ? (currentUser?.name ?? '') : 'Khách',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(isLoggedIn ? '🌿' : '👋', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            if (onNotificationRequested != null) {
              await onNotificationRequested!();
              onNotificationClosed?.call();
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(LucideIcons.bell, size: 20, color: theme.iconTheme.color),
              ),
              if (isLoggedIn && unreadCount > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
