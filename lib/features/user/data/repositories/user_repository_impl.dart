import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/data/mappers/user_dashboard_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_retrofit_service.dart';
import 'package:open_vts/features/user/domain/entities/user_dashboard.dart';
import 'package:open_vts/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({required UserApiService api, UserDashboardMapper mapper = const UserDashboardMapper()})
      : _api = api,
        _mapper = mapper;

  final UserApiService _api;
  final UserDashboardMapper _mapper;

  @override
  Future<Result<UserDashboard, AppError>> getDashboard() async {
    try {
      final response = await _api.getDashboard();
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to load user dashboard.' : response.message));
      }
      return Result.success(_mapper.toDomain(payload));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<Object?, AppError>> loadResource(String resourceKey) async {
    if (resourceKey == 'dashboard') return getDashboard();
    return Result.failure(UnknownError('Unsupported user resource: $resourceKey'));
  }
}
