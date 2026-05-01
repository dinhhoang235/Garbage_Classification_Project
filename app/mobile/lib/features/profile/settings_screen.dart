import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import 'language_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Chung', theme),
          _buildSettingItem(
            LucideIcons.globe,
            'Ngôn ngữ',
            'Tiếng Việt',
            theme,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()));
            },
          ),
          _buildSettingItem(
            LucideIcons.moon,
            'Chế độ tối',
            'Tắt',
            theme,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()));
            },
          ),
          const SizedBox(height: 24),
          _buildSection('Bảo mật', theme),
          _buildSettingItem(
            LucideIcons.lock,
            'Đổi mật khẩu',
            '',
            theme,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            },
          ),
          _buildSettingItem(
            LucideIcons.shieldCheck,
            'Quyền riêng tư',
            '',
            theme,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()));
            },
          ),
          const SizedBox(height: 24),
          _buildSection('Khác', theme),
          _buildSettingItem(LucideIcons.helpCircle, 'Hỗ trợ', '', theme, onTap: () {}),
          _buildSettingItem(LucideIcons.trash2, 'Xóa tài khoản', '', theme, color: AppColors.red, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSection(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String value, ThemeData theme, {Color? color, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? theme.iconTheme.color, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color ?? theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(value, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, color: theme.disabledColor, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}
