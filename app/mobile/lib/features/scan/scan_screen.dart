import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'result_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/predict_service.dart';
import '../../core/state/app_state.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  final _imagePicker = ImagePicker();
  final _predictService = PredictService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể truy cập máy ảnh/thư viện ảnh'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      // If no image selected, open camera
      await _pickImage(ImageSource.camera);
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _predictService.predict(_selectedImage!);
      if (!mounted) return;

      if (result != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              result: result,
              imageFile: _selectedImage,
            ),
          ),
        );
        // Reset after coming back
        if (mounted) {
          setState(() {
            _selectedImage = null;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể phân tích ảnh. Vui lòng thử lại.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: selected image or placeholder
          Positioned.fill(
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : Image.network(
                    'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=2070&auto=format&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(LucideIcons.camera, color: Colors.white24, size: 50),
                    ),
                  ),
          ),

          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(100),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withAlpha(200),
                ],
                stops: const [0.0, 0.2, 0.65, 1.0],
              ),
            ),
          ),

          // Analyzing overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black.withAlpha(160),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Đang phân tích ảnh...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI đang nhận diện loại rác',
                      style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x, color: Colors.white, size: 28),
                      ),
                      if (_selectedImage != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedImage = null),
                          icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 16),
                          label: const Text('Chọn lại', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // Scan frame
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
                        _buildCorner(0, 0, 0),
                        _buildCorner(0, 1, 90),
                        _buildCorner(1, 0, 270),
                        _buildCorner(1, 1, 180),
                        if (_selectedImage != null)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(200),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.check, color: Colors.white, size: 32),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Instruction
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedImage != null ? LucideIcons.checkCircle : LucideIcons.scan,
                        color: _selectedImage != null ? AppColors.primary : Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedImage != null
                            ? 'Ảnh đã chọn — nhấn nút dưới để phân tích'
                            : 'Chụp ảnh hoặc chọn từ thư viện',
                        style: TextStyle(
                          color: _selectedImage != null ? AppColors.primary : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Guest notice
                if (!AppState().isLoggedIn)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.info, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đăng nhập để lưu kết quả và tích điểm',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(LucideIcons.image, color: Colors.white, size: 24),
                        ),
                      ),

                      // Shutter / Analyze button
                      GestureDetector(
                        onTap: _isAnalyzing ? null : _analyzeImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedImage != null ? AppColors.primary : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: _selectedImage != null ? AppColors.primary : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedImage != null
                                      ? AppColors.primaryDark
                                      : AppColors.primary,
                                  width: 4,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? const Icon(LucideIcons.zap, color: Colors.white, size: 28)
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Camera button
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.camera),
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(LucideIcons.camera, color: Colors.white, size: 24),
                        ),
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
