import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _emailController = TextEditingController(text: 'minhanh.eco@gmail.com');
    _addressController = TextEditingController(text: '123 Đường Láng, Đống Đa, Hà Nội');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
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
              setState(() {
                _isEditing = false;
                // Revert changes
                _nameController.text = widget.user.name;
                _phoneController.text = widget.user.phoneNumber;
                _emailController.text = 'minhanh.eco@gmail.com';
                _addressController.text = '123 Đường Láng, Đống Đa, Hà Nội';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                // Save logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thông tin thành công'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                  ),
                );
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
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.user.avatarUrl),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _buildField('Họ và tên', _nameController, _isEditing, theme),
            _buildField('Số điện thoại', _phoneController, _isEditing, theme),
            _buildField('Email', _emailController, _isEditing, theme),
            _buildField('Địa chỉ', _addressController, _isEditing, theme),
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
