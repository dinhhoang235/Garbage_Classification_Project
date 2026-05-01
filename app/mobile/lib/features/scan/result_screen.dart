import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/eco_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/history_service.dart';
import '../../core/state/app_state.dart';
import '../../models/predict_result_model.dart';
import '../../models/history_model.dart';

class ResultScreen extends StatefulWidget {
  final PredictResult result;
  final File? imageFile;

  const ResultScreen({
    super.key,
    required this.result,
    this.imageFile,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _saved = false;

  Future<void> _saveToHistory() async {
    if (!AppState().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập để lưu kết quả và tích điểm'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final historyItem = HistoryItem(
        id: 0,
        userId: 0,
        categoryId: widget.result.label,
        title: widget.result.displayName,
        confidence: widget.result.confidence,
        imageUrl: widget.result.imageUrl,
        pointsEarned: widget.result.pointsEarned,
        createdAt: DateTime.now(),
      );

      final saved = await HistoryService().createHistoryItem(historyItem);

      if (!mounted) return;

      if (saved != null) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+${widget.result.pointsEarned} điểm đã được cộng vào tài khoản!'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu. Vui lòng thử lại.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả phân loại', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image preview
            if (widget.imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  widget.imageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              CircleAvatar(
                radius: 50,
                backgroundColor: result.color.withAlpha(26),
                child: Icon(result.icon, color: result.color, size: 50),
              ),

            const SizedBox(height: 24),

            // Category icon and name
            CircleAvatar(
              radius: 36,
              backgroundColor: result.color.withAlpha(30),
              child: Icon(result.icon, color: result.color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              result.displayName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: result.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.type,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Icon(result.icon, color: Colors.white, size: 14),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confidence bar
            _buildConfidenceBar(result.confidence, context),

            const SizedBox(height: 8),

            // Points earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.star, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+${result.pointsEarned} điểm',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _buildInfoTile(LucideIcons.trash2, 'Thùng rác phù hợp', result.binSuggestion, context),
            _buildInfoTile(LucideIcons.info, 'Cách xử lý', result.guide, context),

            const SizedBox(height: 8),

            // Top scores
            _buildScoresSection(result, context),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: EcoButton(
                    label: 'Quét lại',
                    onPressed: () => Navigator.pop(context),
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _saved
                      ? EcoButton(
                          label: 'Đã lưu ✓',
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          isPrimary: true,
                        )
                      : EcoButton(
                          label: _isSaving ? 'Đang lưu...' : 'Lưu & Tích điểm',
                          onPressed: _isSaving ? () {} : _saveToHistory,
                          isPrimary: true,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence, BuildContext context) {
    final theme = Theme.of(context);
    final pct = (confidence * 100).toStringAsFixed(1);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Độ chính xác', style: TextStyle(color: theme.disabledColor, fontSize: 13)),
            Text('$pct%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: theme.brightness == Brightness.dark
                ? Colors.white12
                : AppColors.primaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence > 0.8
                  ? AppColors.primary
                  : confidence > 0.5
                      ? AppColors.orange
                      : AppColors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection(PredictResult result, BuildContext context) {
    final theme = Theme.of(context);
    // Show top 3 scores
    final sortedScores = result.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedScores.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kết quả chi tiết (Top 3)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...top3.map((entry) {
            final isTop = entry.key == result.label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      PredictResult.labelToName[entry.key] ?? entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                        color: isTop ? result.color : theme.textTheme.bodyMedium?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: entry.value,
                        minHeight: 6,
                        backgroundColor: theme.brightness == Brightness.dark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTop ? result.color : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(entry.value * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                      color: isTop ? result.color : theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withAlpha(26)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
