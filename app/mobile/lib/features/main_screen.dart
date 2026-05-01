import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'scan/scan_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';
import '../models/user_model.dart';
import '../core/mock/mock_data.dart';

import 'home/category_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  User? _currentUser; // Global mock user state

  void _onLogin() {
    setState(() {
      _currentUser = MockData.currentUser;
      _selectedIndex = 0; // Switch to home after login
    });
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  void _requestLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then((_) {
      // Logic handled by login screen return or direct callback
      _onLogin();
    });
  }

  List<Widget> get _screens => [
        HomeScreen(
          currentUser: _currentUser,
          onLoginRequested: _requestLogin,
          onScanRequested: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanScreen(),
                fullscreenDialog: true,
              ),
            );
          },
          onHistoryRequested: () {
            setState(() {
              _selectedIndex = 1; // Switch to History tab
            });
          },
          onCategoryRequested: (category) {
            if (category == 'all') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryListScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Xem danh mục: $category'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          onNotificationRequested: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn không có thông báo mới'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const HistoryScreen(),
        const SizedBox.shrink(), // Placeholder for Scan tab
        const MapScreen(),
        ProfileScreen(
          currentUser: _currentUser,
          onLogin: _onLogin,
          onLogout: _onLogout,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanScreen(),
                  fullscreenDialog: true,
                ),
              );
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Theme.of(context).disabledColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              activeIcon: Icon(LucideIcons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.history),
              activeIcon: Icon(LucideIcons.history),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(LucideIcons.scan, color: Colors.white),
              ),
              label: 'Quét',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.map),
              activeIcon: Icon(LucideIcons.map),
              label: 'Bản đồ',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              activeIcon: Icon(LucideIcons.user),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}


