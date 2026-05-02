import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  /// Tìm kiếm địa điểm qua Nominatim API
  Future<List<dynamic>> searchPlaces(String query, {LatLng? biasPosition}) async {
    try {
      String url = '$_nominatimUrl?q=$query&format=json&limit=5';
      
      if (biasPosition != null) {
        url += '&lat=${biasPosition.latitude}&lon=${biasPosition.longitude}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'EcoSort-App'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Kiểm tra và lấy vị trí hiện tại
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Chuyển tọa độ thành địa chỉ (Reverse Geocoding)
  Future<String> getAddressFromLatLng(double lat, double lon) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'EcoSort-App'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Vị trí không xác định';
      }
      return 'Vị trí không xác định';
    } catch (e) {
      return 'Vị trí không xác định';
    }
  }
}
