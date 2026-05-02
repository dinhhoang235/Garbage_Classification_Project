import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      if (response.statusCode == 200) {
        return null; // Thành công
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return e.response?.data['detail'] ?? 'Mật khẩu cũ không chính xác';
      }
      return 'Lỗi kết nối server';
    } catch (e) {
      return 'Đã xảy ra lỗi ngoài ý muốn';
    }
    return 'Lỗi không xác định';
  }

  Future<bool> deleteAccount() async {
    try {
      final response = await _apiClient.dio.delete(ApiConstants.getProfile);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('UserService.deleteAccount error: $e');
      return false;
    }
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
  Future<User?> uploadAvatar(File imageFile, {String contentType = 'image/webp'}) async {
    try {
      // 0. Nén ảnh trước khi upload sang WebP
      final File? compressedFile = await _compressAvatar(imageFile);
      final File fileToUpload = compressedFile ?? imageFile;

      // 1. Lấy presigned URL
      final urlData = await getAvatarUploadUrl(contentType: contentType);
      if (urlData == null) throw Exception('Không thể lấy upload URL');

      final uploadUrl = urlData['upload_url'] as String;
      final publicUrl = urlData['public_url'] as String;

      // 2. PUT trực tiếp lên MinIO
      final fileLength = await fileToUpload.length();
      final uploadResponse = await Dio().put(
        uploadUrl,
        data: fileToUpload.openRead(),
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: contentType,
            HttpHeaders.contentLengthHeader: fileLength,
          },
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

  Future<File?> _compressAvatar(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = "${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.webp";

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 95,
        minWidth: 512,
        minHeight: 512,
        format: CompressFormat.webp,
      );

      if (result != null) return File(result.path);
    } catch (e) {
      debugPrint('Avatar compression error: $e');
    }
    return null;
  }
}

