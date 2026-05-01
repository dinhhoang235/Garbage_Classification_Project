import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import '../../models/user_model.dart';
import '../../models/achievement_model.dart';

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

  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.achievements);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Achievement.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('UserService.getAchievements error: $e');
    }
    return [];
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

  /// Bước 1: Lấy presigned PUT URL từ server
  Future<Map<String, dynamic>?> getAvatarUploadUrl({String contentType = 'image/jpeg'}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.avatarUploadUrl,
        queryParameters: {'content_type': contentType},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      debugPrint('UserService.getAvatarUploadUrl error: $e');
    }
    return null;
  }

  /// Bước 2: PUT file trực tiếp lên MinIO, Bước 3: cập nhật avatar_url về server
  /// Trả về User đã cập nhật hoặc null nếu lỗi
  Future<User?> uploadAvatar(File imageFile, {String contentType = 'image/jpeg'}) async {
    try {
      // 1. Lấy presigned URL
      final urlData = await getAvatarUploadUrl(contentType: contentType);
      if (urlData == null) throw Exception('Không thể lấy upload URL');

      final uploadUrl = urlData['upload_url'] as String;
      final publicUrl = urlData['public_url'] as String;

      // 2. Đọc file bytes
      final bytes = await imageFile.readAsBytes();

      // 3. PUT trực tiếp lên MinIO (dùng Dio riêng, không gắn JWT)
      final rawDio = Dio();
      final uploadResponse = await rawDio.put(
        uploadUrl,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: contentType,
            HttpHeaders.contentLengthHeader: bytes.length,
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Upload thất bại, status: ${uploadResponse.statusCode}');
      }

      // 4. Lưu public_url vào profile trên server
      return await updateProfile(avatarUrl: publicUrl);
    } catch (e) {
      debugPrint('UserService.uploadAvatar error: $e');
      return null;
    }
  }
}

