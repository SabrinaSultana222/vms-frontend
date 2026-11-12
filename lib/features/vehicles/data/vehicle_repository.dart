import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/vehicle.dart';
import '../models/vehicle_status.dart';

/// Repository that mediates between the UI and the Spring Boot REST API.
///
/// Implements [ChangeNotifier] so UI widgets automatically update
/// when vehicles are fetched, created, updated, or removed.
///
/// Maintains loading, empty, error, and success states without raw HTTP code in widgets.
class VehicleRepository extends ChangeNotifier {
  static VehicleRepository _instance = VehicleRepository._internal();

  /// Global singleton instance.
  static VehicleRepository get instance => _instance;

  /// Visible for testing to reset or inject a mock repository.
  static set instanceForTesting(VehicleRepository repo) {
    _instance = repo;
  }

  final VehicleApiClient _apiClient;
  final List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  VehicleRepository({VehicleApiClient? apiClient})
      : _apiClient = apiClient ?? VehicleApiClient();

  VehicleRepository._internal() : _apiClient = VehicleApiClient();

  /// Factory constructor to initialize with predefined vehicles (e.g. for testing).
  factory VehicleRepository.withVehicles(List<Vehicle> initial, {VehicleApiClient? apiClient}) {
    final repo = VehicleRepository(apiClient: apiClient);
    repo._vehicles.addAll(initial);
    return repo;
  }

  /// Unmodifiable list of currently loaded vehicles.
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  /// Whether a network fetch operation is currently in flight.
  bool get isLoading => _isLoading;

  /// Current error message if an operation failed, or null if healthy.
  String? get errorMessage => _errorMessage;

  /// Whether the repository currently holds an error state.
  bool get hasError => _errorMessage != null;

  /// Whether the vehicles list is empty and not loading.
  bool get isEmpty => !_isLoading && _vehicles.isEmpty;

  /// Total count of all vehicles.
  int get totalCount => _vehicles.length;

  /// Count of active vehicles.
  int get activeCount => _vehicles
      .where((v) => v.vehicleStatus == VehicleStatus.active)
      .length;

  /// Count of vehicles in maintenance.
  int get maintenanceCount => _vehicles
      .where((v) => v.vehicleStatus == VehicleStatus.maintenance)
      .length;

  /// Count of inactive vehicles.
  int get inactiveCount => _vehicles
      .where((v) => v.vehicleStatus == VehicleStatus.inactive)
      .length;

  /// Count of reserved vehicles.
  int get reservedCount => _vehicles
      .where((v) => v.vehicleStatus == VehicleStatus.reserved)
      .length;

  /// Finds a vehicle by its [id] or [vehicleNumber] from memory.
  Vehicle? getById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id || v.vehicleNumber == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the vehicle list from `GET /api/vehicles`.
  ///
  /// Updates loading, error, and success states.
  /// Does NOT silently fall back to mock data if the API fails.
  Future<List<Vehicle>> fetchVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _apiClient.getVehicles();
      _vehicles.clear();
      _vehicles.addAll(fetched);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return List.unmodifiable(_vehicles);
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches a single vehicle by [id] from `GET /api/vehicles/{id}`.
  Future<Vehicle> fetchVehicleById(String id) async {
    return await _apiClient.getVehicleById(id);
  }

  /// Creates a new vehicle via `POST /api/vehicles`.
  ///
  /// On 201 Created success, prepends the vehicle to [_vehicles] and notifies listeners.
  /// If the backend rejects the request (e.g. 409 conflict or 400 validation error),
  /// the [ApiException] is thrown for the UI to display the backend message.
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final created = await _apiClient.createVehicle(vehicle);
    _vehicles.insert(0, created);
    notifyListeners();
    return created;
  }

  /// Updates an existing vehicle via `PUT /api/vehicles/{id}`.
  ///
  /// On 200 OK success, updates the local vehicle list and notifies listeners.
  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    final updated = await _apiClient.updateVehicle(id, vehicle);
    final index = _vehicles.indexWhere((v) => v.id == id || v.vehicleNumber == id);
    if (index != -1) {
      _vehicles[index] = updated;
    } else {
      _vehicles.insert(0, updated);
    }
    notifyListeners();
    return updated;
  }

  /// Deletes a vehicle via `DELETE /api/vehicles/{id}`.
  ///
  /// Deletes only after the backend confirms success (204 No Content).
  Future<void> deleteVehicle(String id) async {
    await _apiClient.deleteVehicle(id);
    _vehicles.removeWhere((v) => v.id == id || v.vehicleNumber == id);
    notifyListeners();
  }

  /// Filters vehicles by search query, status string, and type string.
  List<Vehicle> filter({
    String? query,
    String? status,
    String? type,
  }) {
    return _vehicles.where((v) {
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          v.vehicleNumber.toLowerCase().contains(query.toLowerCase()) ||
          v.company.toLowerCase().contains(query.toLowerCase()) ||
          v.brand.toLowerCase().contains(query.toLowerCase()) ||
          v.model.toLowerCase().contains(query.toLowerCase()) ||
          v.type.toLowerCase().contains(query.toLowerCase()) ||
          v.status.toLowerCase().contains(query.toLowerCase());

      final matchesStatus = status == null ||
          status.trim().isEmpty ||
          v.status.toLowerCase() == status.toLowerCase() ||
          v.vehicleStatus.label.toLowerCase() == status.toLowerCase();

      final matchesType = type == null ||
          type.trim().isEmpty ||
          v.type.toLowerCase() == type.toLowerCase() ||
          v.vehicleType.label.toLowerCase() == type.toLowerCase();

      return matchesQuery && matchesStatus && matchesType;
    }).toList();
  }
}
