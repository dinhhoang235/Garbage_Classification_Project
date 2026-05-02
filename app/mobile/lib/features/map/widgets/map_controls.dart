import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/theme/app_colors.dart';

class MapControls extends StatelessWidget {
  final MapController mapController;
  final VoidCallback onLocateMe;

  const MapControls({
    super.key,
    required this.mapController,
    required this.onLocateMe,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      right: 16,
      child: Column(
        children: [
          // Zoom group
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildControlButton(
                  icon: Icons.add,
                  onPressed: () {
                    final currentZoom = mapController.camera.zoom;
                    mapController.move(mapController.camera.center, currentZoom + 1);
                  },
                ),
                Divider(height: 1, color: Colors.grey[100], indent: 8, endIndent: 8),
                _buildControlButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final currentZoom = mapController.camera.zoom;
                    mapController.move(mapController.camera.center, currentZoom - 1);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Locate button
          GestureDetector(
            onTap: onLocateMe,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.grey[700], size: 22),
        ),
      ),
    );
  }
}
