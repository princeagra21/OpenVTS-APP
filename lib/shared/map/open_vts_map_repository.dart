import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/repositories/admin_vehicles_repository.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/repositories/user_vehicles_repository.dart';

abstract class OpenVtsMapRepository {
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  });

  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  });

  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  });
}

class AdminMapTelemetryAdapter implements OpenVtsMapRepository {
  final AdminVehiclesRepository repository;

  const AdminMapTelemetryAdapter({required this.repository});

  @override
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  }) {
    return repository.getMapTelemetry(cancelToken: cancelToken);
  }

  @override
  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  }) {
    return repository.getVehicleDetailsByImei(imei, cancelToken: cancelToken);
  }

  @override
  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) {
    return repository.reverseGeocode(lat, lng, cancelToken: cancelToken);
  }
}

class SuperadminMapTelemetryAdapter implements OpenVtsMapRepository {
  final SuperadminRepository repository;

  const SuperadminMapTelemetryAdapter({required this.repository});

  @override
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  }) {
    return repository.getMapTelemetry(cancelToken: cancelToken);
  }

  @override
  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  }) {
    return repository.getSuperadminVehicleDetailsByImei(
      imei,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) {
    return repository.reverseGeocode(lat, lng, cancelToken: cancelToken);
  }
}

class UserMapTelemetryAdapter implements OpenVtsMapRepository {
  final UserVehiclesRepository repository;

  const UserMapTelemetryAdapter({required this.repository});

  @override
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  }) {
    return repository.getMapTelemetry(cancelToken: cancelToken);
  }

  @override
  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  }) {
    return repository.getVehicleDetailsByImei(imei, cancelToken: cancelToken);
  }

  @override
  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) {
    return repository.reverseGeocode(lat, lng, cancelToken: cancelToken);
  }
}
