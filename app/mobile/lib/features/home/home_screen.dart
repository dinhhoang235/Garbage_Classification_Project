import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/eco_button.dart';
import '../../widgets/waste_category_card.dart';
import '../../widgets/history_item_card.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../core/mock/mock_data.dart';

class HomeScreen extends StatelessWidget {
  final User? currentUser;
  final VoidCallback? onLoginRequested;
  final VoidCallback? onScanRequested;
  final VoidCallback? onHistoryRequested;
  final Function(String)? onCategoryRequested;
  final VoidCallback? onNotificationRequested;
  final VoidCallback? onAchievementsRequested;

  const HomeScreen({
    super.key,
    this.currentUser,
    this.onLoginRequested,
    this.onScanRequested,
    this.onHistoryRequested,
    this.onCategoryRequested,
    this.onNotificationRequested,
    this.onAchievementsRequested,
  });

  bool get isLoggedIn => currentUser != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              if (isLoggedIn) ...[
                GestureDetector(
                  onTap: onAchievementsRequested,
                  child: _buildScoreCard(),
                ),
                const SizedBox(height: 24),
              ] else ...[
                _buildGuestPrompt(),
                const SizedBox(height: 24),
              ],
              _buildScanBanner(theme),
              const SizedBox(height: 24),
              _buildSectionHeader('Danh mục rác', 'Xem tất cả', () => onCategoryRequested?.call('all'), theme),
              const SizedBox(height: 16),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader('Thành tích gần đây', 'Xem tất cả', onHistoryRequested, theme),
              const SizedBox(height: 16),
              _buildRecentAchievement(),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Chào buổi sáng,';
    } else if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều,';
    } else {
      return 'Chào buổi tối,';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '🌅';
    } else if (hour >= 12 && hour < 18) {
      return '☀️';
    } else {
      return '🌙';
    }
  }

  Widget _buildHeader(ThemeData theme) {
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
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 14)),
              ],
            ),
            Row(
              children: [
                Text(
                  isLoggedIn ? currentUser!.name : 'Khách',
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
          onTap: onNotificationRequested,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(LucideIcons.bell, size: 20, color: theme.iconTheme.color),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestPrompt() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bắt đầu hành trình xanh!',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng nhập để theo dõi điểm thưởng và thành tích bảo vệ môi trường của bạn.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onLoginRequested,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm của bạn',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  currentUser!.points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.award, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${currentUser!.level} - ${currentUser!.levelName}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(LucideIcons.trophy, color: Color(0xFFFFD700), size: 40),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Level ${currentUser!.level}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? theme.cardColor : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quét rác ngay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sử dụng camera để nhận diện và phân loại rác thải.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),
                EcoButton(
                  label: 'Quét ngay',
                  onPressed: onScanRequested ?? () {},
                  icon: LucideIcons.scan,
                  isFullWidth: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Image.network(
            'https://cdn-icons-png.flaticon.com/512/3067/3067451.png',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback? onPressed, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            action,
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MockData.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = MockData.categories[index];
          return WasteCategoryCard(
            icon: cat.icon,
            label: cat.name,
            color: cat.color,
            onTap: () => onCategoryRequested?.call(cat.name),
          );
        },
      ),
    );
  }

  Widget _buildRecentAchievement() {
    return HistoryItemCard(
      title: 'Chai nhựa PET',
      type: 'Tái chế',
      time: 'Hôm nay, 08:30',
      points: isLoggedIn ? '+15 điểm' : 'Đăng nhập để tích điểm',
      icon: LucideIcons.glassWater,
      color: AppColors.blue,
      onTap: onHistoryRequested,
    );
  }
}


