import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../stats/stats_screen.dart';
import '../../widgets/history_item_card.dart';
import '../../core/theme/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Tất cả';
  String _selectedSort = 'Mới nhất';

  final List<Map<String, dynamic>> _allHistoryItems = [
    {
      'title': 'Chai nhựa PET',
      'type': 'Tái chế',
      'time': '08:30',
      'points': '+15 điểm',
      'icon': LucideIcons.glassWater,
      'color': AppColors.blue,
      'date': 'Hôm nay',
      'timestamp': DateTime(2026, 5, 1, 8, 30),
    },
    {
      'title': 'Vỏ chuối',
      'type': 'Hữu cơ',
      'time': '07:45',
      'points': '+10 điểm',
      'icon': LucideIcons.leaf,
      'color': AppColors.primary,
      'date': 'Hôm nay',
      'timestamp': DateTime(2026, 5, 1, 7, 45),
    },
    {
      'title': 'Lon nhôm',
      'type': 'Tái chế',
      'time': '07:20',
      'points': '+15 điểm',
      'icon': LucideIcons.hammer,
      'color': Colors.blueGrey,
      'date': 'Hôm nay',
      'timestamp': DateTime(2026, 5, 1, 7, 20),
    },
    {
      'title': 'Pin tiểu',
      'type': 'Nguy hại',
      'time': '18:30',
      'points': '+20 điểm',
      'icon': LucideIcons.zap,
      'color': AppColors.red,
      'date': 'Hôm qua',
      'timestamp': DateTime(2026, 4, 30, 18, 30),
    },
    {
      'title': 'Hộp giấy',
      'type': 'Tái chế',
      'time': '17:10',
      'points': '+10 điểm',
      'icon': LucideIcons.fileText,
      'color': AppColors.orange,
      'date': 'Hôm qua',
      'timestamp': DateTime(2026, 4, 30, 17, 10),
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    List<Map<String, dynamic>> items = _selectedFilter == 'Tất cả' ? List.from(_allHistoryItems) : _allHistoryItems.where((item) => item['type'] == _selectedFilter).toList();

    items.sort((a, b) {
      final DateTime? dateA = a['timestamp'] as DateTime?;
      final DateTime? dateB = b['timestamp'] as DateTime?;

      if (dateA == null || dateB == null) return 0;

      if (_selectedSort == 'Mới nhất') {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
            icon: Icon(LucideIcons.barChart2, size: 20, color: theme.iconTheme.color),
          ),
          IconButton(
            onPressed: () {
              _showFilterBottomSheet(context, theme);
            },
            icon: Icon(LucideIcons.filter, size: 20, color: theme.iconTheme.color),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterTabs(theme),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.searchX, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text('Không có hoạt động nào', style: TextStyle(color: theme.disabledColor)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      bool showDate = index == 0 || filteredItems[index - 1]['date'] != item['date'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate) _buildDateHeader(item['date'], theme),
                          HistoryItemCard(
                            title: item['title'],
                            type: item['type'],
                            time: item['time'],
                            points: item['points'],
                            icon: item['icon'],
                            color: item['color'],
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bộ lọc & Sắp xếp',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(LucideIcons.x, color: theme.iconTheme.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sắp xếp theo',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterOption(
                    LucideIcons.clock,
                    'Mới nhất',
                    _selectedSort == 'Mới nhất',
                    theme,
                    () {
                      setModalState(() => _selectedSort = 'Mới nhất');
                      setState(() {});
                    },
                  ),
                  _buildFilterOption(
                    LucideIcons.history,
                    'Cũ nhất',
                    _selectedSort == 'Cũ nhất',
                    theme,
                    () {
                      setModalState(() => _selectedSort = 'Cũ nhất');
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(IconData icon, String label, bool isSelected, ThemeData theme, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? AppColors.primary : theme.iconTheme.color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary, size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    final tabs = ['Tất cả', 'Tái chế', 'Hữu cơ', 'Nguy hại'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = tabs[index];
          final isSelected = _selectedFilter == label;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() {
                  _selectedFilter = label;
                });
              }
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? AppColors.primary : theme.dividerColor.withAlpha(100)),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.titleMedium?.color,
        ),
      ),
    );
  }
}
