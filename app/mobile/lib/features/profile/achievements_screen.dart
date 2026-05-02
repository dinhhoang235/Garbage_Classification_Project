import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/achievement_model.dart';
import '../../core/services/user_service.dart';
import 'rank_detail_screen.dart';
import 'achievement_detail_screen.dart';
import '../../widgets/skeleton.dart';

class AchievementsScreen extends StatefulWidget {
  final User? user;

  const AchievementsScreen({super.key, this.user});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadAchievements();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final achievements = await _userService.getAchievements();
      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải dữ liệu thành tích. Vui lòng kiểm tra kết nối.';
        });
      }
    }
  }

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
      body: RefreshIndicator(
        onRefresh: _loadAchievements,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (widget.user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: _buildLevelCard(context),
                ),
              ),
            if (_isLoading)
              _buildSkeletonGrid(theme)
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: _buildErrorState(theme),
              )
            else if (_achievements.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Chưa có thành tích nào')),
              )
            else
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
                      final achievement = _achievements[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final animationValue = Curves.easeOut.transform(
                            (_animationController.value - delay).clamp(0.0, 1.0),
                          );
                          return Opacity(
                            opacity: animationValue,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - animationValue)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildAchievementCard(context, index, achievement, theme),
                      );
                    },
                    childCount: _achievements.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid(ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const AchievementCardSkeleton(),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.disabledColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAchievements,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context) {
    final currentUser = widget.user;
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
                        '${currentUser.totalXP} / ${currentUser.nextLevelTotalXP} XP',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Còn ${currentUser.nextLevelTotalXP - currentUser.totalXP} XP nữa để lên Level ${currentUser.level + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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
                value: (currentUser.xpProgress / currentUser.currentLevelMaxXP).clamp(0.0, 1.0),
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

  Widget _buildAchievementCard(BuildContext context, int index, Achievement achievement, ThemeData theme) {
    final isUnlocked = achievement.isUnlocked;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AchievementDetailScreen(
              achievement: achievement,
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
              _getIconForAchievement(achievement.id),
              size: 48,
              color: isUnlocked ? AppColors.primary : theme.disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
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
            if (!isUnlocked && achievement.targetCount > 0) ...[
               const SizedBox(height: 8),
               ClipRRect(
                 borderRadius: BorderRadius.circular(4),
                 child: LinearProgressIndicator(
                   value: achievement.progress,
                   backgroundColor: theme.dividerColor,
                   color: AppColors.primary.withAlpha(128),
                   minHeight: 4,
                 ),
               ),
               const SizedBox(height: 4),
               Text(
                 '${achievement.currentCount}/${achievement.targetCount}',
                 style: TextStyle(fontSize: 10, color: theme.disabledColor),
               ),
            ]
          ],
        ),
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
