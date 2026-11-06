import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../models/vehicle_status.dart';
import '../models/vehicle_type.dart';

/// In-memory repository providing mock fleet vehicle data.
///
/// Implements [ChangeNotifier] so UI screens automatically update
/// when vehicles are created, updated, or removed.
class VehicleRepository extends ChangeNotifier {
  // Singleton pattern for simple global access across the app
  static final VehicleRepository instance = VehicleRepository._internal();
  factory VehicleRepository() => instance;

  VehicleRepository._internal() {
    _vehicles.addAll(_initialMockData);
  }

  final List<Vehicle> _vehicles = [];

  /// Returns an unmodifiable view of all vehicles.
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  /// Total count of all vehicles.
  int get totalCount => _vehicles.length;

  /// Count of active vehicles.
  int get activeCount =>
      _vehicles.where((v) => v.status == VehicleStatus.active).length;

  /// Count of vehicles currently in maintenance.
  int get maintenanceCount =>
      _vehicles.where((v) => v.status == VehicleStatus.maintenance).length;

  /// Count of inactive or out-of-service vehicles.
  int get inactiveCount =>
      _vehicles.where((v) => v.status == VehicleStatus.inactive).length;

  /// Count of reserved vehicles.
  int get reservedCount =>
      _vehicles.where((v) => v.status == VehicleStatus.reserved).length;

  /// Finds a vehicle by its unique [id] or [vehicleNumber].
  Vehicle? getById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id || v.vehicleNumber == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new vehicle to the repository.
  void addVehicle(Vehicle vehicle) {
    _vehicles.insert(0, vehicle);
    notifyListeners();
  }

  /// Updates an existing vehicle.
  void updateVehicle(Vehicle updated) {
    final index = _vehicles.indexWhere((v) => v.id == updated.id);
    if (index != -1) {
      _vehicles[index] = updated;
      notifyListeners();
    }
  }

  /// Deletes a vehicle by its [id].
  void deleteVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id || v.vehicleNumber == id);
    notifyListeners();
  }

  /// Filters vehicles by query, status, and type.
  List<Vehicle> filter({
    String? query,
    VehicleStatus? status,
    VehicleType? type,
  }) {
    return _vehicles.where((v) {
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          v.vehicleNumber.toLowerCase().contains(query.toLowerCase()) ||
          v.company.toLowerCase().contains(query.toLowerCase()) ||
          v.brand.toLowerCase().contains(query.toLowerCase()) ||
          v.model.toLowerCase().contains(query.toLowerCase());

      final matchesStatus = status == null || v.status == status;
      final matchesType = type == null || v.type == type;

      return matchesQuery && matchesStatus && matchesType;
    }).toList();
  }

  /// Initial realistic mock fleet dataset with exactly:
  /// Vehicle Number, Company, Type, Brand, Model, and Status.
  static final List<Vehicle> _initialMockData = [
    const Vehicle(
      id: 'VMS-101',
      vehicleNumber: 'VN-1001',
      company: 'Apex Logistics',
      type: VehicleType.truck,
      brand: 'Ford',
      model: 'F-150 SuperCrew',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'VMS-102',
      vehicleNumber: 'VN-1002',
      company: 'Global Transport',
      type: VehicleType.sedan,
      brand: 'Toyota',
      model: 'Camry',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'VMS-103',
      vehicleNumber: 'VN-1003',
      company: 'Metro Fleet Inc.',
      type: VehicleType.electric,
      brand: 'Tesla',
      model: 'Model 3',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'VMS-104',
      vehicleNumber: 'VN-1004',
      company: 'Apex Logistics',
      type: VehicleType.van,
      brand: 'Ford',
      model: 'Transit Cargo',
      status: VehicleStatus.maintenance,
    ),
    const Vehicle(
      id: 'VMS-105',
      vehicleNumber: 'VN-1005',
      company: 'Summit Energy',
      type: VehicleType.suv,
      brand: 'Volvo',
      model: 'XC90',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'VMS-106',
      vehicleNumber: 'VN-1006',
      company: 'Global Transport',
      type: VehicleType.truck,
      brand: 'RAM',
      model: '2500 Heavy Duty',
      status: VehicleStatus.inactive,
    ),
    const Vehicle(
      id: 'VMS-107',
      vehicleNumber: 'VN-1007',
      company: 'Express Delivery Co.',
      type: VehicleType.van,
      brand: 'Chevrolet',
      model: 'Express 2500',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'VMS-108',
      vehicleNumber: 'VN-1008',
      company: 'Metro Fleet Inc.',
      type: VehicleType.suv,
      brand: 'Honda',
      model: 'CR-V',
      status: VehicleStatus.reserved,
    ),
    const Vehicle(
      id: 'VMS-109',
      vehicleNumber: 'VN-1009',
      company: 'EcoCourier Services',
      type: VehicleType.electric,
      brand: 'Chevrolet',
      model: 'Bolt EUV',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'VMS-110',
      vehicleNumber: 'VN-1010',
      company: 'Summit Energy',
      type: VehicleType.van,
      brand: 'Chrysler',
      model: 'Pacifica',
      status: VehicleStatus.maintenance,
    ),
  ];
}
