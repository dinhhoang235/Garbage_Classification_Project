import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;
  final Color? color;

  const Skeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color ?? (isDark ? Colors.grey[800] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class HistoryItemSkeleton extends StatelessWidget {
  const HistoryItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: Row(
        children: [
          const Skeleton(height: 60, width: 60, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 16, width: 120),
                const SizedBox(height: 8),
                const Skeleton(height: 12, width: 80),
              ],
            ),
          ),
          const Skeleton(height: 24, width: 60, borderRadius: 20),
        ],
      ),
    );
  }
}

class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Skeleton(
            height: 60,
            width: 60,
            borderRadius: 16,
            color: Theme.of(context).disabledColor.withAlpha(20),
          ),
          const SizedBox(height: 8),
          const Skeleton(height: 12, width: 50),
        ],
      ),
    );
  }
}

class AchievementCardSkeleton extends StatelessWidget {
  const AchievementCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Skeleton(height: 48, width: 48, borderRadius: 24),
          const SizedBox(height: 12),
          const Skeleton(height: 14, width: 80),
          const SizedBox(height: 8),
          const Skeleton(height: 10, width: 60),
        ],
      ),
    );
  }
}

class ScoreCardSkeleton extends StatelessWidget {
  const ScoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 14, width: 100),
                const SizedBox(height: 8),
                const Skeleton(height: 32, width: 150),
                const SizedBox(height: 12),
                const Skeleton(height: 24, width: 120, borderRadius: 12),
              ],
            ),
          ),
          const Skeleton(height: 80, width: 80, borderRadius: 40),
        ],
      ),
    );
  }
}

class CategoryItemSkeleton extends StatelessWidget {
  const CategoryItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: Row(
        children: [
          const Skeleton(height: 48, width: 48, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 18, width: 120),
                const SizedBox(height: 8),
                const Skeleton(height: 14, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 20, width: 150),
          const SizedBox(height: 24),
          Row(
            children: [
              const Skeleton(height: 150, width: 150, borderRadius: 75),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: List.generate(4, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Skeleton(height: 10, width: 10, borderRadius: 5),
                        const SizedBox(width: 8),
                        const Skeleton(height: 12, width: 60),
                      ],
                    ),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 40, width: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 16, width: 200),
                const SizedBox(height: 8),
                const Skeleton(height: 12, width: double.infinity),
                const SizedBox(height: 4),
                const Skeleton(height: 12, width: 150),
                const SizedBox(height: 8),
                const Skeleton(height: 10, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
