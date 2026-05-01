import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import 'rank_detail_screen.dart';
import 'achievement_detail_screen.dart';

class AchievementsScreen extends StatelessWidget {
  final User? user;

  const AchievementsScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Thành tích', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: _buildLevelCard(context),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final isUnlocked = index < 3;
                  return _buildAchievementCard(context, index, isUnlocked, theme, titles);
                },
                childCount: titles.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RankDetailScreen(user: currentUser)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(76),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          image: const DecorationImage(
            image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
            opacity: 0.1,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trophy, color: Color(0xFFFFD700), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${currentUser.level} - ${currentUser.levelName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentUser.points.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} / 3.000 XP',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: currentUser.xpProgress,
                backgroundColor: Colors.white.withAlpha(51),
                color: Colors.white,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, int index, bool isUnlocked, ThemeData theme, List<String> titles) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AchievementDetailScreen(
              title: titles[index],
              isUnlocked: isUnlocked,
              index: index,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked ? theme.cardColor.withAlpha(200) : theme.scaffoldBackgroundColor,
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
      ),
    );
  }
}
