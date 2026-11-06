import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/layout/app_shell.dart';
import '../../../shared/layout/responsive_layout.dart';
import '../../vehicles/data/mock_vehicles.dart';
import '../../vehicles/models/vehicle.dart';
import '../../vehicles/widgets/vehicle_stats_cards.dart';
import '../../vehicles/widgets/vehicle_status_badge.dart';

/// High-level fleet overview dashboard screen.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = VehicleRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final recentVehicles = _repository.vehicles.take(5).toList();

    return AppShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Fleet Operations Dashboard',
      actions: [
        AppButton(
          label: 'Register Vehicle',
          icon: Icons.add,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.vehicleRegister),
        ),
      ],
      child: SingleChildScrollView(
        child: ResponsiveContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              _buildWelcomeBanner(context),
              const SizedBox(height: 24),

              // KPI Statistics Cards
              VehicleStatsCards(repository: _repository),
              const SizedBox(height: 24),

              // Main grid: Recent vehicles & Quick system cards
              Responsive(
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildRecentVehiclesCard(recentVehicles),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildQuickActionsAndBackendStatus(),
                    ),
                  ],
                ),
                mobile: Column(
                  children: [
                    _buildRecentVehiclesCard(recentVehicles),
                    const SizedBox(height: 20),
                    _buildQuickActionsAndBackendStatus(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to VMS Admin Portal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage vehicle inventory, inspect service records, and allocate fleet resources across departments.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AppButton(
            label: 'View All Vehicles',
            isOutlined: true,
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicles),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentVehiclesCard(List<Vehicle> vehicles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recently Added Fleet Vehicles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.vehicles),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vehicles.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(v.type.icon, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v.brand} ${v.model}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'No: ${v.vehicleNumber} • Company: ${v.company}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    VehicleStatusBadge(status: v.status),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsAndBackendStatus() {
    return Column(
      children: [
        // Quick Actions Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'Register New Vehicle',
                  subtitle: 'Add a car, truck, or van to fleet inventory',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.vehicleRegister),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  icon: Icons.filter_list,
                  title: 'Filter Active Fleet',
                  subtitle: 'Explore ready-to-dispatch vehicles',
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.vehicles),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Spring Boot Backend Integration Notes
        Card(
          color: const Color(0xFFF0FDF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_outlined, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Spring Boot Integration Ready',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The models (Vehicle, VehicleStatus, VehicleType) include toJson/fromJson stubs for Vehicle Number, Company, Type, Brand, Model, and Status. Once the Spring Boot API is available, replace the VehicleRepository with an HTTP client.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
