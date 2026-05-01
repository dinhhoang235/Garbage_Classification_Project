import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';

class NotificationsBottomSheet extends StatelessWidget {
  const NotificationsBottomSheet({super.key});

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
                    TextButton.icon(
                      onPressed: () {},
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              itemCount: 5,
              separatorBuilder: (context, index) => Divider(height: 32, color: theme.dividerColor),
              itemBuilder: (context, index) {
                return _buildNotificationItem(index, theme);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
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
          child: const Icon(LucideIcons.bell, color: AppColors.primary, size: 18),
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
                      titles[index],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  if (index < 2)
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
                'Đây là nội dung chi tiết của thông báo để bạn theo dõi hoạt động của mình...',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(178), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    times[index],
                    style: TextStyle(color: theme.textTheme.bodySmall?.color?.withAlpha(128), fontSize: 12),
                  ),
                  Icon(
                    index < 2 ? LucideIcons.circle : LucideIcons.checkCircle2,
                    size: 16,
                    color: index < 2 ? theme.disabledColor : AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
