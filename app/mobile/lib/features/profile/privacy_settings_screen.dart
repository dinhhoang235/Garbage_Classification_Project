import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isPublicProfile = true;
  bool _isEmailEnabled = false;
  bool _isLocationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Quyền riêng tư', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSwitchItem(
            'Công khai hồ sơ',
            'Cho phép người khác xem thành tích của bạn',
            _isPublicProfile,
            (val) => setState(() => _isPublicProfile = val),
            theme,
          ),
          _buildSwitchItem(
            'Nhận thông báo qua Email',
            'Cập nhật tin tức và sự kiện mới',
            _isEmailEnabled,
            (val) => setState(() => _isEmailEnabled = val),
            theme,
          ),
          _buildSwitchItem(
            'Chia sẻ vị trí',
            'Giúp tìm kiếm các điểm thu gom rác gần bạn hơn',
            _isLocationEnabled,
            (val) => setState(() => _isLocationEnabled = val),
            theme,
          ),
          const SizedBox(height: 24),
          Text(
            'Chúng tôi cam kết bảo vệ dữ liệu cá nhân của bạn. Xem thêm Điều khoản & Chính sách bảo mật của Eco Sort.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.disabledColor, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}
