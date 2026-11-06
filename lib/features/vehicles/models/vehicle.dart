import 'vehicle_status.dart';
import 'vehicle_type.dart';

/// Data model representing a vehicle in the Vehicle Management System.
///
/// Fields: Vehicle Number, Company, Type, Brand, Model, and Status.
class Vehicle {
  final String id;
  final String vehicleNumber;
  final String company;
  final VehicleType type;
  final String brand;
  final String model;
  final VehicleStatus status;

  const Vehicle({
    String? id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  }) : id = id ?? vehicleNumber;

  /// Convenient display name (e.g. "Toyota Camry (VN-1001)")
  String get displayName => '$brand $model ($vehicleNumber)';

  /// Creates a copy with modified fields.
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? company,
    VehicleType? type,
    String? brand,
    String? model,
    VehicleStatus? status,
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

  /// Converts this vehicle to a JSON map for Spring Boot API communication.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.name,
      'brand': brand,
      'model': model,
      'status': status.name,
    };
  }

  /// Constructs a [Vehicle] from JSON map received from Spring Boot API.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final vNum = (json['vehicleNumber'] as String?) ?? '';
    return Vehicle(
      id: (json['id'] as String?) ?? vNum,
      vehicleNumber: vNum,
      company: (json['company'] as String?) ?? '',
      type: VehicleType.fromString(json['type'] as String?),
      brand: (json['brand'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      status: VehicleStatus.fromString(json['status'] as String?),
    );
  }
}
