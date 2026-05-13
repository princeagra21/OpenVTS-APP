import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_details.dart';
import 'package:open_vts/core/utils/presentation_result.dart';
import 'package:open_vts/features/admin/data/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';

abstract class OpenVtsMapRepository {
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    AppCancellationHandle? cancelToken,
  });

  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    AppCancellationHandle? cancelToken,
  });

  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    AppCancellationHandle? cancelToken,
  });
}

class AdminMapTelemetryAdapter implements OpenVtsMapRepository {
  final AdminVehiclesRepository repository;

  const AdminMapTelemetryAdapter({required this.repository});

  @override
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    AppCancellationHandle? cancelToken,
  }) {
    return repository.getMapTelemetry(cancelToken: cancelToken);
  }

  @override
  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    AppCancellationHandle? cancelToken,
  }) {
    return repository.getVehicleDetailsByImei(imei, cancelToken: cancelToken);
  }

  @override
  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    AppCancellationHandle? cancelToken,
  }) {
    return repository.reverseGeocode(lat, lng, cancelToken: cancelToken);
  }
}

class SuperadminMapTelemetryAdapter implements OpenVtsMapRepository {
  final SuperadminRepository repository;

  const SuperadminMapTelemetryAdapter({required this.repository});

  @override
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    AppCancellationHandle? cancelToken,
  }) {
    return repository.getMapTelemetry(cancelToken: cancelToken);
  }

  @override
  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    AppCancellationHandle? cancelToken,
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
    AppCancellationHandle? cancelToken,
  }) {
    return repository.reverseGeocode(lat, lng, cancelToken: cancelToken);
  }
}

class UserMapTelemetryAdapter implements OpenVtsMapRepository {
  final UserVehiclesRepository repository;

  const UserMapTelemetryAdapter({required this.repository});

  @override
  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    AppCancellationHandle? cancelToken,
  }) {
    return repository.getMapTelemetry(cancelToken: cancelToken);
  }

  @override
  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    AppCancellationHandle? cancelToken,
  }) {
    return repository.getVehicleDetailsByImei(imei, cancelToken: cancelToken);
  }

  @override
  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    AppCancellationHandle? cancelToken,
  }) {
    return repository.reverseGeocode(lat, lng, cancelToken: cancelToken);
  }
}
