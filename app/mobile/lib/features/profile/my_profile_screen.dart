import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/user_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';

class MyProfileScreen extends StatefulWidget {
  final User user;

  const MyProfileScreen({super.key, required this.user});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isEditing = false;
  bool _isUploadingAvatar = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Ảnh đã chọn nhưng chưa upload (chờ user bấm ✓)
  File? _pendingAvatarFile;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Chọn ảnh từ gallery và Crop ─────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (picked == null) return;

    // Tiến hành crop ảnh thành hình vuông
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cắt ảnh',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Cắt ảnh',
          aspectRatioLockEnabled: true,
          resetButtonHidden: true,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      _pendingAvatarFile = File(croppedFile.path);
    });
  }

  // ── Upload ảnh lên MinIO qua presigned URL ────────────────────────────────
  Future<void> _uploadPendingAvatar() async {
    if (_pendingAvatarFile == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final updatedUser = await _userService.uploadAvatar(_pendingAvatarFile!);
      if (!context.mounted) return;
      if (updatedUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công 🎉'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
        // Trả về user đã cập nhật cho màn hình trước
        Navigator.pop(context, updatedUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload thất bại, vui lòng thử lại'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _pendingAvatarFile = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  bool _hasUnsavedChanges() {
    return _nameController.text != widget.user.name ||
           _phoneController.text != widget.user.phoneNumber ||
           _pendingAvatarFile != null;
  }

  void _showUnsavedChangesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo (Drag handle)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(51),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header: Tiêu đề + Nút X
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thay đổi chưa lưu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn có muốn lưu các thay đổi trước khi thoát chế độ chỉnh sửa không?',
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close modal
                  if (_pendingAvatarFile != null) {
                    await _uploadPendingAvatar();
                  } else {
                    setState(() => _isEditing = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Lưu và thoát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close modal
                  setState(() {
                    _isEditing = false;
                    _pendingAvatarFile = null;
                    _nameController.text = widget.user.name;
                    _phoneController.text = widget.user.phoneNumber;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Thoát không lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ sơ của tôi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _isEditing ? LucideIcons.x : LucideIcons.chevronLeft,
            color: theme.iconTheme.color,
          ),
          onPressed: () {
            if (_isEditing) {
              if (_hasUnsavedChanges()) {
                _showUnsavedChangesModal();
              } else {
                setState(() => _isEditing = false);
              }
            } else {
              Navigator.pop(context);
            }
          },
          ),
          actions: [
            IconButton(
              onPressed: () async {
                if (_isEditing) {
                  // Nếu không có gì thay đổi thì chỉ thoát chế độ sửa, không gọi API
                  if (!_hasUnsavedChanges()) {
                    setState(() => _isEditing = true); // Toggle back to false below
                  } else {
                    if (_pendingAvatarFile != null) {
                      // 1. Nếu có ảnh mới thì upload (hàm này đã bao gồm updateProfile bên trong)
                      await _uploadPendingAvatar();
                    } else {
                      // 2. Nếu chỉ đổi tên hoặc SĐT thì gọi updateProfile
                      setState(() => _isUploadingAvatar = true); // Show loading overlay
                      try {
                        final updatedUser = await _userService.updateProfile(
                          name: _nameController.text != widget.user.name ? _nameController.text : null,
                        );
                        // Lưu ý: Backend hiện chưa hỗ trợ update phone_number trực tiếp qua PUT /me 
                        // nhưng chúng ta vẫn có thể gửi lên nếu cần.
                        
                        if (updatedUser != null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật thông tin thành công'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          // Trả về user mới để cập nhật UI ở màn hình chính
                          Navigator.pop(context, updatedUser);
                          return;
                        }
                      } finally {
                        setState(() => _isUploadingAvatar = false);
                      }
                    }
                  }
                  setState(() => _isEditing = false);
                } else {
                  setState(() => _isEditing = true);
                }
              },
              icon: Icon(
                _isEditing ? LucideIcons.check : LucideIcons.edit3,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Avatar với nút camera ──────────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Avatar: ưu tiên pending preview → network URL → initials
                  GestureDetector(
                    onTap: _isEditing ? (_isUploadingAvatar ? null : _pickAvatar) : null,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      backgroundImage: _pendingAvatarFile != null
                          ? FileImage(_pendingAvatarFile!) as ImageProvider
                          : (widget.user.avatarUrl.isNotEmpty
                              ? NetworkImage(widget.user.avatarUrl)
                              : null),
                      child: (_pendingAvatarFile == null && widget.user.avatarUrl.isEmpty)
                          ? Text(
                              widget.user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Loading indicator khi đang upload
                  if (_isUploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    ),
                  // Nút camera — chỉ hiện khi đang ở chế độ chỉnh sửa
                  if (_isEditing)
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isUploadingAvatar ? Colors.grey : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              _buildField('Họ và tên', _nameController, _isEditing, theme),
              _buildField('Số điện thoại', _phoneController, _isEditing, theme),
            ],
          ),
        ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool enabled, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? theme.cardColor : theme.scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: enabled ? AppColors.primary.withAlpha(51) : theme.dividerColor),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
