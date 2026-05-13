import 'dart:typed_data';

import 'package:open_vts/core/api/api_result.dart' as legacy_result;
import 'package:open_vts/core/api/legacy_api_transport.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart' as domain;
import 'package:open_vts/features/admin/domain/entities/admin_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_settings.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';
import 'package:open_vts/features/settings/data/repositories/app_preferences_repository.dart';
import 'package:open_vts/features/settings/domain/entities/app_preferences.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart' as legacy;
import 'package:open_vts/features/superadmin/domain/entities/superadmin_adoption_graph.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_profile.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_transaction.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_user.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_vehicle.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_total_counts.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_core_gateway_repository.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_log_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_location.dart';

class SuperadminCoreGatewayRepositoryImpl implements SuperadminCoreGatewayRepository {
  SuperadminCoreGatewayRepositoryImpl({required LegacyApiTransport api, required ReferenceDataRepository referenceDataRepository})
      : _legacy = legacy.SuperadminRepository(api: api),
        _preferences = AppPreferencesRepository(api: api),
        _referenceDataRepository = referenceDataRepository;

  final legacy.SuperadminRepository _legacy;
  final AppPreferencesRepository _preferences;
  final ReferenceDataRepository _referenceDataRepository;

  @override
  Future<domain.Result<SuperadminProfile, AppError>> getSuperadminProfile() {
    return _convert(_legacy.getSuperadminProfile());
  }

  @override
  Future<domain.Result<void, AppError>> updateSuperadminPassword({required String adminId, required String newPassword, required String confirmPassword}) {
    return _convert(_legacy.updateAdminPassword(adminId, newPassword, confirmPassword));
  }

  @override
  Future<domain.Result<SuperadminTotalCounts, AppError>> getTotalCounts() => _convert(_legacy.getTotalCounts());

  @override
  Future<domain.Result<SuperadminAdoptionGraph, AppError>> getAdoptionGraph() => _convert(_legacy.getAdoptionGraph());

  @override
  Future<domain.Result<List<SuperadminRecentVehicle>, AppError>> getRecentVehicles() => _convert(_legacy.getRecentVehicles());

  @override
  Future<domain.Result<List<SuperadminRecentUser>, AppError>> getRecentUsers() => _convert(_legacy.getRecentUsers());

  @override
  Future<domain.Result<List<SuperadminRecentTransaction>, AppError>> getRecentTransactions({int? page, int? limit, String? adminId, String? from, String? to, String? status, String? q}) {
    return _convert(_legacy.getRecentTransactions(page: page, limit: limit, adminId: adminId, from: from, to: to, status: status, q: q));
  }


  @override
  Future<domain.Result<List<VehicleListItem>, AppError>> getVehicles({int? page, int? limit}) => _convert(_legacy.getVehicles(page: page, limit: limit));

  @override
  Future<domain.Result<List<AdminListItem>, AppError>> getAdmins({int? page, int? limit, String? status}) => _convert(_legacy.getAdmins(page: page, limit: limit, status: status));

  @override
  Future<domain.Result<Object, AppError>> getAdminProfile(String adminId) {
    return _convert(_legacy.getAdminProfile(adminId).then((value) => value.when(success: (profile) => legacy_result.Result.ok<Object>(profile), failure: legacy_result.Result.fail)));
  }

  @override
  Future<domain.Result<void, AppError>> updateAdminProfile(String adminId, Map<String, Object?> payload) {
    return _convert(_legacy.updateAdminProfile(adminId, Map<String, dynamic>.from(payload)).then((value) => value.when(success: (_) => legacy_result.Result.ok<void>(null), failure: legacy_result.Result.fail)));
  }

  @override
  Future<domain.Result<String, AppError>> uploadSuperadminProfileImage({required String adminId, required Uint8List bytes, required String filename, String? contentType}) {
    return _convert(_legacy.uploadSuperadminProfileImage(adminId: adminId, bytes: bytes, filename: filename, contentType: contentType));
  }

  @override
  Future<domain.Result<void, AppError>> updateAdminStatus(String adminId, bool isActive) => _convert(_legacy.updateAdminStatus(adminId, isActive));

  @override
  Future<domain.Result<List<Map<String, Object?>>, AppError>> getRoles() async {
    final result = await _legacy.getRoles();
    return result.when(
      success: (roles) => domain.Result.success(roles.map((role) => <String, Object?>{for (final entry in role.entries) entry.key.toString(): entry.value}).toList()),
      failure: (error) => domain.Result.failure(AppErrorMapper.fromObject(error)),
    );
  }

  @override
  Future<domain.Result<List<Map<String, Object?>>, AppError>> getAdminActivityLogs(String adminId, {int? limit}) async {
    final result = await _legacy.getAdminActivityLogs(adminId, limit: limit);
    return result.when(
      success: (logs) => domain.Result.success(logs.map((log) => <String, Object?>{for (final entry in log.entries) entry.key.toString(): entry.value}).toList()),
      failure: (error) => domain.Result.failure(AppErrorMapper.fromObject(error)),
    );
  }

  @override
  Future<domain.Result<List<SuperadminDocumentType>, AppError>> getDocumentTypes() => _convert(_legacy.getDocumentTypes());

  @override
  Future<domain.Result<AdminSettings, AppError>> getAdminSettings(String adminId) => _convert(_legacy.getAdminSettings(adminId));

  @override
  Future<domain.Result<AdminSettings, AppError>> updateAdminSettings(String adminId, AdminSettings settings) => _convert(_legacy.updateAdminSettings(adminId, Map<String, dynamic>.from(settings.raw)));

  @override
  Future<domain.Result<List<VehicleLogItem>, AppError>> getVehicleLogs(String imei, {String? from, String? to, String? query, int? page, int? limit}) {
    return _convert(_legacy.getVehicleLogs(imei, from: from, to: to, query: query, page: page, limit: limit));
  }

  @override
  Future<domain.Result<VehicleLocation, AppError>> getVehicleLocation(String imei) => _convert(_legacy.getVehicleLocation(imei));

  @override
  Future<domain.Result<void, AppError>> updateVehicleConfig(String vehicleId, VehicleConfigUpdate payload) => _convert(_legacy.updateVehicleConfig(vehicleId, payload));

  @override
  Future<domain.Result<void, AppError>> deleteVehicle(String vehicleId) => _convert(_legacy.deleteVehicle(vehicleId));

  @override
  Future<domain.Result<List<ReferenceOption>, AppError>> getLanguages() => _referenceDataRepository.getLanguages();

  @override
  Future<domain.Result<List<ReferenceOption>, AppError>> getDateFormats() => _referenceDataRepository.getDateFormats();

  @override
  Future<domain.Result<List<TimezoneOption>, AppError>> getTimezones() => _referenceDataRepository.getTimezones();

  @override
  Future<domain.Result<AppPreferences, AppError>> getAppPreferences() => _convert(_preferences.getAppPreferences());

  @override
  Future<domain.Result<void, AppError>> updateAppPreferences(Map<String, Object?> payload) => _convert(_preferences.updateAppPreferences(Map<String, dynamic>.from(payload)));

  Future<domain.Result<T, AppError>> _convert<T>(Future<legacy_result.Result<T>> future) async {
    final result = await future;
    return result.when(
      success: domain.Result.success,
      failure: (error) => domain.Result.failure(AppErrorMapper.fromObject(error)),
    );
  }
}
