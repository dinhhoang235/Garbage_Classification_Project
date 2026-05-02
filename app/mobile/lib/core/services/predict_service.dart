import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/api_constants.dart';
import 'api_client.dart';
import '../../models/predict_result_model.dart';

class PredictService {
  final ApiClient _apiClient = ApiClient();

  Future<PredictResult?> predict(File imageFile) async {
    try {
      // Step 1: Compress image before uploading
      final File? compressedFile = await _compressImage(imageFile);
      final File fileToUpload = compressedFile ?? imageFile;

      final mimeType = _getMimeType(fileToUpload.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          fileToUpload.path,
          contentType: DioMediaType.parse(mimeType),
          filename: p.basename(fileToUpload.path),
        ),
      });

      debugPrint('Uploading image: ${fileToUpload.path} (Size: ${await fileToUpload.length()} bytes)');

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

  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "temp_${DateTime.now().millisecondsSinceEpoch}.webp");

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 95,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.webp,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      debugPrint('Compression error: $e');
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
