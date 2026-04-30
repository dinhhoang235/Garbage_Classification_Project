import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/eco_button.dart';
import '../../widgets/waste_category_card.dart';
import '../../widgets/history_item_card.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  final User? currentUser;
  final VoidCallback? onLoginRequested;

  const HomeScreen({
    super.key,
    this.currentUser,
    this.onLoginRequested,
  });

  bool get isLoggedIn => currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (isLoggedIn) ...[
                _buildScoreCard(),
                const SizedBox(height: 24),
              ] else ...[
                _buildGuestPrompt(),
                const SizedBox(height: 24),
              ],
              _buildScanBanner(),
              const SizedBox(height: 24),
              _buildSectionHeader('Danh mục rác', 'Xem tất cả'),
              const SizedBox(height: 16),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader('Thành tích gần đây', 'Xem tất cả'),
              const SizedBox(height: 16),
              _buildRecentAchievement(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào buổi sáng,',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              children: [
                Text(
                  isLoggedIn ? currentUser!.name : 'Khách',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(isLoggedIn ? '🌿' : '👋', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(LucideIcons.bell, size: 20, color: AppColors.textPrimary),
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

  Widget _buildScanBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quét rác ngay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sử dụng camera để nhận diện và phân loại rác thải.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                EcoButton(
                  label: 'Quét ngay',
                  onPressed: () {},
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

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': LucideIcons.glassWater, 'label': 'Nhựa', 'color': AppColors.blue},
      {'icon': LucideIcons.fileText, 'label': 'Giấy', 'color': AppColors.orange},
      {'icon': LucideIcons.hammer, 'label': 'Kim loại', 'color': Colors.blueGrey},
      {'icon': LucideIcons.leaf, 'label': 'Hữu cơ', 'color': AppColors.primary},
      {'icon': LucideIcons.zap, 'label': 'Pin & Điện tử', 'color': AppColors.red},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return WasteCategoryCard(
            icon: cat['icon'] as IconData,
            label: cat['label'] as String,
            color: cat['color'] as Color,
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
    );
  }
}


