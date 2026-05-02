import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import 'waste_category_model.dart';

class HistoryItem {
  final int id;
  final int userId;
  final String categoryId;
  final String title;
  final double confidence;
  final String? imageUrl;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int pointsEarned;
  final DateTime createdAt;
  final WasteCategory? category;

  HistoryItem({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.confidence,
    this.imageUrl,
    this.location,
    this.latitude,
    this.longitude,
    required this.pointsEarned,
    required this.createdAt,
    this.category,
  });

  HistoryItem copyWith({
    int? id,
    int? userId,
    String? categoryId,
    String? title,
    double? confidence,
    String? imageUrl,
    String? location,
    double? latitude,
    double? longitude,
    int? pointsEarned,
    DateTime? createdAt,
    WasteCategory? category,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      confidence: confidence ?? this.confidence,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    String? dateStr = json['created_at']?.toString();
    if (dateStr != null && !dateStr.endsWith('Z') && !dateStr.contains('+')) {
      dateStr += 'Z';
    }

    return HistoryItem(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      categoryId: json['category_id'] ?? '',
      title: json['title'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      location: json['location'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      pointsEarned: json['points_earned'] ?? 0,
      createdAt: dateStr != null
          ? (DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      category: json['category'] != null ? WasteCategory.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'title': title,
      'confidence': confidence,
      'image_url': imageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'points_earned': pointsEarned,
    };
  }

  String get displayName => category?.name ?? title;
  String get type {
    if (categoryId == 'battery') return 'Nguy hại';
    if (categoryId == 'biological') return 'Hữu cơ';
    if (categoryId == 'trash') return 'Thường';
    return 'Tái chế';
  }
  Color get color => category?.color ?? AppColors.textTertiary;
  IconData get icon => category?.icon ?? LucideIcons.trash2;

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
