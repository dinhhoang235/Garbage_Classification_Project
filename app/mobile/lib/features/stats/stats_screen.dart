import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'Tháng này';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalCard(),
            const SizedBox(height: 24),
            _buildChartSection(theme),
            const SizedBox(height: 24),
            _buildComparisonCard(theme),
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

  Widget _buildTotalCard() {
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
              const Text(
                '12.6 kg',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'CO₂ tiết kiệm',
                style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12),
              ),
              const Text(
                '24.5 kg',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Icon(LucideIcons.globe, color: Colors.white, size: 80),
        ],
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme) {
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
            'Theo loại rác (kg)',
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
                      PieChartSectionData(color: AppColors.primary, value: 57, radius: 15, showTitle: false),
                      PieChartSectionData(color: AppColors.orange, value: 25, radius: 15, showTitle: false),
                      PieChartSectionData(color: AppColors.red, value: 10, radius: 15, showTitle: false),
                      PieChartSectionData(color: Colors.blueGrey, value: 8, radius: 15, showTitle: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Tái chế', '7.2 kg', '57%', AppColors.primary, theme),
                    _buildLegendItem('Hữu cơ', '3.1 kg', '25%', AppColors.orange, theme),
                    _buildLegendItem('Nguy hại', '1.2 kg', '10%', AppColors.red, theme),
                    _buildLegendItem('Khác', '1.1 kg', '8%', Colors.blueGrey, theme),
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

  Widget _buildComparisonCard(ThemeData theme) {
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
            'So sánh',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '+18%',
                style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                'so với tháng trước',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
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
                        const titles = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                        if (value.toInt() >= 0 && value.toInt() < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[value.toInt()],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.disabledColor,
                                fontWeight: FontWeight.bold,
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
                barGroups: [
                  _makeGroupData(0, 5, 8, theme),
                  _makeGroupData(1, 10, 12, theme),
                  _makeGroupData(2, 8, 15, theme),
                  _makeGroupData(3, 15, 20, theme),
                  _makeGroupData(4, 18, 25, theme),
                  _makeGroupData(5, 12, 18, theme),
                  _makeGroupData(6, 14, 22, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2, ThemeData theme) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: theme.dividerColor, width: 12, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: y2, color: AppColors.primary, width: 12, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }
}
