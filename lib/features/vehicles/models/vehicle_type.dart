import 'package:flutter/material.dart';

/// Categories of fleet vehicles.
enum VehicleType {
  sedan,
  suv,
  truck,
  van,
  electric;

  /// User-friendly display label.
  String get label {
    switch (this) {
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.van:
        return 'Cargo Van';
      case VehicleType.electric:
        return 'Electric (EV)';
    }
  }

  /// Icon representing the vehicle category.
  IconData get icon {
    switch (this) {
      case VehicleType.sedan:
        return Icons.directions_car_filled_outlined;
      case VehicleType.suv:
        return Icons.directions_car_outlined;
      case VehicleType.truck:
        return Icons.local_shipping_outlined;
      case VehicleType.van:
        return Icons.airport_shuttle_outlined;
      case VehicleType.electric:
        return Icons.electric_car_outlined;
    }
  }

  /// Parses a string into a [VehicleType] enum, falling back to [VehicleType.sedan].
  static VehicleType fromString(String? value) {
    if (value == null) return VehicleType.sedan;
    return VehicleType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VehicleType.sedan,
    );
  }
}
