import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AchievementDetailScreen extends StatelessWidget {
  final String title;
  final bool isUnlocked;
  final int index;

  const AchievementDetailScreen({
    super.key,
    required this.title,
    required this.isUnlocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      {'req': 'Hoàn thành lượt quét rác đầu tiên của bạn.', 'icon': LucideIcons.flag, 'reward': '50 XP'},
      {'req': 'Phân loại thành công 50 vật dụng từ chất liệu Nhựa.', 'icon': LucideIcons.glassWater, 'reward': '200 XP'},
      {'req': 'Phân loại thành công 50 vật dụng từ chất liệu Giấy.', 'icon': LucideIcons.fileText, 'reward': '200 XP'},
      {'req': 'Đạt tỉ lệ nhận diện chính xác 100% trong 20 lần quét liên tiếp.', 'icon': LucideIcons.checkCircle, 'reward': '500 XP'},
      {'req': 'Xử lý đúng cách 20 vật dụng hữu cơ.', 'icon': LucideIcons.leaf, 'reward': '150 XP'},
      {'req': 'Phân loại đúng 10 thiết bị điện tử hoặc pin cũ.', 'icon': LucideIcons.zap, 'reward': '300 XP'},
      {'req': 'Phân loại thành công 50 vật dụng hữu cơ.', 'icon': LucideIcons.apple, 'reward': '250 XP'},
      {'req': 'Đạt cấp độ 5 (Eco Hero) và chia sẻ ứng dụng cho 3 người bạn.', 'icon': LucideIcons.users, 'reward': '1000 XP'},
    ];

    final currentDetail = details[index % details.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thành tích', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.primary.withAlpha(26) : theme.disabledColor.withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? AppColors.primary : theme.disabledColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  LucideIcons.award,
                  size: 64,
                  color: isUnlocked ? AppColors.primary : theme.disabledColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked ? 'Đã đạt được' : 'Chưa đạt được',
              style: TextStyle(
                fontSize: 16,
                color: isUnlocked ? AppColors.primary : theme.disabledColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection(
                    context,
                    'Yêu cầu thành tích',
                    currentDetail['req'] as String,
                    currentDetail['icon'] as IconData,
                    theme,
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    context,
                    'Phần thưởng',
                    currentDetail['reward'] as String,
                    LucideIcons.gift,
                    theme,
                    isReward: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String label, String value, IconData icon, ThemeData theme, {bool isReward = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isReward ? AppColors.orange : AppColors.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.disabledColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
