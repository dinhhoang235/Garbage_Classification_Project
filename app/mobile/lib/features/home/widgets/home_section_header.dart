import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onPressed;

  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.action,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Text(action, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
        ),
      ],
    );
  }
}
