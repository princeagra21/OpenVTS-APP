import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/vehicles/data/local/vehicle_local_source.dart';
import 'package:open_vts/features/vehicles/data/mappers/vehicle_mapper.dart';
import 'package:open_vts/features/vehicles/data/repositories/legacy_vehicle_repository.dart' as legacy_repo;
import 'package:open_vts/features/vehicles/data/sources/vehicle_retrofit_service.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart' as legacy_models;
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  const VehicleRepositoryImpl({
    VehicleApiService? api,
    VehicleLocalSource? localSource,
    legacy_repo.VehicleRepository? legacyRepository,
    String listEndpoint = '/admin/vehicles',
  })  : _api = api,
        _localSource = localSource,
        _legacyRepository = legacyRepository,
        _listEndpoint = listEndpoint;

  final VehicleApiService? _api;
  final VehicleLocalSource? _localSource;
  final legacy_repo.VehicleRepository? _legacyRepository;
  final String _listEndpoint;

  @override
  Future<Result<PaginatedResponse<Vehicle>, AppError>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final api = _api;
    if (api != null) {
      try {
        final response = await api.getVehiclesFromEndpoint(
          _listEndpoint,
          page: page,
          limit: limit,
          search: search,
          status: status,
        );
        final payload = response.payload;
        if (!response.action || payload == null) {
          return Result.failure(ServerError(response.message.isEmpty ? 'Unable to load vehicles.' : response.message));
        }
        final vehicles = payload.items.map(VehicleMapper.fromMap).toList(growable: false);
        final pageData = PaginatedResponse<Vehicle>(
          data: vehicles,
          total: payload.total,
          page: payload.page,
          limit: payload.limit,
        );
        await _localSource?.saveVehicleList(
          pageData: pageData,
          page: page,
          limit: limit,
          search: search,
          status: status,
        );
        return Result.success(pageData);
      } catch (error) {
        final cached = await _localSource?.readVehicleList(
          page: page,
          limit: limit,
          search: search,
          status: status,
        );
        if (cached != null) {
          return Result.success(cached.page);
        }
        return Result.failure(AppErrorMapper.fromObject(error));
      }
    }

    final legacyRepository = _legacyRepository;
    if (legacyRepository == null) {
      return const Result.failure(UnknownError('Vehicle repository is not configured.'));
    }

    final cancelToken = CancelToken();
    final result = await legacyRepository.getVehicles(
      legacy_models.VehicleListRequest(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
      cancelToken,
    );

    return result.when(
      success: (items) async {
        final vehicles = items.map(VehicleMapper.fromLegacy).toList();
        final pageData = PaginatedResponse<Vehicle>(
          data: vehicles,
          total: vehicles.length,
          page: page,
          limit: limit,
        );
        await _localSource?.saveVehicleList(
          pageData: pageData,
          page: page,
          limit: limit,
          search: search,
          status: status,
        );
        return Result.success(pageData);
      },
      failure: (error) async {
        final cached = await _localSource?.readVehicleList(
          page: page,
          limit: limit,
          search: search,
          status: status,
        );
        if (cached != null) {
          return Result.success(cached.page);
        }
        return Result.failure(AppErrorMapper.fromObject(error));
      },
    );
  }
}
