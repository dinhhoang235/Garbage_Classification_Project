import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';

class HistoryItem {
  final int id;
  final int userId;
  final String categoryId;
  final String title;
  final double confidence;
  final String? imageUrl;
  final String? location;
  final int pointsEarned;
  final DateTime createdAt;

  HistoryItem({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.confidence,
    this.imageUrl,
    this.location,
    required this.pointsEarned,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      categoryId: json['category_id'] ?? '',
      title: json['title'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      location: json['location'],
      pointsEarned: json['points_earned'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'title': title,
      'confidence': confidence,
      'image_url': imageUrl,
      'location': location,
      'points_earned': pointsEarned,
    };
  }

  // Helper: Map server label → display name
  static const Map<String, String> _labelToName = {
    'battery': 'Pin & Điện tử',
    'biological': 'Hữu cơ',
    'cardboard': 'Bìa carton',
    'clothes': 'Quần áo',
    'glass': 'Thủy tinh',
    'metal': 'Kim loại',
    'paper': 'Giấy',
    'plastic': 'Nhựa',
    'shoes': 'Giày dép',
    'trash': 'Rác thường',
  };

  static const Map<String, String> _labelToType = {
    'battery': 'Nguy hại',
    'biological': 'Hữu cơ',
    'cardboard': 'Tái chế',
    'clothes': 'Tái chế',
    'glass': 'Tái chế',
    'metal': 'Tái chế',
    'paper': 'Tái chế',
    'plastic': 'Tái chế',
    'shoes': 'Tái chế',
    'trash': 'Thường',
  };

  static const Map<String, Color> _labelToColor = {
    'battery': AppColors.red,
    'biological': AppColors.primary,
    'cardboard': AppColors.orange,
    'clothes': AppColors.blue,
    'glass': Colors.teal,
    'metal': Colors.blueGrey,
    'paper': AppColors.orange,
    'plastic': AppColors.blue,
    'shoes': Colors.brown,
    'trash': AppColors.textTertiary,
  };

  static const Map<String, IconData> _labelToIcon = {
    'battery': LucideIcons.zap,
    'biological': LucideIcons.leaf,
    'cardboard': LucideIcons.package,
    'clothes': LucideIcons.shirt,
    'glass': LucideIcons.wine,
    'metal': LucideIcons.hammer,
    'paper': LucideIcons.fileText,
    'plastic': LucideIcons.glassWater,
    'shoes': LucideIcons.footprints,
    'trash': LucideIcons.trash2,
  };

  String get displayName => _labelToName[categoryId] ?? title;
  String get type => _labelToType[categoryId] ?? 'Thường';
  Color get color => _labelToColor[categoryId] ?? AppColors.textTertiary;
  IconData get icon => _labelToIcon[categoryId] ?? LucideIcons.trash2;

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
