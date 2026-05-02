import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../stats/stats_screen.dart';
import '../../widgets/history_item_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/history_service.dart';
import '../../core/state/app_state.dart';
import '../../models/history_model.dart';
import '../../widgets/skeleton.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Function(int)? onTabRequested;
  const HistoryScreen({super.key, this.onTabRequested});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Tất cả';
  String _selectedSort = 'Mới nhất';
  bool _isLoading = true;
  String? _errorMessage;
  List<HistoryItem> _allHistoryItems = [];

  final _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    AppState().historyUpdateNotifier.addListener(_loadHistory);
  }

  @override
  void dispose() {
    AppState().historyUpdateNotifier.removeListener(_loadHistory);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!AppState().isLoggedIn) {
      setState(() {
        _isLoading = false;
        _allHistoryItems = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _historyService.getHistory().timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _allHistoryItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  List<HistoryItem> get _filteredItems {
    List<HistoryItem> items = _selectedFilter == 'Tất cả'
        ? List.from(_allHistoryItems)
        : _allHistoryItems.where((item) => item.type == _selectedFilter).toList();

    items.sort((a, b) {
      return _selectedSort == 'Mới nhất'
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const StatsScreen()));
            },
            icon: Icon(LucideIcons.barChart2, size: 20, color: theme.iconTheme.color),
          ),
          IconButton(
            onPressed: () => _showFilterBottomSheet(context, theme),
            icon: Icon(LucideIcons.filter, size: 20, color: theme.iconTheme.color),
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.primary,
        child: Column(
          children: [
            _buildFilterTabs(theme),
            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: 6,
        itemBuilder: (context, index) => const HistoryItemSkeleton(),
      );
    }

    if (!AppState().isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logIn, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Đăng nhập để xem lịch sử',
                style: TextStyle(color: theme.disabledColor, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Mỗi lần quét rác sẽ được ghi lại tại đây.',
                style: TextStyle(color: theme.disabledColor, fontSize: 13)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: theme.disabledColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final filteredItems = _filteredItems;
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              _allHistoryItems.isEmpty ? 'Chưa có hoạt động nào' : 'Không tìm thấy kết quả',
              style: TextStyle(color: theme.disabledColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final showDate = index == 0 ||
            filteredItems[index - 1].formattedDate != item.formattedDate;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _buildDateHeader(item.formattedDate, theme),
            HistoryItemCard(
              title: item.displayName,
              type: item.type,
              time: item.formattedTime,
              points: '+${item.pointsEarned} điểm',
              icon: item.icon,
              color: item.color,
              imageUrl: item.imageUrl,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryDetailScreen(item: _buildDetailMap(item)),
                  ),
                );
                if (result == 'go_to_map' && widget.onTabRequested != null) {
                  widget.onTabRequested!(3);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _buildDetailMap(HistoryItem item) {
    return {
      'title': item.displayName,
      'type': item.type,
      'time': item.formattedTime,
      'points': '+${item.pointsEarned} điểm',
      'icon': item.icon,
      'color': item.color,
      'date': item.formattedDate,
      'timestamp': item.createdAt,
      'location': item.location ?? '',
      'imageUrl': item.imageUrl,
      'confidence': item.confidence,
      'guide': item.category?.disposalGuide ?? 'Đối với loại rác này, bạn nên làm sạch trước khi bỏ vào thùng rác để tăng hiệu quả tái chế và tránh mùi hôi.',
    };
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
                      Text('Bộ lọc & Sắp xếp',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(LucideIcons.x, color: theme.iconTheme.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Sắp xếp theo',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildFilterOption(LucideIcons.clock, 'Mới nhất', _selectedSort == 'Mới nhất',
                      theme, () {
                    setModalState(() => _selectedSort = 'Mới nhất');
                    setState(() {});
                  }),
                  _buildFilterOption(LucideIcons.history, 'Cũ nhất', _selectedSort == 'Cũ nhất',
                      theme, () {
                    setModalState(() => _selectedSort = 'Cũ nhất');
                    setState(() {});
                  }),
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

  Widget _buildFilterOption(
      IconData icon, String label, bool isSelected, ThemeData theme, VoidCallback onTap) {
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
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    final tabs = ['Tất cả', 'Tái chế', 'Hữu cơ', 'Nguy hại'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = tabs[index];
          final isSelected = _selectedFilter == label;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : theme.dividerColor.withAlpha(50),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
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
