import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';

class PredictResult {
  final String label;
  final double confidence;
  final String? imageUrl;
  final Map<String, double> scores;

  PredictResult({
    required this.label,
    required this.confidence,
    this.imageUrl,
    required this.scores,
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
    );
  }

  static const Map<String, String> labelToName = {
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

  static const Map<String, String> _labelToGuide = {
    'battery': 'Phân loại riêng vì chứa chất độc hại, cần xử lý đặc biệt tại điểm thu gom nguy hại.',
    'biological': 'Bỏ vào thùng rác hữu cơ để ủ phân bón. Không trộn với rác tái chế.',
    'cardboard': 'Gấp gọn và giữ cho bìa luôn khô ráo trước khi tái chế.',
    'clothes': 'Có thể quyên góp nếu còn dùng được, hoặc bỏ vào điểm thu gom tái chế quần áo.',
    'glass': 'Bỏ vào thùng tái chế thủy tinh, cẩn thận khi xử lý để tránh bị thương.',
    'metal': 'Làm sạch và loại bỏ các phần nhựa đính kèm nếu có, sau đó bỏ vào thùng tái chế.',
    'paper': 'Giữ cho giấy khô ráo. Gấp gọn và bỏ vào thùng tái chế giấy.',
    'plastic': 'Rửa sạch, làm khô, bóp nhẹ và cho vào thùng rác tái chế.',
    'shoes': 'Nếu còn dùng được thì quyên góp, nếu không thì bỏ vào điểm tái chế đặc biệt.',
    'trash': 'Bỏ vào thùng rác thông thường. Tránh để lẫn với rác tái chế.',
  };

  static const Map<String, String> _labelToBin = {
    'battery': 'Thùng rác nguy hại (màu đỏ)',
    'biological': 'Thùng rác hữu cơ (màu nâu)',
    'cardboard': 'Thùng tái chế (màu xanh lá)',
    'clothes': 'Điểm thu gom quần áo',
    'glass': 'Thùng tái chế thủy tinh',
    'metal': 'Thùng tái chế (màu vàng)',
    'paper': 'Thùng tái chế giấy (màu xanh)',
    'plastic': 'Thùng tái chế (màu xanh lá)',
    'shoes': 'Điểm thu gom đặc biệt',
    'trash': 'Thùng rác thông thường (màu đen)',
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

  String get displayName => labelToName[label] ?? label;
  String get type => _labelToType[label] ?? 'Thường';
  String get guide => _labelToGuide[label] ?? 'Xử lý theo hướng dẫn địa phương.';
  String get binSuggestion => _labelToBin[label] ?? 'Thùng rác thông thường';
  Color get color => _labelToColor[label] ?? Colors.grey;
  IconData get icon => _labelToIcon[label] ?? LucideIcons.trash2;

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
