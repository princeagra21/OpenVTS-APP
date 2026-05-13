import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_settings.dart';
import 'dart:typed_data';

import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_adoption_graph.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_profile.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_transaction.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_user.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_vehicle.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_total_counts.dart';
import 'package:open_vts/features/settings/domain/entities/app_preferences.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_log_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_location.dart';

abstract interface class SuperadminCoreGatewayRepository {
  Future<Result<SuperadminProfile, AppError>> getSuperadminProfile();
  Future<Result<void, AppError>> updateSuperadminPassword({
    required String adminId,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Result<SuperadminTotalCounts, AppError>> getTotalCounts();
  Future<Result<SuperadminAdoptionGraph, AppError>> getAdoptionGraph();
  Future<Result<List<SuperadminRecentVehicle>, AppError>> getRecentVehicles();
  Future<Result<List<SuperadminRecentUser>, AppError>> getRecentUsers();
  Future<Result<List<SuperadminRecentTransaction>, AppError>> getRecentTransactions({
    int? page,
    int? limit,
    String? adminId,
    String? from,
    String? to,
    String? status,
    String? q,
  });

  Future<Result<List<VehicleListItem>, AppError>> getVehicles({int? page, int? limit});
  Future<Result<List<AdminListItem>, AppError>> getAdmins({int? page, int? limit, String? status});

  Future<Result<Object, AppError>> getAdminProfile(String adminId);
  Future<Result<void, AppError>> updateAdminProfile(String adminId, Map<String, Object?> payload);
  Future<Result<String, AppError>> uploadSuperadminProfileImage({
    required String adminId,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  });
  Future<Result<void, AppError>> updateAdminStatus(String adminId, bool isActive);
  Future<Result<List<Map<String, Object?>>, AppError>> getRoles();
  Future<Result<List<Map<String, Object?>>, AppError>> getAdminActivityLogs(String adminId, {int? limit});

  Future<Result<List<SuperadminDocumentType>, AppError>> getDocumentTypes();
  Future<Result<AdminSettings, AppError>> getAdminSettings(String adminId);
  Future<Result<AdminSettings, AppError>> updateAdminSettings(String adminId, AdminSettings settings);

  Future<Result<List<VehicleLogItem>, AppError>> getVehicleLogs(String imei, {String? from, String? to, String? query, int? page, int? limit});
  Future<Result<VehicleLocation, AppError>> getVehicleLocation(String imei);
  Future<Result<void, AppError>> updateVehicleConfig(String vehicleId, VehicleConfigUpdate payload);
  Future<Result<void, AppError>> deleteVehicle(String vehicleId);

  Future<Result<List<ReferenceOption>, AppError>> getLanguages();
  Future<Result<List<ReferenceOption>, AppError>> getDateFormats();
  Future<Result<List<TimezoneOption>, AppError>> getTimezones();

  Future<Result<AppPreferences, AppError>> getAppPreferences();
  Future<Result<void, AppError>> updateAppPreferences(Map<String, Object?> payload);
}
