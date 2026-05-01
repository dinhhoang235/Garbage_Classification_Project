import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/profile_menu_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../models/user_model.dart';
import 'my_profile_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    required this.onLogin,
    required this.onLogout,
  });

  bool get isLoggedIn => currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (isLoggedIn) ...[
                    _buildLevelCard(context),
                    const SizedBox(height: 24),
                  ],
                  ProfileMenuItem(
                    icon: LucideIcons.user,
                    title: 'Hồ sơ của tôi',
                    onTap: () {
                      if (!isLoggedIn) {
                        _navigateToLogin(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyProfileScreen(user: currentUser!)),
                        );
                      }
                    },
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.trophy,
                    title: 'Thành tích',
                    trailing: isLoggedIn ? currentUser!.achievementsCount.toString() : null,
                    onTap: () {
                      if (!isLoggedIn) {
                        _navigateToLogin(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AchievementsScreen(user: currentUser)),
                        );
                      }
                    },
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.settings,
                    title: 'Cài đặt',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.bell,
                    title: 'Thông báo',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  ProfileMenuItem(
                    icon: LucideIcons.info,
                    title: 'Giới thiệu',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  isLoggedIn ? _buildLogoutButton() : _buildLoginButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    // AppState is updated by LoginScreen directly
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    onLogout();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withAlpha(51),
            backgroundImage: isLoggedIn && currentUser!.avatarUrl.isNotEmpty
                ? NetworkImage(currentUser!.avatarUrl)
                : null,
            child: isLoggedIn && currentUser!.avatarUrl.isEmpty
                ? Text(
                    currentUser!.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : (!isLoggedIn
                    ? const Icon(LucideIcons.user, color: Colors.white, size: 40)
                    : null),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? currentUser!.name : 'Khách',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isLoggedIn ? currentUser!.phoneNumber : 'Đăng nhập để lưu lại quá trình',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AchievementsScreen(user: currentUser)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.award, color: AppColors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${currentUser!.level} - ${currentUser!.levelName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${currentUser!.points.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} / 3.000 XP',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 16, color: theme.disabledColor),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: currentUser!.xpProgress,
                backgroundColor: theme.brightness == Brightness.dark ? Colors.white.withAlpha(26) : AppColors.primaryLight,
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateToLogin(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Đăng nhập',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Builder(
      builder: (context) => TextButton.icon(
        onPressed: () => _handleLogout(),
        icon: const Icon(LucideIcons.logOut, color: AppColors.red, size: 20),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }
}



