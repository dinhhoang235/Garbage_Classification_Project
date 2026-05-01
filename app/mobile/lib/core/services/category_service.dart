import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';
import '../../models/waste_category_model.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<WasteCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        return (response.data as List).map((json) {
          final id = json['id']?.toString() ?? '';
          final iconName = json['icon_name']?.toString() ?? 'trash-2';
          final colorHex = json['color_hex']?.toString() ?? '#94A3B8';
          
          return WasteCategory(
            id: id,
            name: json['name'] ?? '',
            description: json['description'] ?? '',
            icon: _getIconFromName(iconName),
            color: _hexToColor(colorHex),
            examples: List<String>.from(json['examples'] ?? []),
            disposalGuide: json['disposal_guide'] ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('CategoryService.getCategories error: $e');
      return [];
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'glass-water': return LucideIcons.glassWater;
      case 'file-text': return LucideIcons.fileText;
      case 'hammer': return LucideIcons.hammer;
      case 'wine': return LucideIcons.wine;
      case 'leaf': return LucideIcons.leaf;
      case 'zap': return LucideIcons.zap;
      case 'package': return LucideIcons.package;
      case 'shirt': return LucideIcons.shirt;
      case 'footprints': return LucideIcons.footprints;
      case 'trash-2': return LucideIcons.trash2;
      default: return LucideIcons.trash2;
    }
  }
}
