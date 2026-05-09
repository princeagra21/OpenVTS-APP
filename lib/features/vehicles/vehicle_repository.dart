import 'package:dio/dio.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_vehicles_repository.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/features/vehicles/vehicle_models.dart';
import 'package:open_vts/features/vehicles/vehicle_permissions.dart';
import 'package:open_vts/features/vehicles/vehicle_role_config.dart';

abstract class VehicleRepository {
  Future<Result<List<VehicleItem>>> getVehicles(
    VehicleListRequest request,
    CancelToken cancelToken,
  );

  Future<Result<List<Map<String, dynamic>>>> getTelemetry(
    CancelToken cancelToken,
  );
}

class VehicleRepositoryFactory {
  static VehicleRepository create(VehicleRole role) {
    final container = AppContainer.instance;
    switch (role) {
      case VehicleRole.superadmin:
        return _SuperadminVehicleRepository(container.superadminRepository);
      case VehicleRole.admin:
        return _AdminVehicleRepository(
          AdminVehiclesRepository(api: container.apiClient),
        );
      case VehicleRole.user:
        return _UserVehicleRepository(
          UserVehiclesRepository(api: container.apiClient),
        );
    }
  }
}

class _SuperadminVehicleRepository implements VehicleRepository {
  const _SuperadminVehicleRepository(this._repository);

  final SuperadminRepository _repository;

  @override
  Future<Result<List<VehicleItem>>> getVehicles(
    VehicleListRequest request,
    CancelToken cancelToken,
  ) async {
    final result = await _repository.getVehicles(
      page: request.page,
      limit: request.limit,
      cancelToken: cancelToken,
    );

    return result.when(
      success: (items) => Result.ok(
        _filterItems(
          items.map((item) => VehicleItem(item.raw)).toList(),
          request,
        ),
      ),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getTelemetry(
    CancelToken cancelToken,
  ) async {
    final result = await _repository.getMapTelemetry(cancelToken: cancelToken);
    return result.when(
      success: (points) => Result.ok(points.map((point) => point.raw).toList()),
      failure: (error) => Result.fail(error),
    );
  }
}

class _AdminVehicleRepository implements VehicleRepository {
  const _AdminVehicleRepository(this._repository);

  final AdminVehiclesRepository _repository;

  @override
  Future<Result<List<VehicleItem>>> getVehicles(
    VehicleListRequest request,
    CancelToken cancelToken,
  ) async {
    final result = await _repository.getVehicles(
      search: request.search,
      status: request.status,
      page: request.page,
      limit: request.limit,
      cancelToken: cancelToken,
    );

    return result.when(
      success: (items) => Result.ok(
        _filterItems(
          items.map((item) => VehicleItem(item.raw)).toList(),
          request,
        ),
      ),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getTelemetry(
    CancelToken cancelToken,
  ) async {
    final result = await _repository.getTelemetry(cancelToken: cancelToken);
    return result.when(
      success: (points) => Result.ok(points.map((point) => point.raw).toList()),
      failure: (error) => Result.fail(error),
    );
  }
}

class _UserVehicleRepository implements VehicleRepository {
  const _UserVehicleRepository(this._repository);

  final UserVehiclesRepository _repository;

  @override
  Future<Result<List<VehicleItem>>> getVehicles(
    VehicleListRequest request,
    CancelToken cancelToken,
  ) async {
    final result = await _repository.getVehicles(
      limit: request.limit,
      cancelToken: cancelToken,
    );

    return result.when(
      success: (items) => Result.ok(
        _filterItems(
          items.map((item) => VehicleItem(item.raw)).toList(),
          request,
        ),
      ),
      failure: (error) => Result.fail(error),
    );
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getTelemetry(
    CancelToken cancelToken,
  ) async {
    final result = await _repository.getMapTelemetry(cancelToken: cancelToken);
    return result.when(
      success: (points) => Result.ok(points.map((point) => point.raw).toList()),
      failure: (error) => Result.fail(error),
    );
  }
}

List<VehicleItem> _filterItems(
  List<VehicleItem> items,
  VehicleListRequest request,
) {
  final query = request.search?.trim().toLowerCase();
  final status = request.status?.trim().toLowerCase();

  return items.where((vehicle) {
    if (query != null && query.isNotEmpty && !_matchesQuery(vehicle, query)) {
      return false;
    }
    if (status != null &&
        status.isNotEmpty &&
        !_matchesStatus(vehicle, status)) {
      return false;
    }
    return true;
  }).toList();
}

bool _matchesQuery(VehicleItem vehicle, String query) {
  return <String>[
    vehicle.name,
    vehicle.plateNumber,
    vehicle.vin,
    vehicle.imei,
    vehicle.driverName,
    vehicle.type,
  ].any((value) => value.toLowerCase().contains(query));
}

bool _matchesStatus(VehicleItem vehicle, String status) {
  final statusText = '${vehicle.status} ${vehicle.motion} ${vehicle.engine}'
      .trim()
      .toLowerCase();
  switch (status) {
    case 'active':
      return vehicle.isActive || statusText.contains('active');
    case 'inactive':
      return !vehicle.isActive &&
          (statusText.contains('inactive') || statusText.contains('disabled'));
    case 'running':
      return statusText.contains('running') ||
          statusText.contains('moving') ||
          statusText.contains('on');
    case 'stopped':
      return statusText.contains('stopped') ||
          statusText.contains('idle') ||
          statusText.contains('off');
    default:
      return statusText.contains(status);
  }
}
