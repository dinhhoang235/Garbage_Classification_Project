import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WasteCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> examples;
  final String disposalGuide;

  WasteCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.examples,
    required this.disposalGuide,
  });

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    final iconName = json['icon_name']?.toString() ?? 'trash-2';
    final colorHex = json['color_hex']?.toString() ?? '#94A3B8';
    
    return WasteCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconFromName(iconName),
      color: _hexToColor(colorHex),
      examples: List<String>.from(json['examples'] ?? []),
      disposalGuide: json['disposal_guide'] ?? '',
    );
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static IconData _getIconFromName(String name) {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'examples': examples,
      'disposal_guide': disposalGuide,
    };
  }
}
