import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/core/auth/auth_session.dart';
import 'package:vms_frontend/core/constants/app_routes.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/auth/screens/login_screen.dart';
import 'package:vms_frontend/features/auth/services/auth_service.dart';
import 'package:vms_frontend/features/vehicles/data/mock_vehicles.dart';
import 'package:vms_frontend/features/vehicles/screens/vehicle_list_screen.dart';
import 'package:vms_frontend/shared/components/app_button.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('VMS smoke test - loads login screen without demo autofill hint', (WidgetTester tester) async {
    // Build the VMS app and trigger a frame.
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify that the login screen title and sign-in button are present.
    expect(find.text('Vehicle Management System'), findsOneWidget);
    expect(find.text('Sign In to VMS'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify demo auto-fill hint is removed
    expect(find.text('Auto-Fill'), findsNothing);
    expect(find.textContaining('Demo: admin@vms.com'), findsNothing);
  });

  testWidgets('Login screen displays clear user-friendly error for invalid credentials (401)', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'message': 'Invalid email or password.'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    });
    final authService = AuthService(httpClient: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(authService: authService),
      ),
    );
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byType(TextFormField).first, 'wrong@vms.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrongpass');

    // Tap sign in
    await tester.tap(find.text('Sign In to VMS'));
    await tester.pumpAndSettle();

    // Verify user-friendly error message is displayed
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('Login screen displays clear user-friendly error for connection failure', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      throw http.ClientException('Failed to connect to host');
    });
    final authService = AuthService(httpClient: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(authService: authService),
      ),
    );
    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(find.byType(TextFormField).first, 'admin@vms.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');

    // Tap sign in
    await tester.tap(find.text('Sign In to VMS'));
    await tester.pumpAndSettle();

    // Verify connection error message is displayed
    expect(find.textContaining('Unable to connect to the backend server'), findsOneWidget);
  });

  testWidgets('Logout action clears session and returns to login screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    AuthSession.instance.setSession(token: 'active-session-token', email: 'driver@vms.com');
    expect(AuthSession.instance.isAuthenticated, isTrue);

    final testRepo = VehicleRepository.withVehicles(mockVehicles);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.vehicles,
        routes: {
          AppRoutes.vehicles: (_) => VehicleListScreen(repository: testRepo),
          AppRoutes.login: (_) => const LoginScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    // Verify sidebar displays user name and email from AuthSession
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('driver@vms.com'), findsOneWidget);
    expect(find.text('Operator'), findsNothing);
    expect(find.text('admin@vms.com'), findsNothing);

    // Find and tap sign out button in sidebar
    expect(find.byTooltip('Sign Out'), findsOneWidget);
    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Are you sure you want to end your current session?'), findsOneWidget);

    // Confirm sign out
    await tester.tap(find.widgetWithText(AppButton, 'Sign Out'));
    await tester.pumpAndSettle();

    // Session is cleared
    expect(AuthSession.instance.isAuthenticated, isFalse);
    expect(AuthSession.instance.token, isNull);

    // User is redirected to LoginScreen
    expect(find.text('Vehicle Management System'), findsOneWidget);
    expect(find.text('Sign In to VMS'), findsOneWidget);
  });

  testWidgets('Vehicle List screen displays exact required columns', (WidgetTester tester) async {
    // Set a wide desktop window size for tests
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testRepo = VehicleRepository.withVehicles(mockVehicles);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VehicleListScreen(repository: testRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Verify headers for the required fields
    expect(find.text('VEHICLE NUMBER'), findsOneWidget);
    expect(find.text('COMPANY'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
    expect(find.text('BRAND'), findsOneWidget);
    expect(find.text('MODEL'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);

    // Verify a sample mock vehicle with the new fields is displayed
    expect(find.text('VN-1001'), findsOneWidget);
    expect(find.text('Apex Logistics'), findsWidgets);
    expect(find.text('Ford'), findsWidgets);
    expect(find.text('F-150 SuperCrew'), findsOneWidget);
  });

  testWidgets('Unauthenticated direct route generation redirects to login immediately without loading error screen', (WidgetTester tester) async {
    AuthSession.instance.clear();
    expect(AuthSession.instance.isAuthenticated, isFalse);

    // Direct navigation / reload to protected routes:
    for (final route in [AppRoutes.vehicles, AppRoutes.dashboard, AppRoutes.vehicleRegister]) {
      final generated = VmsApp.generateRoute(RouteSettings(name: route));
      expect(generated, isA<MaterialPageRoute>());
      expect(generated.settings.name, AppRoutes.login);

      final initialRoutes = VmsApp.generateInitialRoutes(route);
      expect(initialRoutes.length, 1);
      expect(initialRoutes.first.settings.name, AppRoutes.login);
    }
  });

  testWidgets('Unauthenticated VehicleListScreen redirects to login immediately without making API calls or showing error screen', (WidgetTester tester) async {
    AuthSession.instance.clear();
    expect(AuthSession.instance.isAuthenticated, isFalse);

    // If VehicleListScreen is mounted without authentication and without mock repo,
    // it redirects to Login immediately and shows no "Unable to Load Vehicles" screen.
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.vehicles,
        routes: {
          AppRoutes.vehicles: (_) => const VehicleListScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    // Must be on LoginScreen, and "Unable to Load Vehicles" error card must not be present
    expect(find.text('Vehicle Management System'), findsOneWidget);
    expect(find.text('Sign In to VMS'), findsOneWidget);
    expect(find.text('Unable to Load Vehicles'), findsNothing);
  });
}
