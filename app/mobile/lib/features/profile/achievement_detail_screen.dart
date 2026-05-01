import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/achievement_model.dart';

class AchievementDetailScreen extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailScreen({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

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
                  _getIconForAchievement(achievement.id),
                  size: 64,
                  color: isUnlocked ? AppColors.primary : theme.disabledColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              achievement.title,
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
                  if (!isUnlocked && achievement.targetCount > 0) ...[
                    Text(
                      'Tiến độ',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.disabledColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: 12,
                        backgroundColor: theme.dividerColor,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${achievement.currentCount} / ${achievement.targetCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                  ],
                  _buildDetailSection(
                    context,
                    'Yêu cầu thành tích',
                    achievement.description,
                    LucideIcons.target,
                    theme,
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    context,
                    'Phần thưởng',
                    'Thẻ danh hiệu độc quyền',
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

  IconData _getIconForAchievement(String id) {
    switch (id) {
      case 'beginner': return LucideIcons.award;
      case 'plastic_hero': return LucideIcons.recycle;
      case 'paper_warrior': return LucideIcons.fileText;
      case 'sorting_master': return LucideIcons.layers;
      case 'forest_protector': return LucideIcons.treePine;
      case 'energy_saver': return LucideIcons.zap;
      case 'organic_expert': return LucideIcons.leaf;
      case 'inspiration': return LucideIcons.star;
      default: return LucideIcons.award;
    }
  }
}
