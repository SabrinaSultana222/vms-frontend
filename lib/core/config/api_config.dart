/// Configuration constants for the VMS REST API.
class ApiConfig {
  ApiConfig._();

  /// The base URL for the backend API, configurable at compile time via:
  /// `--dart-define=API_BASE_URL=http://your-host:port`
  /// Defaults to `http://localhost:8080`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Path for the vehicle resources.
  static const String vehiclesPath = '/api/vehicles';

  /// Path for the auth login endpoint.
  static const String authLoginPath = '/api/auth/login';

  /// Returns the base URL stripped of any trailing slash.
  static String get normalizedBaseUrl {
    if (baseUrl.endsWith('/')) {
      return baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  /// Full URI string for `/api/vehicles`.
  static String get vehiclesUri => '$normalizedBaseUrl$vehiclesPath';

  /// Full URI string for `/api/vehicles/{id}`.
  static String vehicleUri(String id) => '$normalizedBaseUrl$vehiclesPath/$id';

  /// Full URI string for `/api/auth/login`.
  static String get authLoginUri => '$normalizedBaseUrl$authLoginPath';
}
