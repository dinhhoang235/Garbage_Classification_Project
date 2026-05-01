import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import '../../models/history_model.dart';

class HistoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<HistoryItem>> getHistory({int skip = 0, int limit = 100}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.history,
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('HistoryService.getHistory error: $e');
    }
    return [];
  }

  Future<HistoryItem?> createHistoryItem(HistoryItem item) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.history,
        data: item.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return HistoryItem.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('HistoryService.createHistoryItem error: $e');
    }
    return null;
  }
}
