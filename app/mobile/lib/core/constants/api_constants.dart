import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost / 127.0.0.1
  // Real device: LAN IP (e.g. 192.168.1.x)
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  // User endpoints
  static const String getProfile = '/users/me';
  static const String changePassword = '/users/me/change-password';
  static const String avatarUploadUrl = '/users/me/avatar-upload-url';
  static const String achievements = '/users/me/achievements';

  // Categories endpoints
  static const String categories = '/categories';

  // History endpoints
  static const String history = '/history';

  // Predict endpoint
  static const String predict = '/predict';
}
