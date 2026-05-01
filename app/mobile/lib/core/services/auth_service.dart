import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  /// Login with phone number and password.
  /// Returns true if login succeeded and tokens are stored.
  Future<bool> login(String phoneNumber, String password) async {
    try {
      // FastAPI OAuth2PasswordRequestForm expects form data
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: FormData.fromMap({
          'username': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'] ?? '';

        await _apiClient.storage.write(key: 'access_token', value: accessToken);
        if (refreshToken.isNotEmpty) {
          await _apiClient.storage.write(key: 'refresh_token', value: refreshToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthService.login error: $e');
      return false;
    }
  }

  /// Register a new user account.
  /// Returns true if registration succeeded.
  Future<bool> register({
    required String name,
    required String phoneNumber,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'password': password,
          'avatar_url': avatarUrl,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('AuthService.register error: $e');
      return false;
    }
  }

  /// Clear all stored tokens (logout).
  Future<void> logout() async {
    await _apiClient.storage.deleteAll();
  }

  /// Check if an access token is stored.
  Future<bool> isLoggedIn() async {
    final token = await _apiClient.storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }
}
