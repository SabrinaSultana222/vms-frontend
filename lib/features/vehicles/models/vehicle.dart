import 'vehicle_status.dart';
import 'vehicle_type.dart';

/// Data model representing a vehicle in the Vehicle Management System.
///
/// Fields: id, vehicleNumber, company, type, brand, model, status.
class Vehicle {
  final String? id;
  final String vehicleNumber;
  final String company;
  final String type;
  final String brand;
  final String model;
  final String status;

  const Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  });

  /// Convenient display name (e.g. "Toyota Camry (VN-1001)")
  String get displayName => '$brand $model ($vehicleNumber)';

  /// Strongly-typed [VehicleType] helper for UI icons and categorization.
  VehicleType get vehicleType => VehicleType.fromString(type);

  /// Strongly-typed [VehicleStatus] helper for badge styling.
  VehicleStatus get vehicleStatus => VehicleStatus.fromString(status);

  /// Creates a copy with modified fields.
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? company,
    String? type,
    String? brand,
    String? model,
    String? status,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
    );
  }

  /// Converts this vehicle to a JSON map.
  /// Exactly matches the backend fields: id (if present), vehicleNumber,
  /// company, type, brand, model, status.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': int.tryParse(id!) ?? id,
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type,
      'brand': brand,
      'model': model,
      'status': status,
    };
  }

  /// Converts this vehicle to the JSON map expected by the Spring Boot
  /// POST and PUT request bodies (omits `id` to match VehicleRequest).
  Map<String, dynamic> toRequestBody() {
    return {
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type,
      'brand': brand,
      'model': model,
      'status': status,
    };
  }

  /// Constructs a [Vehicle] from JSON map received from Spring Boot API.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString(),
      vehicleNumber: (json['vehicleNumber'] as String?) ?? '',
      company: (json['company'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
    );
  }
}
