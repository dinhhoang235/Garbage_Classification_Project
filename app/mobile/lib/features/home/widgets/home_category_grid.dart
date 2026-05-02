import 'package:flutter/material.dart';
import '../../../models/waste_category_model.dart';
import '../../../widgets/waste_category_card.dart';
import '../../../widgets/skeleton.dart';

class HomeCategoryGrid extends StatelessWidget {
  final List<WasteCategory> categories;
  final bool isLoading;
  final Function(String)? onCategoryRequested;

  const HomeCategoryGrid({
    super.key,
    required this.categories,
    required this.isLoading,
    this.onCategoryRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => const CategoryCardSkeleton(),
        ),
      );
    }

    if (categories.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Không thể tải danh mục',
            style: TextStyle(color: theme.disabledColor),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];
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
}
