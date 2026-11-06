import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/mock_vehicles.dart';

/// Top overview cards displaying key fleet statistics.
class VehicleStatsCards extends StatelessWidget {
  final VehicleRepository repository;

  const VehicleStatsCards({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    final stats = [
      _StatItem(
        label: 'Total Fleet',
        value: repository.totalCount.toString(),
        icon: Icons.directions_car_outlined,
        color: AppColors.primary,
        subtitle: 'All tracked vehicles',
      ),
      _StatItem(
        label: 'Active Vehicles',
        value: repository.activeCount.toString(),
        icon: Icons.check_circle_outline,
        color: AppColors.statusActive,
        subtitle: 'On the road / available',
      ),
      _StatItem(
        label: 'In Maintenance',
        value: repository.maintenanceCount.toString(),
        icon: Icons.build_outlined,
        color: AppColors.statusMaintenance,
        subtitle: 'Service or inspection',
      ),
      _StatItem(
        label: 'Inactive / Reserved',
        value: (repository.inactiveCount + repository.reservedCount).toString(),
        icon: Icons.pause_circle_outline,
        color: AppColors.textSecondary,
        subtitle: 'Out of service / booked',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: stats
            .map((item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildCard(item),
                  ),
                ))
            .toList(),
      );
    }

    // Tablet & Mobile layout: 2-column or wrapping grid
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
              .map((item) => SizedBox(
                    width: cardWidth > 200 ? cardWidth : constraints.maxWidth,
                    child: _buildCard(item),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCard(_StatItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 20, color: item.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}
