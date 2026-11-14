import 'package:flutter/material.dart';
import 'core/auth/auth_session.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/vehicles/models/vehicle.dart';
import 'features/vehicles/screens/vehicle_form_screen.dart';
import 'features/vehicles/screens/vehicle_list_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthSession.instance.onUnauthorized = () {
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  };
  runApp(const VmsApp());
}

/// Root widget for the Vehicle Management System frontend application.
class VmsApp extends StatelessWidget {
  const VmsApp({super.key});

  /// Centralized route generator with authentication guard.
  /// When [AuthSession] has no token, redirects to [LoginScreen] immediately.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (!AuthSession.instance.isAuthenticated && settings.name != AppRoutes.login) {
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: const RouteSettings(name: AppRoutes.login),
      );
    }

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
          settings: const RouteSettings(name: AppRoutes.login),
        );
    }
  }

  /// Generates initial routes with authentication guard.
  /// When [AuthSession] has no token, returns a single route to [LoginScreen].
  static List<Route<dynamic>> generateInitialRoutes(String initialRoute) {
    if (!AuthSession.instance.isAuthenticated) {
      return [
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: const RouteSettings(name: AppRoutes.login),
        ),
      ];
    }
    return [
      generateRoute(RouteSettings(name: initialRoute)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    AuthSession.instance.onUnauthorized ??= () {
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    };

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateInitialRoutes: generateInitialRoutes,
      onGenerateRoute: generateRoute,
    );
  }
}
