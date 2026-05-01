import 'package:dio/dio.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> login(String username, String password) async {
    try {
      // API Login thường dùng FormData cho OAuth2 Password Request Form
      // Hoặc dùng JSON data. Ở đây giả định dùng JSON data hoặc FormData tùy server của bạn.
      // Trong FastAPI mặc định OAuth2PasswordRequestForm dùng application/x-www-form-urlencoded
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'];
        // Tùy API của bạn có trả về refresh_token không
        final refreshToken = response.data['refresh_token'] ?? ''; 

        // Lưu lại token
        await _apiClient.storage.write(key: 'access_token', value: accessToken);
        if (refreshToken.isNotEmpty) {
          await _apiClient.storage.write(key: 'refresh_token', value: refreshToken);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.storage.read(key: 'access_token');
    return token != null;
  }
}
