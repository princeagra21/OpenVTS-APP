import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/settings/data/mappers/settings_mapper.dart';
import 'package:open_vts/features/settings/data/sources/settings_retrofit_service.dart';
import 'package:open_vts/features/settings/domain/entities/settings_snapshot.dart';
import 'package:open_vts/features/settings/domain/repositories/settings_repository.dart';
import 'package:open_vts/features/settings/data/models/settings_update_request_dto.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required SettingsApiService api, SettingsMapper mapper = const SettingsMapper()})
      : _api = api,
        _mapper = mapper;

  final SettingsApiService _api;
  final SettingsMapper _mapper;

  @override
  Future<Result<SettingsSnapshot, AppError>> getSettings() async {
    try {
      final response = await _api.getSettings();
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to load settings.' : response.message));
      }
      return Result.success(_mapper.toDomain(payload));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<SettingsSnapshot, AppError>> updateSettings(Map<String, Object?> values) async {
    try {
      final response = await _api.updateSettings(SettingsUpdateRequestDto(values));
      final payload = response.payload;
      if (!response.action || payload == null) {
        return Result.failure(ServerError(response.message.isEmpty ? 'Unable to save settings.' : response.message));
      }
      return Result.success(_mapper.toDomain(payload));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }
}
