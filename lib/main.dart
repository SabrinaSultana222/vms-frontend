import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/vehicles/models/vehicle.dart';
import 'features/vehicles/screens/vehicle_form_screen.dart';
import 'features/vehicles/screens/vehicle_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VmsApp());
}

/// Root widget for the Vehicle Management System frontend application.
class VmsApp extends StatelessWidget {
  const VmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.login:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: settings,
            );

          case AppRoutes.dashboard:
            return MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
              settings: settings,
            );

          case AppRoutes.vehicles:
            return MaterialPageRoute(
              builder: (_) => const VehicleListScreen(),
              settings: settings,
            );

          case AppRoutes.vehicleRegister:
            return MaterialPageRoute(
              builder: (_) => const VehicleFormScreen(),
              settings: settings,
            );

          case AppRoutes.vehicleEdit:
            final vehicle = settings.arguments as Vehicle?;
            return MaterialPageRoute(
              builder: (_) => VehicleFormScreen(initialVehicle: vehicle),
              settings: settings,
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}
