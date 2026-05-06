import '../constants/api_constants.dart';

/// Builds a full image URL from a relative path returned by the backend.
///
/// The backend returns relative paths like `/garbage-images/uuid.jpg` or `/avatars/user_1/uuid.jpg`
/// This function constructs the full URL by combining with the API base URL.
String buildImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return '';
  }

  // If it's already a full URL, return as is
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }

  // Ensure the path starts with /
  final normalizedPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';

  // Combine base URL with the image path
  final baseUrl = ApiConstants.baseUrl.replaceAll(
    RegExp(r'/$'),
    '',
  ); // Remove trailing slash
  return '$baseUrl$normalizedPath';
}
