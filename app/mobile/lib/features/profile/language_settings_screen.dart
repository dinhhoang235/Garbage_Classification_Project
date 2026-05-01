import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Ngôn ngữ', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLanguageItem('Tiếng Việt', 'Vietnamese', theme),
          _buildLanguageItem('English', 'English', theme),
          _buildLanguageItem('日本語', 'Japanese', theme),
          _buildLanguageItem('한국어', 'Korean', theme),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(String title, String subtitle, ThemeData theme) {
    final isSelected = _selectedLanguage == title;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() {
          _selectedLanguage = title;
        });
      },
    );
  }
}
