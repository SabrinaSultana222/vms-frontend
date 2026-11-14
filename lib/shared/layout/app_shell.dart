import 'package:flutter/material.dart';
import '../../core/auth/auth_session.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/vehicles/data/vehicle_repository.dart';
import '../components/confirmation_dialog.dart';

/// Desktop-first application shell providing persistent sidebar navigation,
/// header bar, user profile, and responsive layout handling.
class AppShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Fixed desktop sidebar
            _DesktopSidebar(currentRoute: currentRoute),

            // Main content area with header
            Expanded(
              child: Column(
                children: [
                  _TopHeaderBar(
                    title: title,
                    actions: actions,
                    showMenuButton: false,
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  Expanded(
                    child: SelectionArea(
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tablet & Mobile layout: Top AppBar + Drawer fallback
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopHeaderBar(
          title: title,
          actions: actions,
          showMenuButton: true,
        ),
      ),
      drawer: _MobileDrawer(currentRoute: currentRoute),
      body: SelectionArea(
        child: child,
      ),
    );
  }
}

/// Desktop sidebar navigation panel.
class _DesktopSidebar extends StatelessWidget {
  final String currentRoute;

  const _DesktopSidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Fleet Platform',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Navigation Links
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: currentRoute == AppRoutes.dashboard,
            onTap: () => _navigate(context, AppRoutes.dashboard),
          ),
          _SidebarItem(
            icon: Icons.directions_car_outlined,
            activeIcon: Icons.directions_car_filled,
            label: 'Vehicles',
            isSelected: currentRoute == AppRoutes.vehicles ||
                currentRoute == AppRoutes.vehicleRegister ||
                currentRoute == AppRoutes.vehicleEdit,
            onTap: () => _navigate(context, AppRoutes.vehicles),
          ),
          _SidebarItem(
            icon: Icons.build_outlined,
            activeIcon: Icons.build,
            label: 'Maintenance',
            isSelected: false,
            badge: 'Demo',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maintenance module will connect to Spring Boot backend in future sprint.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _SidebarItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Reports & Logs',
            isSelected: false,
            badge: 'Mock',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reports module is a planned feature.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const Spacer(),

          // System info & User Profile footer
          const Divider(height: 1, color: AppColors.border),
          ListenableBuilder(
            listenable: AuthSession.instance,
            builder: (context, _) {
              final userEmail = AuthSession.instance.email ?? '';
              final userName = AuthSession.instance.userName ?? 'User';
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _userInitials(userEmail, userName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userEmail.isNotEmpty)
                            Text(
                              userEmail,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                      tooltip: 'Sign Out',
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _userInitials(String? email, [String? name]) {
    if (name != null && name.trim().isNotEmpty && name.trim() != 'User') {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
    }
    if (email == null || email.trim().isEmpty) return 'U';
    final parts = email.split('@').first.split(RegExp(r'[._\-]'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _navigate(BuildContext context, String route) {
    if (currentRoute != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to end your current session?',
      confirmLabel: 'Sign Out',
    );
    if (confirmed == true && context.mounted) {
      AuthSession.instance.clear();
      VehicleRepository.instance.clear();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
    }
  }
}

/// Navigation item inside the sidebar.
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFFF1F5F9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top Header Bar for Desktop and Mobile.
class _TopHeaderBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenuButton;

  const _TopHeaderBar({
    required this.title,
    this.actions,
    required this.showMenuButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.surface,
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          ...?actions,
          const SizedBox(width: 12),
          // Demo notifications bell
          IconButton(
            icon: const Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_none_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new alerts. Fleet status normal.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Chip with backend indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 14, color: AppColors.secondary),
                SizedBox(width: 4),
                Text(
                  'Live API',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawer fallback for mobile and compact tablet screens.
class _MobileDrawer extends StatelessWidget {
  final String currentRoute;

  const _MobileDrawer({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: currentRoute == AppRoutes.dashboard,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Vehicles'),
              selected: currentRoute == AppRoutes.vehicles,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.vehicles);
              },
            ),
            const Spacer(),
            if (AuthSession.instance.isAuthenticated) ...[
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _DesktopSidebar._userInitials(
                      AuthSession.instance.email,
                      AuthSession.instance.userName,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  AuthSession.instance.userName ?? 'User',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: AuthSession.instance.email != null && AuthSession.instance.email!.isNotEmpty
                    ? Text(AuthSession.instance.email!, style: const TextStyle(fontSize: 12))
                    : null,
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.statusInactive),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.statusInactive)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to end your current session?',
                  confirmLabel: 'Sign Out',
                );
                if (confirmed == true && context.mounted) {
                  AuthSession.instance.clear();
                  VehicleRepository.instance.clear();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
