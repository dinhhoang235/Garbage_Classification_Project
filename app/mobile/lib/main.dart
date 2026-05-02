import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:camera/camera.dart';

import 'core/theme/app_theme.dart';
import 'core/services/theme_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/user_service.dart';
import 'core/state/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/main_screen.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera error: $e');
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.init();

  // Check onboarding
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  // Try to auto-login from stored token
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  if (isLoggedIn) {
    final user = await UserService().getProfile();
    if (user != null) {
      AppState().setUser(user);
    } else {
      // Token invalid, clean up
      await authService.logout();
    }
  }

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Eco Sort',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: onboardingCompleted ? const MainScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}
