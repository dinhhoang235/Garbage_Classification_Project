import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../stats/stats_screen.dart';
import '../../widgets/history_item_card.dart';
import '../../core/theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
            icon: const Icon(LucideIcons.barChart2, size: 20),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.filter, size: 20),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildDateHeader('Hôm nay'),
                _buildHistoryItem('Chai nhựa PET', 'Tái chế', '08:30', '+15 điểm', LucideIcons.glassWater, AppColors.blue),
                _buildHistoryItem('Vỏ chuối', 'Hữu cơ', '07:45', '+10 điểm', LucideIcons.leaf, AppColors.primary),
                _buildHistoryItem('Lon nhôm', 'Tái chế', '07:20', '+15 điểm', LucideIcons.hammer, Colors.blueGrey),
                const SizedBox(height: 24),
                _buildDateHeader('Hôm qua'),
                _buildHistoryItem('Pin tiểu', 'Nguy hại', '18:30', '+20 điểm', LucideIcons.zap, AppColors.red),
                _buildHistoryItem('Hộp giấy', 'Tái chế', '17:10', '+10 điểm', LucideIcons.fileText, AppColors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['Tất cả', 'Tái chế', 'Hữu cơ', 'Nguy hại'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return ChoiceChip(
            label: Text(tabs[index]),
            selected: isSelected,
            onSelected: (val) {},
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String type, String time, String points, IconData icon, Color color) {
    return HistoryItemCard(
      title: title,
      type: type,
      time: time,
      points: points,
      icon: icon,
      color: color,
    );
  }
}
