import 'dart:convert';
import '../config/api_config.dart';

/// Exception thrown when an API request fails.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? error;
  final String? path;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.error,
    this.path,
  });

  /// Creates an [ApiException] by parsing a Spring Boot error JSON response.
  ///
  /// Expected backend schema:
  /// ```json
  /// {
  ///   "status": 400 | 404 | 409 | 500,
  ///   "error": "Bad Request",
  ///   "message": "vehicleNumber: Vehicle number is required",
  ///   "path": "/api/vehicles",
  ///   "timestamp": "2026-11-12T08:10:28Z"
  /// }
  /// ```
  factory ApiException.fromResponseBody(int statusCode, String body) {
    if (body.trim().isEmpty) {
      return ApiException(
        statusCode: statusCode,
        message: _defaultMessageForStatusCode(statusCode),
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] as String?;
        final error = decoded['error'] as String?;
        final path = decoded['path'] as String?;

        return ApiException(
          statusCode: statusCode,
          message: (message != null && message.trim().isNotEmpty)
              ? message
              : _defaultMessageForStatusCode(statusCode),
          error: error,
          path: path,
        );
      }
    } catch (_) {
      // Body was not valid JSON
    }

    return ApiException(
      statusCode: statusCode,
      message: _defaultMessageForStatusCode(statusCode),
    );
  }

  /// Creates an [ApiException] representing a network connection error.
  factory ApiException.networkError([dynamic cause]) {
    return ApiException(
      statusCode: 0,
      message:
          'Unable to connect to the backend server. Please check your network connection and ensure the Spring Boot API is running at ${ApiConfig.baseUrl}.',
      error: cause?.toString(),
    );
  }

  static String _defaultMessageForStatusCode(int code) {
    switch (code) {
      case 400:
        return 'Invalid vehicle data provided. Please check the required fields.';
      case 401:
        return 'Unauthorized. Please sign in to continue.';
      case 404:
        return 'The requested vehicle was not found.';
      case 409:
        return 'A vehicle with this vehicle number already exists.';
      case 500:
        return 'A server error occurred. Please try again later.';
      default:
        return 'Request failed with status code $code.';
    }
  }

  @override
  String toString() => message;
}
