import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/vehicles/data/mock_vehicles.dart';
import 'package:vms_frontend/features/vehicles/screens/vehicle_list_screen.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('VMS smoke test - loads login screen', (WidgetTester tester) async {
    // Build the VMS app and trigger a frame.
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify that the login screen title and sign-in button are present.
    expect(find.text('Vehicle Management System'), findsOneWidget);
    expect(find.text('Sign In to VMS'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
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
}
