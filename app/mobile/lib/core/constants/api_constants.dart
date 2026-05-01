import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Dùng 10.0.2.2 cho Android Emulator
  // Dùng localhost hoặc 127.0.0.1 cho iOS Simulator
  // Dùng IP LAN (VD: 192.168.1.x) nếu test trên máy thật
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';

  // User endpoints
  static const String getProfile = '/users/me';

  // Categories endpoints
  static const String categories = '/categories';
}
