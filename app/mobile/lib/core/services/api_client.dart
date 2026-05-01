import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Tự động lấy token từ storage và gắn vào Header Authorization
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Xử lý refresh token khi bị lỗi 401 (Unauthorized)
        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              // Gọi API refresh token
              final response = await dio.post(ApiConstants.refreshToken, data: {
                'refresh_token': refreshToken,
              });

              final newAccessToken = response.data['access_token'];
              await storage.write(key: 'access_token', value: newAccessToken);

              // Thử gọi lại API vừa bị lỗi với token mới
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (refreshError) {
              // Nếu refresh token cũng lỗi thì xóa hết token (bắt đăng nhập lại)
              await storage.deleteAll();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}
