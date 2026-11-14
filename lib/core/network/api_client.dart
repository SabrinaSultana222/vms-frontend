import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_session.dart';
import '../config/api_config.dart';
import '../../features/vehicles/models/vehicle.dart';
import 'api_exception.dart';

/// Clean HTTP API client for interacting with the Spring Boot VMS backend.
///
/// Uses exactly these endpoints:
/// - GET /api/vehicles (list)
/// - GET /api/vehicles/{id}
/// - POST /api/vehicles (create, returns 201)
/// - PUT /api/vehicles/{id} (update, returns 200)
/// - DELETE /api/vehicles/{id} (delete, returns 204)
///
/// Attaches `Authorization: Bearer <token>` to every request when a session exists.
/// If any vehicle request returns 401, clears the session and triggers unauthorized redirection.
class VehicleApiClient {
  final http.Client _httpClient;
  final String _baseUrl;
  final AuthSession _session;

  VehicleApiClient({
    http.Client? httpClient,
    String? baseUrl,
    AuthSession? session,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.normalizedBaseUrl,
        _session = session ?? AuthSession.instance;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _session.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      _session.handleUnauthorized();
    }
  }

  /// GET /api/vehicles
  ///
  /// Retrieves all vehicles.
  Future<List<Vehicle>> getVehicles() async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.vehiclesPath}');
    try {
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      }

      _checkUnauthorized(response);
      throw ApiException.fromResponseBody(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  /// GET /api/vehicles/{id}
  ///
  /// Retrieves a single vehicle by its [id].
  Future<Vehicle> getVehicleById(String id) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.vehiclesPath}/$id');
    try {
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      }

      _checkUnauthorized(response);
      throw ApiException.fromResponseBody(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  /// POST /api/vehicles
  ///
  /// Creates a new vehicle. Expects 201 Created from backend.
  /// Throws [ApiException] with backend message on 400 (validation) or 409 (duplicate).
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.vehiclesPath}');
    final bodyJson = jsonEncode(vehicle.toRequestBody());

    try {
      final response = await _httpClient.post(
        uri,
        headers: _headers,
        body: bodyJson,
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      }

      _checkUnauthorized(response);
      throw ApiException.fromResponseBody(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  /// PUT /api/vehicles/{id}
  ///
  /// Updates an existing vehicle. Expects 200 OK from backend.
  /// Throws [ApiException] with backend message on 400 (validation), 404 (not found), or 409 (duplicate).
  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.vehiclesPath}/$id');
    final bodyJson = jsonEncode(vehicle.toRequestBody());

    try {
      final response = await _httpClient.put(
        uri,
        headers: _headers,
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      }

      _checkUnauthorized(response);
      throw ApiException.fromResponseBody(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }

  /// DELETE /api/vehicles/{id}
  ///
  /// Deletes a vehicle by its [id]. Expects 204 No Content from backend.
  Future<void> deleteVehicle(String id) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.vehiclesPath}/$id');

    try {
      final response = await _httpClient.delete(uri, headers: _headers);

      if (response.statusCode == 204) {
        return;
      }

      _checkUnauthorized(response);
      throw ApiException.fromResponseBody(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.networkError(e);
    }
  }
}
