import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Thành tích', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          final isUnlocked = index < 3;
          return _buildAchievementCard(index, isUnlocked, theme);
        },
      ),
    );
  }

  Widget _buildAchievementCard(int index, bool isUnlocked, ThemeData theme) {
    final titles = [
      'Người mới bắt đầu',
      'Siêu anh hùng nhựa',
      'Chiến binh giấy',
      'Bậc thầy phân loại',
      'Người bảo vệ rừng',
      'Tiết kiệm năng lượng',
      'Chuyên gia hữu cơ',
      'Người truyền cảm hứng'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? theme.cardColor : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? AppColors.primary.withAlpha(51) : theme.dividerColor),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: AppColors.primary.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.award,
            size: 48,
            color: isUnlocked ? AppColors.primary : theme.disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            titles[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isUnlocked ? theme.textTheme.titleMedium?.color : theme.disabledColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isUnlocked ? 'Đã đạt được' : 'Chưa đạt được',
            style: TextStyle(
              fontSize: 11,
              color: isUnlocked ? AppColors.primary : theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
