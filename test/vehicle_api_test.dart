import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/core/config/api_config.dart';
import 'package:vms_frontend/core/network/api_client.dart';
import 'package:vms_frontend/core/network/api_exception.dart';
import 'package:vms_frontend/features/vehicles/data/vehicle_repository.dart';
import 'package:vms_frontend/features/vehicles/models/vehicle.dart';

void main() {
  group('ApiConfig', () {
    test('default baseUrl is http://localhost:8080', () {
      expect(ApiConfig.baseUrl, 'http://localhost:8080');
      expect(ApiConfig.normalizedBaseUrl, 'http://localhost:8080');
      expect(ApiConfig.vehiclesUri, 'http://localhost:8080/api/vehicles');
      expect(ApiConfig.vehicleUri('1'), 'http://localhost:8080/api/vehicles/1');
    });
  });

  group('VehicleApiClient', () {
    const sampleVehicleJson = {
      'id': 1,
      'vehicleNumber': 'DHK-11-2233',
      'company': 'Acme Corp',
      'type': 'Truck',
      'brand': 'Volvo',
      'model': 'FH16',
      'status': 'Active',
    };

    test('getVehicles returns list of vehicles on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/vehicles');
        return http.Response(jsonEncode([sampleVehicleJson]), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      final vehicles = await apiClient.getVehicles();

      expect(vehicles.length, 1);
      expect(vehicles.first.id, '1');
      expect(vehicles.first.vehicleNumber, 'DHK-11-2233');
      expect(vehicles.first.type, 'Truck');
      expect(vehicles.first.status, 'Active');
    });

    test('getVehicleById returns single vehicle on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/vehicles/1');
        return http.Response(jsonEncode(sampleVehicleJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      final vehicle = await apiClient.getVehicleById('1');

      expect(vehicle.id, '1');
      expect(vehicle.vehicleNumber, 'DHK-11-2233');
    });

    test('createVehicle sends POST /api/vehicles and returns 201 Created', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/vehicles');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['vehicleNumber'], 'DHK-11-2233');
        expect(body.containsKey('id'), isFalse); // id omitted in create request

        return http.Response(jsonEncode(sampleVehicleJson), 201, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      const toCreate = Vehicle(
        vehicleNumber: 'DHK-11-2233',
        company: 'Acme Corp',
        type: 'Truck',
        brand: 'Volvo',
        model: 'FH16',
        status: 'Active',
      );

      final created = await apiClient.createVehicle(toCreate);
      expect(created.id, '1');
      expect(created.vehicleNumber, 'DHK-11-2233');
    });

    test('createVehicle throws ApiException with backend message on 409 Conflict', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 409,
            'error': 'Conflict',
            'message': 'Vehicle already exists with vehicle number: DHK-11-2233',
            'path': '/api/vehicles',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      const toCreate = Vehicle(
        vehicleNumber: 'DHK-11-2233',
        company: 'Acme Corp',
        type: 'Truck',
        brand: 'Volvo',
        model: 'FH16',
        status: 'Active',
      );

      expect(
        () => apiClient.createVehicle(toCreate),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Vehicle already exists with vehicle number: DHK-11-2233',
        )),
      );
    });

    test('createVehicle throws ApiException with backend message on 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 400,
            'error': 'Bad Request',
            'message': 'vehicleNumber: Vehicle number is required',
            'path': '/api/vehicles',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      const toCreate = Vehicle(
        vehicleNumber: '',
        company: 'Acme Corp',
        type: 'Truck',
        brand: 'Volvo',
        model: 'FH16',
        status: 'Active',
      );

      expect(
        () => apiClient.createVehicle(toCreate),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          'vehicleNumber: Vehicle number is required',
        )),
      );
    });

    test('updateVehicle sends PUT /api/vehicles/{id} and returns 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/vehicles/1');
        return http.Response(jsonEncode(sampleVehicleJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      const toUpdate = Vehicle(
        id: '1',
        vehicleNumber: 'DHK-11-2233',
        company: 'Acme Corp',
        type: 'Truck',
        brand: 'Volvo',
        model: 'FH16',
        status: 'Active',
      );

      final updated = await apiClient.updateVehicle('1', toUpdate);
      expect(updated.id, '1');
    });

    test('deleteVehicle sends DELETE /api/vehicles/{id} and returns 204 No Content', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/vehicles/1');
        return http.Response('', 204);
      });

      final apiClient = VehicleApiClient(httpClient: mockClient);
      await expectLater(apiClient.deleteVehicle('1'), completes);
    });
  });

  group('VehicleRepository', () {
    test('delete only removes vehicle after backend confirms success (204)', () async {
      var deleteCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCalled = true;
          return http.Response('', 204);
        }
        return http.Response('', 404);
      });

      const initial = Vehicle(
        id: '1',
        vehicleNumber: 'VN-1001',
        company: 'Apex Logistics',
        type: 'Truck',
        brand: 'Ford',
        model: 'F-150',
        status: 'Active',
      );

      final repo = VehicleRepository.withVehicles(
        [initial],
        apiClient: VehicleApiClient(httpClient: mockClient),
      );

      expect(repo.vehicles.length, 1);
      await repo.deleteVehicle('1');
      expect(deleteCalled, isTrue);
      expect(repo.vehicles.length, 0);
    });

    test('delete does NOT remove vehicle if backend returns error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 500,
            'error': 'Internal Server Error',
            'message': 'Failed to delete vehicle on server',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      const initial = Vehicle(
        id: '1',
        vehicleNumber: 'VN-1001',
        company: 'Apex Logistics',
        type: 'Truck',
        brand: 'Ford',
        model: 'F-150',
        status: 'Active',
      );

      final repo = VehicleRepository.withVehicles(
        [initial],
        apiClient: VehicleApiClient(httpClient: mockClient),
      );

      expect(repo.vehicles.length, 1);
      await expectLater(
        repo.deleteVehicle('1'),
        throwsA(isA<ApiException>()),
      );
      // Vehicle is still in repository because backend did not confirm success
      expect(repo.vehicles.length, 1);
    });

    test('fetchVehicles sets error and does not fall back silently to mock data on failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 500,
            'message': 'Database connection lost',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(httpClient: mockClient),
      );

      expect(repo.vehicles.isEmpty, isTrue);
      expect(repo.hasError, isFalse);

      await expectLater(
        repo.fetchVehicles(),
        throwsA(isA<ApiException>()),
      );

      // After failure, error state is set and vehicles remains empty (no silent mock data fallback)
      expect(repo.hasError, isTrue);
      expect(repo.errorMessage, 'Database connection lost');
      expect(repo.vehicles.isEmpty, isTrue);
    });
  });
}
