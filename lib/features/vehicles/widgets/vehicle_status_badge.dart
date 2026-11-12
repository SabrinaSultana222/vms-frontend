import 'package:flutter/material.dart';
import '../models/vehicle_status.dart';

/// Pill-style badge component indicating vehicle operational status.
class VehicleStatusBadge extends StatelessWidget {
  final String status;

  const VehicleStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = VehicleStatus.colorFor(status);
    final statusBgColor = VehicleStatus.backgroundColorFor(status);
    final statusEnum = VehicleStatus.fromString(status);
    final displayLabel = status.trim().isNotEmpty ? status : statusEnum.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
