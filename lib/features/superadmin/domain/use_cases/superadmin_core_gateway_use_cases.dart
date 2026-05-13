import 'dart:typed_data';

import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_settings.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/settings/domain/entities/app_preferences.dart';
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

class GetSuperadminProfileGatewayUseCase {
  const GetSuperadminProfileGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<SuperadminProfile, AppError>> call() => _repository.getSuperadminProfile();
}

class UpdateSuperadminPasswordGatewayUseCase {
  const UpdateSuperadminPasswordGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<void, AppError>> call({required String adminId, required String newPassword, required String confirmPassword}) {
    return _repository.updateSuperadminPassword(adminId: adminId, newPassword: newPassword, confirmPassword: confirmPassword);
  }
}

class GetSuperadminDashboardGatewayUseCase {
  const GetSuperadminDashboardGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<SuperadminTotalCounts, AppError>> getTotalCounts() => _repository.getTotalCounts();
  Future<Result<SuperadminAdoptionGraph, AppError>> getAdoptionGraph() => _repository.getAdoptionGraph();
  Future<Result<List<SuperadminRecentVehicle>, AppError>> getRecentVehicles() => _repository.getRecentVehicles();
  Future<Result<List<SuperadminRecentUser>, AppError>> getRecentUsers() => _repository.getRecentUsers();
  Future<Result<List<SuperadminRecentTransaction>, AppError>> getRecentTransactions({int? page, int? limit, String? adminId, String? from, String? to, String? status, String? q}) {
    return _repository.getRecentTransactions(page: page, limit: limit, adminId: adminId, from: from, to: to, status: status, q: q);
  }
  Future<Result<List<VehicleListItem>, AppError>> getVehicles({int? page, int? limit}) => _repository.getVehicles(page: page, limit: limit);
  Future<Result<List<AdminListItem>, AppError>> getAdmins({int? page, int? limit, String? status}) => _repository.getAdmins(page: page, limit: limit, status: status);
}

class GetSuperadminAdminGatewayUseCase {
  const GetSuperadminAdminGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<Object, AppError>> getAdminProfile(String adminId) => _repository.getAdminProfile(adminId);
  Future<Result<void, AppError>> updateAdminProfile(String adminId, Map<String, Object?> payload) => _repository.updateAdminProfile(adminId, payload);
  Future<Result<String, AppError>> uploadSuperadminProfileImage({required String adminId, required Uint8List bytes, required String filename, String? contentType}) {
    return _repository.uploadSuperadminProfileImage(adminId: adminId, bytes: bytes, filename: filename, contentType: contentType);
  }
  Future<Result<void, AppError>> updateAdminStatus(String adminId, bool isActive) => _repository.updateAdminStatus(adminId, isActive);
  Future<Result<List<Map<String, Object?>>, AppError>> getRoles() => _repository.getRoles();
  Future<Result<List<Map<String, Object?>>, AppError>> getAdminActivityLogs(String adminId, {int? limit}) => _repository.getAdminActivityLogs(adminId, limit: limit);
  Future<Result<List<SuperadminDocumentType>, AppError>> getDocumentTypes() => _repository.getDocumentTypes();
  Future<Result<AdminSettings, AppError>> getAdminSettings(String adminId) => _repository.getAdminSettings(adminId);
  Future<Result<AdminSettings, AppError>> updateAdminSettings(String adminId, AdminSettings settings) => _repository.updateAdminSettings(adminId, settings);
}

class SuperadminVehicleGatewayUseCase {
  const SuperadminVehicleGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<List<VehicleLogItem>, AppError>> getVehicleLogs(String imei, {String? from, String? to, String? query, int? page, int? limit}) {
    return _repository.getVehicleLogs(imei, from: from, to: to, query: query, page: page, limit: limit);
  }
  Future<Result<VehicleLocation, AppError>> getVehicleLocation(String imei) => _repository.getVehicleLocation(imei);
  Future<Result<void, AppError>> updateVehicleConfig(String vehicleId, VehicleConfigUpdate payload) => _repository.updateVehicleConfig(vehicleId, payload);
  Future<Result<void, AppError>> deleteVehicle(String vehicleId) => _repository.deleteVehicle(vehicleId);
}

class SuperadminReferenceOptionsGatewayUseCase {
  const SuperadminReferenceOptionsGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<List<ReferenceOption>, AppError>> getLanguages() => _repository.getLanguages();
  Future<Result<List<ReferenceOption>, AppError>> getDateFormats() => _repository.getDateFormats();
  Future<Result<List<TimezoneOption>, AppError>> getTimezones() => _repository.getTimezones();
}

class SuperadminPreferencesGatewayUseCase {
  const SuperadminPreferencesGatewayUseCase(this._repository);
  final SuperadminCoreGatewayRepository _repository;
  Future<Result<AppPreferences, AppError>> getAppPreferences() => _repository.getAppPreferences();
  Future<Result<void, AppError>> updateAppPreferences(Map<String, Object?> payload) => _repository.updateAppPreferences(payload);
}
