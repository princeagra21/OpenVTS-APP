import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_dashboard_mapper.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_retrofit_service.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_dashboard.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_repository.dart';

class SuperadminRepositoryImpl implements SuperadminRepository {
  const SuperadminRepositoryImpl({required SuperadminApiService api, SuperadminDashboardMapper mapper = const SuperadminDashboardMapper()})
      : _api = api,
        _mapper = mapper;

  final SuperadminApiService _api;
  final SuperadminDashboardMapper _mapper;

  @override
  Future<Result<SuperadminDashboard, AppError>> getDashboard() async {
    try {
      final response = await _api.getDashboard();
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to load superadmin dashboard.' : response.message));
      }
      return Result.success(_mapper.toDomain(payload));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Object?, AppError>> loadResource(String resourceKey) async {
    if (resourceKey == 'dashboard') return getDashboard();
    return Result.failure(UnknownError('Unsupported superadmin resource: $resourceKey'));
  }
}
