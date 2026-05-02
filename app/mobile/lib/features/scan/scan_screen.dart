import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'result_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/predict_service.dart';
import '../../core/state/app_state.dart';
import '../../main.dart' as main_dart;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  File? _selectedImage;
  bool _isAnalyzing = false;
  final _imagePicker = ImagePicker();
  final _predictService = PredictService();

  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (main_dart.cameras.isNotEmpty) {
      // Ưu tiên camera sau khi mở ứng dụng
      final backCameraIndex = main_dart.cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;
      
      _initCamera(main_dart.cameras[_selectedCameraIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(cameraController.description);
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (main_dart.cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % main_dart.cameras.length;
    await _initCamera(main_dart.cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFile == null) return;

      // Cho phép người dùng di chuyển và cắt ảnh để khớp với vùng quét
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Căn chỉnh ảnh rác',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Căn chỉnh ảnh rác',
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xử lý ảnh đã chọn'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    File? imageToAnalyze = _selectedImage;

    if (imageToAnalyze == null) {
      // Capture from camera if no image selected
      if (_controller == null || !_controller!.value.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera chưa sẵn sàng')),
        );
        return;
      }

      try {
        setState(() => _isAnalyzing = true);
        final XFile file = await _controller!.takePicture();
        imageToAnalyze = File(file.path);
      } catch (e) {
        debugPrint('Capture error: $e');
        setState(() => _isAnalyzing = false);
        return;
      }
    } else {
      setState(() => _isAnalyzing = true);
    }

    try {
      final result = await _predictService.predict(imageToAnalyze);
      if (!mounted) return;

      if (result != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              result: result,
              imageFile: imageToAnalyze,
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
          // Background: Camera Preview or selected image
          Positioned.fill(
            child: _selectedImage != null
                ? Container(
                    color: Colors.black,
                    child: Image.file(_selectedImage!, fit: BoxFit.contain),
                  )
                : (_controller != null && _controller!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: 1 / _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
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
                      Row(
                        children: [
                          if (_selectedImage == null && _controller != null)
                            IconButton(
                              onPressed: _toggleFlash,
                              icon: Icon(
                                _isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          if (_selectedImage != null)
                            TextButton.icon(
                              onPressed: () => setState(() => _selectedImage = null),
                              icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 16),
                              label: const Text('Chọn lại', style: TextStyle(color: Colors.white)),
                            ),
                        ],
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
                        onTapDown: (_) => setState(() => _buttonScale = 0.9),
                        onTapUp: (_) => setState(() => _buttonScale = 1.0),
                        onTapCancel: () => setState(() => _buttonScale = 1.0),
                        onTap: _isAnalyzing ? null : _analyzeImage,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 100),
                          scale: _buttonScale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (_selectedImage != null || _isAnalyzing)
                                    ? AppColors.primary
                                    : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                if (_selectedImage != null && !_isAnalyzing)
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(100),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: (_selectedImage != null || _isAnalyzing)
                                      ? AppColors.primary
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (_selectedImage != null || _isAnalyzing)
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                    width: 4,
                                  ),
                                ),
                                child: (_selectedImage != null || _isAnalyzing)
                                    ? const Icon(LucideIcons.zap, color: Colors.white, size: 28)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Toggle Camera button
                      GestureDetector(
                        onTap: _toggleCamera,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(LucideIcons.refreshCcw, color: Colors.white, size: 24),
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
