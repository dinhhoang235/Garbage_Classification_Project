import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
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
          // Simulated Camera Background
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1595273670150-db0a3d326495?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay
          Container(
            color: Colors.black.withAlpha(77),
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
                        onPressed: () {},
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black26),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.zap, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black26),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Scan Frame
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 350,
                    child: Stack(
                      children: [
                        DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            color: AppColors.primary,
                            strokeWidth: 3,
                            dashPattern: const [40, 20],
                            radius: const Radius.circular(30),
                          ),
                          child: const SizedBox.expand(),
                        ),
                        // Corner decorations
                        _buildCorner(0, 0, 0),
                        _buildCorner(1, 0, 90),
                        _buildCorner(0, 1, 270),
                        _buildCorner(1, 1, 180),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đặt vật thể vào khung hình',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1595273670150-db0a3d326495?q=80&w=100&auto=format&fit=crop',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
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
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.refreshCcw, color: Colors.white, size: 28),
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
      top: top == 0 ? 0 : null,
      bottom: top == 1 ? 0 : null,
      left: left == 0 ? 0 : null,
      right: left == 1 ? 0 : null,
      child: RotatedBox(
        quarterTurns: (rotation / 90).round(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 6),
              left: BorderSide(color: AppColors.primary, width: 6),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
          ),
        ),
      ),
    );
  }
}
