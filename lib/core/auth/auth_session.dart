import 'package:flutter/foundation.dart';

/// In-memory session holder for authentication state.
///
/// Keeps the JWT token and user info strictly in memory.
/// Never persists the token or password to localStorage, shared preferences, or logs.
class AuthSession extends ChangeNotifier {
  static final AuthSession instance = AuthSession();

  String? _token;
  String? _email;
  String? _userName;

  /// Callback triggered when an unauthorized (HTTP 401) response is received.
  VoidCallback? onUnauthorized;

  /// Returns the current in-memory token, or null if not authenticated.
  String? get token => _token;

  /// Returns the authenticated user's email, or null if not authenticated.
  String? get email => _email;

  /// Returns the authenticated user's display name or username.
  /// If no explicit name was provided, derives a formatted display name from [email].
  String? get userName {
    if (_userName != null && _userName!.trim().isNotEmpty) {
      return _userName!.trim();
    }
    if (_email != null && _email!.trim().isNotEmpty) {
      return _deriveUserName(_email!);
    }
    return null;
  }

  /// Alias for [userName].
  String? get name => userName;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Saves the authenticated session strictly in memory.
  void setSession({
    required String token,
    required String email,
    String? userName,
  }) {
    _token = token;
    _email = email;
    _userName = userName;
    notifyListeners();
  }

  /// Clears the in-memory session (used on logout and session expiration).
  void clear() {
    _token = null;
    _email = null;
    _userName = null;
    notifyListeners();
  }

  /// Invoked when a 401 Unauthorized status is received from any vehicle endpoint.
  /// Clears session in memory and triggers [onUnauthorized] redirect.
  void handleUnauthorized() {
    clear();
    onUnauthorized?.call();
  }

  /// Derives a clean display name from an email address (e.g. "john.doe@vms.com" -> "John Doe").
  static String? _deriveUserName(String email) {
    final prefix = email.split('@').first.trim();
    if (prefix.isEmpty) return null;
    final parts = prefix.split(RegExp(r'[._\-]'));
    final formatted = parts
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
    return formatted.isNotEmpty ? formatted : prefix;
  }

  @override
  String toString() => 'AuthSession(isAuthenticated: $isAuthenticated, email: $_email, userName: $userName)';
}
