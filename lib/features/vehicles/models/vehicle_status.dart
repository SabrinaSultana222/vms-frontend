import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Represents the operational status of a fleet vehicle.
enum VehicleStatus {
  active('Active'),
  maintenance('Maintenance'),
  inactive('Inactive'),
  reserved('Reserved');

  /// Display label and backend representation string.
  final String label;

  const VehicleStatus(this.label);

  /// Dropdown values formatted as plain strings matching backend values.
  static const List<String> dropdownValues = [
    'Active',
    'Maintenance',
    'Inactive',
    'Reserved',
  ];

  /// Foreground / text / border color for status indicator.
  Color get color => colorFor(label);

  /// Soft background color for badge or chip.
  Color get backgroundColor => backgroundColorFor(label);

  /// Resolves the indicator color for any free-text status string.
  static Color colorFor(String? statusName) {
    final s = fromString(statusName);
    switch (s) {
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

  /// Resolves the soft badge background color for any free-text status string.
  static Color backgroundColorFor(String? statusName) {
    final s = fromString(statusName);
    switch (s) {
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

  /// Parses a free-text string into a [VehicleStatus] enum, falling back to [VehicleStatus.active].
  static VehicleStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return VehicleStatus.active;
    final clean = value.trim().toLowerCase();
    for (final s in VehicleStatus.values) {
      if (s.name.toLowerCase() == clean || s.label.toLowerCase() == clean) {
        return s;
      }
    }
    if (clean.contains('active')) return VehicleStatus.active;
    if (clean.contains('maint')) return VehicleStatus.maintenance;
    if (clean.contains('inact')) return VehicleStatus.inactive;
    if (clean.contains('reserv')) return VehicleStatus.reserved;
    return VehicleStatus.active;
  }
}
