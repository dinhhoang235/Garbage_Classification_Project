import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/skeleton.dart';
import '../../core/services/history_service.dart';
import '../../models/history_model.dart';
import '../../core/state/app_state.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'Tuần này';
  bool _isLoading = true;
  List<HistoryItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    if (AppState().isLoggedIn) {
      final items = await HistoryService().getHistory();
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<HistoryItem> _getFilteredItems() {
    final now = DateTime.now();
    return _allItems.where((item) {
      if (_selectedPeriod == 'Tuần này') {
        return now.difference(item.createdAt).inDays <= 7;
      } else if (_selectedPeriod == 'Tháng này') {
        return item.createdAt.year == now.year && item.createdAt.month == now.month;
      } else if (_selectedPeriod == 'Năm này') {
        return item.createdAt.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems = _getFilteredItems();
    final totalScans = filteredItems.length;
    final totalPoints = filteredItems.fold<int>(0, (sum, item) => sum + item.pointsEarned);

    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          GestureDetector(
            onTap: () => _showPeriodSelector(context, theme),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor.withAlpha(100)),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedPeriod,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronDown, size: 14, color: theme.iconTheme.color),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const ScoreCardSkeleton(),
                  const SizedBox(height: 24),
                  const ChartSkeleton(),
                  const SizedBox(height: 24),
                  const ChartSkeleton(),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalCard(totalScans, totalPoints),
                  const SizedBox(height: 24),
                  _buildChartSection(theme, filteredItems, totalScans),
                  const SizedBox(height: 24),
                  _buildComparisonCard(theme, filteredItems),
                ],
              ),
            ),
    );
  }

  void _showPeriodSelector(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                    'Chọn thời gian',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: theme.iconTheme.color),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPeriodOption(LucideIcons.calendar, 'Tuần này', theme),
              _buildPeriodOption(LucideIcons.calendarDays, 'Tháng này', theme),
              _buildPeriodOption(LucideIcons.calendarRange, 'Năm này', theme),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(IconData icon, String label, ThemeData theme) {
    final isSelected = _selectedPeriod == label;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : theme.iconTheme.color,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary, size: 20) : null,
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTotalCard(int totalScans, int totalPoints) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
          opacity: 0.05,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng rác đã phân loại',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '$totalScans lần',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Điểm nhận được',
                style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12),
              ),
              Text(
                '+$totalPoints điểm',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(LucideIcons.globe, color: Colors.white, size: 80),
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme, List<HistoryItem> items, int totalScans) {
    int countTaiChe = items.where((i) => i.type == 'Tái chế').length;
    int countHuuCo = items.where((i) => i.type == 'Hữu cơ').length;
    int countNguyHai = items.where((i) => i.type == 'Nguy hại').length;
    int countKhac = items.where((i) => i.type == 'Khác').length;
    
    int matched = countTaiChe + countHuuCo + countNguyHai + countKhac;
    if (matched < totalScans) countKhac += (totalScans - matched);

    double pctTaiChe = totalScans == 0 ? 0 : (countTaiChe / totalScans * 100);
    double pctHuuCo = totalScans == 0 ? 0 : (countHuuCo / totalScans * 100);
    double pctNguyHai = totalScans == 0 ? 0 : (countNguyHai / totalScans * 100);
    double pctKhac = totalScans == 0 ? 0 : (countKhac / totalScans * 100);

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
          Text(
            'Theo loại rác (lần)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(color: AppColors.primary, value: pctTaiChe > 0 ? pctTaiChe : 1, radius: 15, showTitle: false),
                      PieChartSectionData(color: AppColors.orange, value: pctHuuCo > 0 ? pctHuuCo : 1, radius: 15, showTitle: false),
                      PieChartSectionData(color: AppColors.red, value: pctNguyHai > 0 ? pctNguyHai : 1, radius: 15, showTitle: false),
                      PieChartSectionData(color: Colors.blueGrey, value: pctKhac > 0 ? pctKhac : 1, radius: 15, showTitle: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Tái chế', '$countTaiChe lần', '${pctTaiChe.toStringAsFixed(0)}%', AppColors.primary, theme),
                    _buildLegendItem('Hữu cơ', '$countHuuCo lần', '${pctHuuCo.toStringAsFixed(0)}%', AppColors.orange, theme),
                    _buildLegendItem('Nguy hại', '$countNguyHai lần', '${pctNguyHai.toStringAsFixed(0)}%', AppColors.red, theme),
                    _buildLegendItem('Khác', '$countKhac lần', '${pctKhac.toStringAsFixed(0)}%', Colors.blueGrey, theme),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, String percent, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('($percent)', style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(ThemeData theme, List<HistoryItem> items) {
    final now = DateTime.now();
    List<int> counts = [];
    List<String> labels = [];
    String title = 'Tần suất quét';

    if (_selectedPeriod == 'Tuần này') {
      title = 'Tần suất quét (7 ngày qua)';
      counts = List.filled(7, 0);
      for (var item in items) {
        final diff = now.difference(item.createdAt).inDays;
        if (diff >= 0 && diff < 7) {
          counts[6 - diff]++;
        }
      }
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        labels.add('${date.day}/${date.month}');
      }
    } else if (_selectedPeriod == 'Tháng này') {
      title = 'Tần suất quét (4 tuần)';
      counts = List.filled(4, 0);
      for (var item in items) {
        if (item.createdAt.year == now.year && item.createdAt.month == now.month) {
          int day = item.createdAt.day;
          if (day <= 7) {
            counts[0]++;
          } else if (day <= 14) {
            counts[1]++;
          } else if (day <= 21) {
            counts[2]++;
          } else {
            counts[3]++;
          }
        }
      }
      labels = ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
    } else if (_selectedPeriod == 'Năm này') {
      title = 'Tần suất quét (12 tháng)';
      counts = List.filled(12, 0);
      for (var item in items) {
        if (item.createdAt.year == now.year) {
          counts[item.createdAt.month - 1]++;
        }
      }
      labels = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
    }

    double maxCount = 0;
    for (var count in counts) {
      if (count > maxCount) maxCount = count.toDouble();
    }
    if (maxCount == 0) maxCount = 5;

    double average = counts.isEmpty ? 0 : counts.reduce((a, b) => a + b) / counts.length;
    double barWidth = counts.length > 7 ? 8 : 12;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < counts.length; i++) {
      barGroups.add(_makeGroupData(i, average, counts[i].toDouble(), theme, barWidth));
    }

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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxCount * 1.2,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.disabledColor,
                                fontWeight: FontWeight.bold,
                                fontSize: counts.length > 7 ? 10 : 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2, ThemeData theme, double width) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: theme.dividerColor.withAlpha(100), width: width, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: y2, color: AppColors.primary, width: width, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }
}
