import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_dashboard_mapper.dart';
import 'package:open_vts/features/admin/data/sources/admin_retrofit_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_dashboard.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl({required AdminApiService api, AdminDashboardMapper mapper = const AdminDashboardMapper()})
      : _api = api,
        _mapper = mapper;

  final AdminApiService _api;
  final AdminDashboardMapper _mapper;

  @override
  Future<Result<AdminDashboard, AppError>> getDashboard() async {
    try {
      final response = await _api.getDashboard();
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to load admin dashboard.' : response.message));
      }
      return Result.success(_mapper.toDomain(payload));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Object?, AppError>> loadResource(String resourceKey) async {
    if (resourceKey == 'dashboard') return getDashboard();
    return Result.failure(UnknownError('Unsupported admin resource: $resourceKey'));
  }
}
