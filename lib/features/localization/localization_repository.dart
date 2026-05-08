import 'package:dio/dio.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/admin_localization_repository.dart';
import 'package:open_vts/core/repositories/common_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_localization_repository.dart';
import 'package:open_vts/features/localization/localization_models.dart';

class LocalizationRepository {
  LocalizationRepository._({
    required CommonRepository commonRepository,
    required _LocalizationRoleAdapter roleAdapter,
  }) : _commonRepository = commonRepository,
       _roleAdapter = roleAdapter;

  factory LocalizationRepository.forRole(
    LocalizationRole role, {
    ApiClient? api,
  }) {
    final resolvedApi = api ?? ApiClientProvider.create();
    final commonRepository = CommonRepository(api: resolvedApi);

    final adapter = switch (role) {
      LocalizationRole.admin => _AdminLocalizationRoleAdapter(
        AdminLocalizationRepository(api: resolvedApi),
      ),
      LocalizationRole.superadmin => _SuperadminLocalizationRoleAdapter(
        SuperadminRepository(api: resolvedApi),
      ),
      LocalizationRole.user => _UserLocalizationRoleAdapter(
        UserLocalizationRepository(api: resolvedApi),
      ),
    };

    return LocalizationRepository._(
      commonRepository: commonRepository,
      roleAdapter: adapter,
    );
  }

  final CommonRepository _commonRepository;
  final _LocalizationRoleAdapter _roleAdapter;

  Future<Result<List<ReferenceOption>>> getLanguages({
    CancelToken? cancelToken,
  }) {
    return _commonRepository.getLanguages(cancelToken: cancelToken);
  }

  Future<Result<List<String>>> getDateFormats({
    CancelToken? cancelToken,
  }) async {
    final result = await _commonRepository.getDateFormats(
      cancelToken: cancelToken,
    );

    return result.when(
      success: (items) => Result.ok(items.map((e) => e.value).toList()),
      failure: Result.fail,
    );
  }

  Future<Result<List<String>>> getTimezones({CancelToken? cancelToken}) async {
    final result = await _commonRepository.getTimezones(
      cancelToken: cancelToken,
    );

    return result.when(
      success: (items) => Result.ok(items.map((e) => e.value).toList()),
      failure: Result.fail,
    );
  }

  Future<Result<LocalizationSettingsData>> getLocalization({
    CancelToken? cancelToken,
  }) {
    return _roleAdapter.getLocalization(cancelToken: cancelToken);
  }

  Future<Result<void>> updateLocalization(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) {
    return _roleAdapter.updateLocalization(payload, cancelToken: cancelToken);
  }
}

abstract interface class _LocalizationRoleAdapter {
  Future<Result<LocalizationSettingsData>> getLocalization({
    CancelToken? cancelToken,
  });

  Future<Result<void>> updateLocalization(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  });
}

class _AdminLocalizationRoleAdapter implements _LocalizationRoleAdapter {
  const _AdminLocalizationRoleAdapter(this._repository);

  final AdminLocalizationRepository _repository;

  @override
  Future<Result<LocalizationSettingsData>> getLocalization({
    CancelToken? cancelToken,
  }) async {
    final result = await _repository.getLocalization(cancelToken: cancelToken);

    return result.when(
      success: (settings) => Result.ok(
        LocalizationSettingsData(
          languageCode: settings.languageCode,
          direction: settings.direction,
          dateFormat: settings.dateFormat,
          timeFormat: settings.timeFormat,
          use24Hour: settings.use24Hour,
          timezone: settings.timezone,
          units: settings.units,
          mapLat: settings.mapLat,
          mapLng: settings.mapLng,
          mapZoom: settings.mapZoom,
        ),
      ),
      failure: Result.fail,
    );
  }

  @override
  Future<Result<void>> updateLocalization(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) {
    return _repository.updateLocalization(payload, cancelToken: cancelToken);
  }
}

class _UserLocalizationRoleAdapter implements _LocalizationRoleAdapter {
  const _UserLocalizationRoleAdapter(this._repository);

  final UserLocalizationRepository _repository;

  @override
  Future<Result<LocalizationSettingsData>> getLocalization({
    CancelToken? cancelToken,
  }) async {
    final result = await _repository.getLocalization(cancelToken: cancelToken);

    return result.when(
      success: (settings) => Result.ok(
        LocalizationSettingsData(
          languageCode: settings.languageCode,
          direction: settings.direction,
          dateFormat: settings.dateFormat,
          timeFormat: settings.timeFormat,
          use24Hour: settings.use24Hour,
          timezone: settings.timezone,
          units: settings.units,
          mapLat: settings.mapLat,
          mapLng: settings.mapLng,
          mapZoom: settings.mapZoom,
        ),
      ),
      failure: Result.fail,
    );
  }

  @override
  Future<Result<void>> updateLocalization(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) {
    return _repository.updateLocalization(payload, cancelToken: cancelToken);
  }
}

class _SuperadminLocalizationRoleAdapter implements _LocalizationRoleAdapter {
  const _SuperadminLocalizationRoleAdapter(this._repository);

  final SuperadminRepository _repository;

  @override
  Future<Result<LocalizationSettingsData>> getLocalization({
    CancelToken? cancelToken,
  }) async {
    final result = await _repository.getLocalizationSettings(
      cancelToken: cancelToken,
    );

    return result.when(
      success: (settings) => Result.ok(
        LocalizationSettingsData(
          languageCode: settings.languageCode,
          direction: settings.textDirection,
          dateFormat: settings.dateFormat,
          timeFormat: settings.timeFormat,
          use24Hour: settings.use24Hour,
          timezone: settings.timezone,
          units: settings.units,
          mapLat: settings.mapLat,
          mapLng: settings.mapLng,
          mapZoom: settings.mapZoom,
        ),
      ),
      failure: Result.fail,
    );
  }

  @override
  Future<Result<void>> updateLocalization(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) {
    return _repository.updateLocalizationSettings(
      payload,
      cancelToken: cancelToken,
    );
  }
}
