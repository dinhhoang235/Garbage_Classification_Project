import 'package:flutter/material.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';
import '../../models/waste_category_model.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<WasteCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.categories).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (response.data as List).map((json) {
          return WasteCategory.fromJson(json);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('CategoryService.getCategories error: $e');
      return [];
    }
  }
}
