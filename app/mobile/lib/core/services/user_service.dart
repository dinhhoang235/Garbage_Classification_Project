import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import '../../models/user_model.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<User?> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.getProfile);
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('UserService.getProfile error: $e');
    }
    return null;
  }

  Future<User?> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      final response = await _apiClient.dio.put(ApiConstants.getProfile, data: data);
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('UserService.updateProfile error: $e');
    }
    return null;
  }
}
