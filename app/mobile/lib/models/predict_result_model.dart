import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import 'waste_category_model.dart';

class PredictResult {
  final String label;
  final double confidence;
  final String? imageUrl;
  final Map<String, double> scores;
  final WasteCategory? category;

  PredictResult({
    required this.label,
    required this.confidence,
    this.imageUrl,
    required this.scores,
    this.category,
  });

  factory PredictResult.fromJson(Map<String, dynamic> json) {
    return PredictResult(
      label: json['label'] ?? 'trash',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      scores: Map<String, double>.from(
        ((json['scores'] as Map<String, dynamic>?) ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      category: json['category'] != null ? WasteCategory.fromJson(json['category']) : null,
    );
  }

  String get displayName => category?.name ?? label;
  String get type {
    if (label == 'battery') return 'Nguy hại';
    if (label == 'biological') return 'Hữu cơ';
    if (label == 'trash') return 'Thường';
    return 'Tái chế';
  }
  String get guide => category?.disposalGuide ?? 'Xử lý theo hướng dẫn địa phương.';
  String get binSuggestion => category?.description ?? 'Thùng rác thông thường';
  Color get color => category?.color ?? AppColors.textTertiary;
  IconData get icon => category?.icon ?? LucideIcons.trash2;

  int get pointsEarned {
    switch (label) {
      case 'battery':
        return 20;
      case 'biological':
        return 10;
      default:
        return 15;
    }
  }
}
