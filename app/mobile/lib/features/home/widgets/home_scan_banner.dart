import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/eco_button.dart';

class HomeScanBanner extends StatelessWidget {
  final VoidCallback? onScanRequested;

  const HomeScanBanner({super.key, this.onScanRequested});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
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
}
