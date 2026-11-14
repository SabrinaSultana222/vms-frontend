import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/core/auth/auth_session.dart';
import 'package:vms_frontend/core/network/api_client.dart';
import 'package:vms_frontend/core/network/api_exception.dart';
import 'package:vms_frontend/features/auth/services/auth_service.dart';
import 'package:vms_frontend/features/vehicles/models/vehicle.dart';

void main() {
  group('AuthSession (In-Memory)', () {
    late AuthSession session;

    setUp(() {
      session = AuthSession();
    });

    test('initial state is unauthenticated', () {
      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
      expect(session.email, isNull);
    });

    test('setSession stores token and email in-memory only', () {
      session.setSession(token: 'jwt-xyz-123', email: 'test@vms.com');
      expect(session.isAuthenticated, isTrue);
      expect(session.token, 'jwt-xyz-123');
      expect(session.email, 'test@vms.com');
      expect(session.userName, 'Test');
    });

    test('userName derives formatted name from email and supports explicit userName', () {
      session.setSession(token: 't1', email: 'john.doe@vms.com');
      expect(session.userName, 'John Doe');

      session.setSession(token: 't2', email: 'fleet_admin@vms.com');
      expect(session.userName, 'Fleet Admin');

      session.setSession(token: 't3', email: 'custom@vms.com', userName: 'Super Admin');
      expect(session.userName, 'Super Admin');
      expect(session.name, 'Super Admin');
    });

    test('clear resets token, email, and userName in-memory', () {
      session.setSession(token: 'jwt-xyz-123', email: 'test@vms.com', userName: 'Custom');
      session.clear();
      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
      expect(session.email, isNull);
      expect(session.userName, isNull);
    });

    test('toString never reveals the token', () {
      session.setSession(token: 'super-secret-jwt-token', email: 'test@vms.com');
      expect(session.toString(), isNot(contains('super-secret-jwt-token')));
      expect(session.toString(), contains('test@vms.com'));
    });

    test('handleUnauthorized clears session and fires onUnauthorized callback', () {
      var callbackFired = false;
      session.onUnauthorized = () => callbackFired = true;
      session.setSession(token: 'jwt-xyz-123', email: 'test@vms.com');

      session.handleUnauthorized();

      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
      expect(callbackFired, isTrue);
    });
  });

  group('AuthService', () {
    test('login success (200) stores token and email in session', () async {
      final session = AuthSession();
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'admin@vms.com');
        expect(body['password'], 'secret123');

        return http.Response(
          jsonEncode({
            'token': 'jwt-sample-token-456',
            'email': 'admin@vms.com',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        httpClient: mockClient,
        session: session,
      );

      await authService.login('admin@vms.com', 'secret123');

      expect(session.isAuthenticated, isTrue);
      expect(session.token, 'jwt-sample-token-456');
      expect(session.email, 'admin@vms.com');
    });

    test('login 401 throws ApiException with backend message', () async {
      final session = AuthSession();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Bad credentials. Please check your password.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(
        httpClient: mockClient,
        session: session,
      );

      expect(
        () => authService.login('admin@vms.com', 'wrongpassword'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Bad credentials. Please check your password.'),
        ),
      );
      expect(session.isAuthenticated, isFalse);
    });

    test('login connection failure throws ApiException networkError', () async {
      final session = AuthSession();
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final authService = AuthService(
        httpClient: mockClient,
        session: session,
      );

      expect(
        () => authService.login('admin@vms.com', 'admin'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.message, 'message', contains('Unable to connect to the backend server')),
        ),
      );
    });

    test('logout clears the session', () {
      final session = AuthSession();
      session.setSession(token: 'token-123', email: 'user@vms.com');
      final authService = AuthService(session: session);

      authService.logout();

      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
    });
  });

  group('VehicleApiClient Authorization & 401 handling', () {
    const sampleVehicleJson = {
      'id': 1,
      'vehicleNumber': 'DHK-11-2233',
      'company': 'Acme Corp',
      'type': 'Truck',
      'brand': 'Volvo',
      'model': 'FH16',
      'status': 'Active',
    };

    test('attaches Authorization: Bearer <token> to vehicle requests', () async {
      final session = AuthSession();
      session.setSession(token: 'my-secret-jwt', email: 'admin@vms.com');

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer my-secret-jwt');
        return http.Response(jsonEncode([sampleVehicleJson]), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = VehicleApiClient(httpClient: mockClient, session: session);
      final list = await apiClient.getVehicles();

      expect(list.length, 1);
    });

    test('when vehicle request returns 401, clears session and triggers onUnauthorized', () async {
      final session = AuthSession();
      session.setSession(token: 'expired-jwt', email: 'admin@vms.com');

      var unauthorizedRedirectTriggered = false;
      session.onUnauthorized = () {
        unauthorizedRedirectTriggered = true;
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Full authentication is required to access this resource'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(httpClient: mockClient, session: session);

      await expectLater(
        apiClient.getVehicles(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
      expect(unauthorizedRedirectTriggered, isTrue);
    });

    test('createVehicle includes Authorization header and handles 401', () async {
      final session = AuthSession();
      session.setSession(token: 'token-post', email: 'admin@vms.com');

      var unauthorizedCalled = false;
      session.onUnauthorized = () => unauthorizedCalled = true;

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token-post');
        return http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(httpClient: mockClient, session: session);
      const toCreate = Vehicle(
        vehicleNumber: 'VN-1',
        company: 'Acme',
        type: 'Van',
        brand: 'Ford',
        model: 'Transit',
        status: 'Active',
      );

      await expectLater(
        apiClient.createVehicle(toCreate),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      expect(session.isAuthenticated, isFalse);
      expect(unauthorizedCalled, isTrue);
    });
  });
}
