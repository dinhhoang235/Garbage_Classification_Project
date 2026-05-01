import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Giới thiệu', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(LucideIcons.leaf, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Eco Sort',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Text(
              'Phiên bản 1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Eco Sort là ứng dụng giúp bạn phân loại rác thải một cách thông minh bằng công nghệ AI. Chúng tôi mong muốn xây dựng một cộng đồng sống xanh và bảo vệ môi trường bền vững.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 40),
            _buildLinkItem(LucideIcons.globe, 'Website', 'www.ecosort.vn'),
            _buildLinkItem(LucideIcons.facebook, 'Facebook', 'fb.com/ecosort'),
            _buildLinkItem(LucideIcons.mail, 'Liên hệ', 'contact@ecosort.vn'),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: const Icon(LucideIcons.externalLink, size: 18),
      onTap: () {},
    );
  }
}
