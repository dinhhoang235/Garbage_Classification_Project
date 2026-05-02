import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/history_model.dart';

class CategoryMarker extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const CategoryMarker({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color markerColor;
    IconData iconData;

    switch (item.categoryId.toLowerCase()) {
      case 'plastic':
      case 'nhựa':
        markerColor = Colors.orange;
        iconData = Icons.recycling;
        break;
      case 'paper':
      case 'giấy':
        markerColor = Colors.blue;
        iconData = Icons.description;
        break;
      case 'metal':
      case 'kim loại':
        markerColor = Colors.grey;
        iconData = Icons.build;
        break;
      case 'biological':
      case 'hữu cơ':
        markerColor = Colors.green;
        iconData = Icons.eco;
        break;
      default:
        markerColor = AppColors.primary;
        iconData = Icons.delete_outline;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              iconData,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class SelectedPositionMarker extends StatelessWidget {
  final String? label;
  final VoidCallback onClear;

  const SelectedPositionMarker({
    super.key,
    this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Dùng Transform để đưa đầu nhọn của ghim về chính giữa tâm Marker
        Transform.translate(
          offset: const Offset(
              0, -20), // Dịch lên 20px (1/2 size icon) để đầu nhọn nằm đúng tâm
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Biểu tượng ghim
              const Icon(Icons.location_on, color: AppColors.red, size: 40),
              // Nút X gắn vào ghim
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.withAlpha(40)),
                    ),
                    child:
                        const Icon(Icons.close, size: 10, color: AppColors.red),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Nhãn địa điểm - Nằm trên ghim
        Positioned(
          bottom: 125, // Tạo khoảng cách 10px so với đỉnh ghim (150-35+10)
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CurrentLocationMarker extends StatelessWidget {
  const CurrentLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withAlpha(30),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
