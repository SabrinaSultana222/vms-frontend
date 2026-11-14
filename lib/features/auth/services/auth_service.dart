import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_session.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';

/// Service responsible for authenticating with the Spring Boot backend.
class AuthService {
  final http.Client _httpClient;
  final String _baseUrl;
  final AuthSession _session;

  AuthService({
    http.Client? httpClient,
    String? baseUrl,
    AuthSession? session,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.normalizedBaseUrl,
        _session = session ?? AuthSession.instance;

  /// In-memory session reference.
  AuthSession get session => _session;

  /// Authenticates using the Spring Boot `/api/auth/login` endpoint.
  ///
  /// Sends POST with JSON {"email": email, "password": password}.
  /// On success (200), stores {"token", "email"} strictly in memory via [AuthSession].
  /// On 401 invalid credentials, throws [ApiException] containing the backend message.
  /// On connection failure, throws [ApiException] network error.
  Future<void> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.authLoginPath}');
    final requestBody = jsonEncode({
      'email': email,
      'password': password,
    });

    http.Response response;
    try {
      response = await _httpClient.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
    } catch (e) {
      throw ApiException.networkError(e);
    }

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final token = decoded['token'] as String?;
          final returnedEmail = decoded['email'] as String? ?? email;
          final returnedName = decoded['userName'] as String? ??
              decoded['name'] as String? ??
              decoded['username'] as String?;

          if (token != null && token.isNotEmpty) {
            _session.setSession(
              token: token,
              email: returnedEmail,
              userName: returnedName,
            );
            return;
          }
        }
        throw const ApiException(
          statusCode: 200,
          message: 'Invalid response from server. Missing authentication token.',
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          statusCode: 200,
          message: 'Failed to process server response.',
          error: e.toString(),
        );
      }
    }

    if (response.statusCode == 401) {
      String errorMessage = 'Invalid email or password.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          final msg = decoded['message'].toString().trim();
          if (msg.isNotEmpty) {
            errorMessage = msg;
          }
        }
      } catch (_) {
        // Fallback to default invalid credentials message
      }

      throw ApiException(
        statusCode: 401,
        message: errorMessage,
      );
    }

    throw ApiException.fromResponseBody(response.statusCode, response.body);
  }

  /// Logs out the user by clearing the in-memory session.
  void logout() {
    _session.clear();
  }
}
