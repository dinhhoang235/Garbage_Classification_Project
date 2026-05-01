import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import '../../models/predict_result_model.dart';

class PredictService {
  final ApiClient _apiClient = ApiClient();

  Future<PredictResult?> predict(File imageFile) async {
    try {
      final mimeType = _getMimeType(imageFile.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.predict,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        return PredictResult.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('PredictService.predict error: $e');
    }
    return null;
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
