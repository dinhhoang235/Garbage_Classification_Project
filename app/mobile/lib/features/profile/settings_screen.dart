import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import '../../core/state/app_state.dart';
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
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService().themeModeNotifier,
            builder: (context, mode, _) {
              String status = 'Tắt';
              if (mode == ThemeMode.dark) {
                status = 'Bật';
              } else if (mode == ThemeMode.system) {
                status = Theme.of(context).brightness == Brightness.dark ? 'Bật' : 'Tắt';
              }
              
              return _buildSettingItem(
                LucideIcons.moon,
                'Chế độ tối',
                status,
                theme,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()));
                },
              );
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
          _buildSettingItem(
            LucideIcons.trash2,
            'Xóa tài khoản',
            '',
            theme,
            color: AppColors.red,
            onTap: () => _showDeleteConfirmation(context, theme),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
            ),
            const Icon(LucideIcons.alertTriangle, color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Xóa tài khoản?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hành động này không thể hoàn tác. Toàn bộ dữ liệu lịch sử và điểm tích lũy của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: Text('Hủy', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await UserService().deleteAccount();
                      if (success) {
                        await AuthService().logout();
                        AppState().setUser(null);
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tài khoản đã được xóa'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể xóa tài khoản, vui lòng thử lại sau'),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Xóa vĩnh viễn', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
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
