import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Represents the operational status of a fleet vehicle.
enum VehicleStatus {
  active,
  maintenance,
  inactive,
  reserved;

  /// User-friendly display label.
  String get label {
    switch (this) {
      case VehicleStatus.active:
        return 'Active';
      case VehicleStatus.maintenance:
        return 'In Maintenance';
      case VehicleStatus.inactive:
        return 'Inactive';
      case VehicleStatus.reserved:
        return 'Reserved';
    }
  }

  /// Foreground / text / border color for status indicator.
  Color get color {
    switch (this) {
      case VehicleStatus.active:
        return AppColors.statusActive;
      case VehicleStatus.maintenance:
        return AppColors.statusMaintenance;
      case VehicleStatus.inactive:
        return AppColors.statusInactive;
      case VehicleStatus.reserved:
        return AppColors.statusReserved;
    }
  }

  /// Soft background color for badge or chip.
  Color get backgroundColor {
    switch (this) {
      case VehicleStatus.active:
        return AppColors.statusActiveBg;
      case VehicleStatus.maintenance:
        return AppColors.statusMaintenanceBg;
      case VehicleStatus.inactive:
        return AppColors.statusInactiveBg;
      case VehicleStatus.reserved:
        return AppColors.statusReservedBg;
    }
  }

  /// Parses a string into a [VehicleStatus] enum, falling back to [VehicleStatus.active].
  static VehicleStatus fromString(String? value) {
    if (value == null) return VehicleStatus.active;
    return VehicleStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VehicleStatus.active,
    );
  }
}
