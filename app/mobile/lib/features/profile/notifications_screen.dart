import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (context, index) => Divider(height: 32, color: theme.dividerColor),
        itemBuilder: (context, index) {
          return _buildNotificationItem(index, theme);
        },
      ),
    );
  }

  Widget _buildNotificationItem(int index, ThemeData theme) {
    final titles = [
      'Chúc mừng! Bạn đã đạt Level 7',
      'Lời nhắc: Đừng quên phân loại rác hôm nay',
      'Cập nhật mới: Thêm tính năng bản đồ rác',
      'Bạn nhận được 15 điểm từ việc tái chế',
      'Chào mừng bạn đến với Eco Sort'
    ];
    final times = ['2 giờ trước', '5 giờ trước', 'Hôm qua', '2 ngày trước', '1 tuần trước'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.bell, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titles[index],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Đây là nội dung chi tiết của thông báo để bạn theo dõi hoạt động của mình...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                times[index],
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
