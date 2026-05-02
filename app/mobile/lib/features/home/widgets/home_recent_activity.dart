import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/history_model.dart';
import '../../../widgets/history_item_card.dart';
import '../../../widgets/skeleton.dart';

class HomeRecentActivity extends StatelessWidget {
  final bool isLoading;
  final bool isLoggedIn;
  final HistoryItem? latestHistoryItem;
  final VoidCallback? onHistoryRequested;
  final VoidCallback? onLoginRequested;

  const HomeRecentActivity({
    super.key,
    required this.isLoading,
    required this.isLoggedIn,
    this.latestHistoryItem,
    this.onHistoryRequested,
    this.onLoginRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const HistoryItemSkeleton();
    }

    if (latestHistoryItem != null) {
      return HistoryItemCard(
        title: latestHistoryItem!.displayName,
        type: latestHistoryItem!.type,
        time: latestHistoryItem!.formattedTime,
        points: '+${latestHistoryItem!.pointsEarned} điểm',
        icon: latestHistoryItem!.icon,
        color: latestHistoryItem!.color,
        imageUrl: latestHistoryItem!.imageUrl,
        onTap: onHistoryRequested,
      );
    }

    // Empty state for both guests and logged-in users with no history
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.disabledColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.history, color: theme.disabledColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hoạt động nào',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? 'Bắt đầu quét rác để theo dõi quá trình bảo vệ môi trường của bạn.'
                : 'Đăng nhập để bắt đầu lưu lại lịch sử phân loại và tích lũy điểm thưởng!',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.disabledColor, fontSize: 13),
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onLoginRequested,
              child: const Text(
                'Đăng nhập ngay',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
