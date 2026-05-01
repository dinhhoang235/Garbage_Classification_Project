import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/category_service.dart';
import '../../models/waste_category_model.dart';
import '../../widgets/skeleton.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<WasteCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryService().getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh mục rác',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 5,
              itemBuilder: (context, index) => const CategoryItemSkeleton(),
            )
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.info, size: 64, color: theme.disabledColor),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy danh mục nào',
                        style: TextStyle(color: theme.disabledColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(category, theme);
                  },
                ),
    );
  }

  Widget _buildCategoryCard(WasteCategory category, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: category.color.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: category.color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: category.color, size: 24),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          category.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
        ),
        iconColor: theme.iconTheme.color,
        collapsedIconColor: theme.iconTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: theme.dividerColor),
                const SizedBox(height: 12),
                if (category.examples.isNotEmpty) ...[
                  const Text(
                    'Ví dụ:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.examples
                        .map((example) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white.withAlpha(13)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Text(example, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (category.disposalGuide.isNotEmpty) ...[
                  const Text(
                    'Hướng dẫn xử lý:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, color: category.color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.disposalGuide,
                            style: TextStyle(fontSize: 13, color: category.color, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
