import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'result_screen.dart';
import '../../core/theme/app_colors.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Background (Fixed URL)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[900],
                child: const Icon(LucideIcons.camera, color: Colors.white24, size: 50),
              ),
            ),
          ),
          // Overlay for focus
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(100),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withAlpha(180),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),
          // Scan UI
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.zap, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Scan Frame
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12, width: 1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Corner decorations - matching Image 1
                        _buildCorner(0, 0, 0),
                        _buildCorner(0, 1, 90),
                        _buildCorner(1, 0, 270),
                        _buildCorner(1, 1, 180),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Instruction text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.scan, color: Colors.white, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'Đặt vật thể vào khung hình',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom Controls Panel
                Padding(
                  padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery button
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1542601906990-b4d3fb773b09?q=80&w=100&auto=format&fit=crop',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.white10,
                              child: const Icon(LucideIcons.image, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      // Shutter button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResultScreen()),
                          );
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Flip camera button
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double top, double left, double rotation) {
    return Positioned(
      top: top == 0 ? -2 : null,
      bottom: top == 1 ? -2 : null,
      left: left == 0 ? -2 : null,
      right: left == 1 ? -2 : null,
      child: RotatedBox(
        quarterTurns: (rotation / 90).round(),
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 5),
              left: BorderSide(color: AppColors.primary, width: 5),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(25)),
          ),
        ),
      ),
    );
  }
}
