import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/theme_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeService.themeModeNotifier,
      builder: (context, currentMode, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Chế độ tối', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildThemeItem('Sáng', LucideIcons.sun, ThemeMode.light, currentMode),
              _buildThemeItem('Tối', LucideIcons.moon, ThemeMode.dark, currentMode),
              _buildThemeItem('Theo hệ thống', LucideIcons.monitor, ThemeMode.system, currentMode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeItem(String title, IconData icon, ThemeMode mode, ThemeMode currentMode) {
    final isSelected = currentMode == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: isSelected ? AppColors.primary : Theme.of(context).iconTheme.color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
      onTap: () {
        _themeService.setThemeMode(mode);
      },
    );
  }
}
