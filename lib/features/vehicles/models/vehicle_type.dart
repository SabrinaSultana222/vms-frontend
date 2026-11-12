import 'package:flutter/material.dart';

/// Categories of fleet vehicles.
enum VehicleType {
  truck('Truck'),
  sedan('Sedan'),
  suv('SUV'),
  van('Van'),
  electric('Electric');

  /// Display label and backend representation string.
  final String label;

  const VehicleType(this.label);

  /// Dropdown values formatted as plain strings matching backend values.
  static const List<String> dropdownValues = [
    'Truck',
    'Sedan',
    'SUV',
    'Van',
    'Electric',
  ];

  /// Icon representing the vehicle category.
  IconData get icon => iconFor(label);

  /// Resolves an appropriate icon for any free-text vehicle type string.
  static IconData iconFor(String? typeName) {
    if (typeName == null) return Icons.directions_car_filled_outlined;
    final lower = typeName.toLowerCase();
    if (lower.contains('truck')) {
      return Icons.local_shipping_outlined;
    } else if (lower.contains('suv')) {
      return Icons.directions_car_outlined;
    } else if (lower.contains('van')) {
      return Icons.airport_shuttle_outlined;
    } else if (lower.contains('electric') || lower.contains('ev')) {
      return Icons.electric_car_outlined;
    }
    return Icons.directions_car_filled_outlined;
  }

  /// Parses a free-text string into a [VehicleType] enum, falling back to [VehicleType.truck].
  static VehicleType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return VehicleType.truck;
    final clean = value.trim().toLowerCase();
    for (final t in VehicleType.values) {
      if (t.name.toLowerCase() == clean || t.label.toLowerCase() == clean) {
        return t;
      }
    }
    if (clean.contains('truck')) return VehicleType.truck;
    if (clean.contains('sedan')) return VehicleType.sedan;
    if (clean.contains('suv')) return VehicleType.suv;
    if (clean.contains('van')) return VehicleType.van;
    if (clean.contains('electric') || clean.contains('ev')) return VehicleType.electric;
    return VehicleType.truck;
  }
}
