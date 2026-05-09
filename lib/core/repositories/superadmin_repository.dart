import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:open_vts/core/models/calendar_event_item.dart';
import 'package:open_vts/core/models/admin_list_item.dart';
import 'package:open_vts/core/models/admin_document_item.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/models/admin_settings.dart';
import 'package:open_vts/core/models/admin_vehicle_item.dart';
import 'package:open_vts/core/models/command_option.dart';
import 'package:open_vts/core/models/credit_log_item.dart';
import 'package:open_vts/core/models/map_vehicle_point.dart';
import 'package:open_vts/core/models/localization_settings.dart';
import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/core/models/pricing_plan.dart';
import 'package:open_vts/core/models/sent_command_item.dart';
import 'package:open_vts/core/models/ssl_certificate_item.dart';
import 'package:open_vts/core/models/server_overall_status.dart';
import 'package:open_vts/core/models/server_postgres_status.dart';
import 'package:open_vts/core/models/server_service_item.dart';
import 'package:open_vts/core/models/superadmin_adoption_graph.dart';
import 'package:open_vts/core/models/superadmin_profile.dart';
import 'package:open_vts/core/models/superadmin_recent_transaction.dart';
import 'package:open_vts/core/models/superadmin_recent_vehicle.dart';
import 'package:open_vts/core/models/superadmin_recent_user.dart';
import 'package:open_vts/core/models/superadmin_total_counts.dart';
import 'package:open_vts/core/models/ticket_list_item.dart';
import 'package:open_vts/core/models/ticket_message_item.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/core/models/vehicle_config.dart';
import 'package:open_vts/core/models/vehicle_details.dart';
import 'package:open_vts/core/models/vehicle_log_item.dart';
import 'package:open_vts/core/models/vehicle_location.dart';
import 'package:open_vts/core/models/vehicle_list_item.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_envelope.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/auth_repository.dart';
import 'package:open_vts/core/network/api_paths.dart';

class SuperadminRepository {
  final ApiClient api;

  SuperadminRepository({required this.api});

  Future<Result<List<AdminListItem>>> getAdmins({
    int? page,
    int? limit,
    String? status,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;
    if (status != null && status.trim().isNotEmpty) qp['status'] = status;

    final res = await api.get(
      SuperadminApiPaths.adminList,
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['admins', 'users']);
        final out = <AdminListItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(AdminListItem(it));
            } else if (it is Map) {
              out.add(AdminListItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminProfile>> getAdminProfile(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.adminDetails(adminId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(AdminProfile(_coerceMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<SuperadminProfile>> getSuperadminProfile({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.profile,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(SuperadminProfile(_coerceMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminProfile>> updateAdminProfile(
    String adminId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      SuperadminApiPaths.updateAdmin(adminId),
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(AdminProfile(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateAdminPassword(
    String adminId,
    String newPassword,
    String confirmPassword, {
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'adminid': adminId,
      'newpassword': newPassword,
      'confirmpassword': confirmPassword,
    };

    final res = await api.post(
      SuperadminApiPaths.adminPasswordUpdate,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateAdminStatus(
    String adminId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final primaryRes = await api.post(
      SuperadminApiPaths.activateAdmin(adminId),
      data: {'isActive': isActive},
      cancelToken: cancelToken,
    );

    if (primaryRes.isSuccess) {
      return Result.ok(null);
    }

    final err = primaryRes.error;
    if (err is ApiException && err.statusCode == 404) {
      final fallbackRes = await api.post(
        SuperadminApiPaths.adminStatusUpdate,
        data: {'adminid': adminId, 'status': isActive},
        cancelToken: cancelToken,
      );

      return fallbackRes.when(
        success: (_) => Result.ok(null),
        failure: (fallbackErr) => Result.fail(fallbackErr),
      );
    }

    return Result.fail(err ?? StateError('Unknown error'));
  }

  Future<Result<String>> uploadSuperadminFile({
    required String adminId,
    required String type,
    required Uint8List bytes,
    required String filename,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    final MediaType? mediaType =
        (contentType == null || contentType.trim().isEmpty)
        ? null
        : MediaType.parse(contentType);

    final form = FormData.fromMap({
      'type': type,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mediaType,
      ),
    });

    final res = await api.post(
      SuperadminApiPaths.upload(adminId),
      data: form,
      cancelToken: cancelToken,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Accept': 'application/json'},
      ),
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        final url = (map['url'] ?? map['path'] ?? '').toString();
        return Result.ok(url);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<String>> uploadSuperadminProfileImage({
    required String adminId,
    required Uint8List bytes,
    required String filename,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    return uploadSuperadminFile(
      adminId: adminId,
      type: 'PROFILE',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      cancelToken: cancelToken,
    );
  }

  Future<Result<void>> deleteSuperadminFile(
    String fileId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      SuperadminApiPaths.uploadDocById(fileId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SuperadminDocumentType>>> getDocumentTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.documentTypesForUser,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['data', 'documentTypes', 'types'],
        );
        final out = <SuperadminDocumentType>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(SuperadminDocumentType.fromJson(it));
            } else if (it is Map) {
              out.add(
                SuperadminDocumentType.fromJson(
                  Map<String, dynamic>.from(it.cast()),
                ),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> uploadDocument({
    required String associateType,
    required String associateId,
    required int docTypeId,
    required String title,
    required Uint8List fileBytes,
    required String filename,
    String? description,
    String? tags,
    String? expiryAt,
    bool isVisible = true,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    final MediaType? mediaType =
        (contentType == null || contentType.trim().isEmpty)
        ? null
        : MediaType.parse(contentType);

    final form = FormData.fromMap({
      'title': title,
      'docTypeId': docTypeId.toString(),
      'description': description?.trim().isNotEmpty == true
          ? description!.trim()
          : '',
      'tags': tags?.trim().isNotEmpty == true ? tags!.trim() : '',
      'AssociateType': associateType,
      'associateId': associateId,
      if (expiryAt != null && expiryAt.trim().isNotEmpty) 'expiryAt': expiryAt,
      'isVisible': isVisible,
      'File': MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
        contentType: mediaType,
      ),
    });

    final res = await api.post(
      SuperadminApiPaths.uploadDoc,
      data: form,
      cancelToken: cancelToken,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Accept': 'application/json'},
      ),
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateDocument({
    required String documentId,
    int? docTypeId,
    String? title,
    String? description,
    String? tags,
    String? expiryAt,
    bool? isVisible,
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    final MediaType? mediaType =
        (contentType == null || contentType.trim().isEmpty)
        ? null
        : MediaType.parse(contentType);

    final data = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (docTypeId != null) 'docTypeId': docTypeId.toString(),
      if (description != null) 'description': description.trim(),
      if (tags != null) 'tags': tags.trim(),
      if (expiryAt != null && expiryAt.trim().isNotEmpty) 'expiryAt': expiryAt,
      if (isVisible != null) 'isVisible': isVisible,
      if (fileBytes != null && filename != null)
        'File': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
          contentType: mediaType,
        ),
    };

    final res = await api.patch(
      SuperadminApiPaths.uploadDocById(documentId),
      data: FormData.fromMap(data),
      cancelToken: cancelToken,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {'Accept': 'application/json'},
      ),
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> updateCompanyConfig(
    String companyId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      SuperadminApiPaths.companyConfig(companyId),
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_extractMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> updateCompanyDetails(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      SuperadminApiPaths.companyDetails,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_extractMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> deleteAdmin(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      SuperadminApiPaths.deleteAdmin(adminId),
      data: <String, dynamic>{'adminId': adminId},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> deleteVehicle(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      SuperadminApiPaths.deleteVehicle(vehicleId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createAdmin(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      SuperadminApiPaths.createAdmin,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.mapTelemetry,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['telemetry', 'vehicles', 'points', 'items'],
        );
        final out = <MapVehiclePoint>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(MapVehiclePoint(it));
            } else if (it is Map) {
              out.add(MapVehiclePoint(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SslCertificateItem>>> getSslCertificates({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.domainList,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = SslCertificateItem.fromResponse(data);
        if (list.isNotEmpty) return Result.ok(list);

        final single = _coerceMap(data);
        if (single.isNotEmpty) {
          final candidate = SslCertificateItem(single);
          if (candidate.domain.trim().isNotEmpty) {
            return Result.ok(<SslCertificateItem>[candidate]);
          }
        }
        return Result.ok(const <SslCertificateItem>[]);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<ServerOverallStatus>> getServerOverallStatus({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.serverOverview,
      queryParameters: <String, dynamic>{
        'rk': DateTime.now().millisecondsSinceEpoch,
      },
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final level1 = _extractMap(data);
        final level2 = _extractMapFromNested(level1);
        final payload = level2.isNotEmpty
            ? level2
            : level1.isNotEmpty
            ? level1
            : _coerceMap(data);
        return Result.ok(ServerOverallStatus(payload));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<ServerPostgresStatus>> getServerPostgresStatus({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.healthDatabases,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final list = _toMapList(
          root['databases'] ?? root['dbs'] ?? root['items'] ?? root['data'],
        );
        if (list != null && list.isNotEmpty) {
          Map<String, dynamic> candidate = list.first;
          for (final it in list) {
            final name = (it['name'] ?? it['dbName'] ?? '')
                .toString()
                .toLowerCase();
            if (name.contains('primary') ||
                name.contains('openvts') ||
                name.contains('open_vts') ||
                name.contains('fleetstack')) {
              candidate = it;
              break;
            }
          }
          return Result.ok(ServerPostgresStatus(candidate));
        }
        return Result.ok(ServerPostgresStatus(_extractMap(data)));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<ServerPostgresStatus>> getLogsDbStatus({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.healthLogsDb,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final payload = _extractMap(data);
        return Result.ok(
          ServerPostgresStatus.fromHealthPayload('logs-db', payload),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<ServerPostgresStatus>> getAddressDbStatus({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.healthAddressDb,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final payload = _extractMap(data);
        return Result.ok(
          ServerPostgresStatus.fromHealthPayload('address-db', payload),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<ServerServiceItem>>> getServerServices({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.serverOverview,
      queryParameters: <String, dynamic>{
        'rk': DateTime.now().millisecondsSinceEpoch,
      },
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(ServerServiceItem.listFromOverview(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getServerOverviewRaw({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.serverOverview,
      queryParameters: <String, dynamic>{
        'rk': DateTime.now().millisecondsSinceEpoch,
      },
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(_coerceMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<CalendarEventItem>>> getCalendarEvents({
    required String from,
    required String to,
    String? typeFilter,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{'from': from, 'to': to};
    if (typeFilter != null && typeFilter.trim().isNotEmpty) {
      qp['type'] = typeFilter.trim();
    }

    final res = await api.get(
      SuperadminApiPaths.calendarEvents,
      queryParameters: qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final out = <CalendarEventItem>[];
        final list = _extractList(
          data,
          extraKeys: const ['events', 'calendarEvents', 'rows'],
        );
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(CalendarEventItem(it));
            } else if (it is Map) {
              out.add(CalendarEventItem(Map<String, dynamic>.from(it.cast())));
            }
          }
          return Result.ok(out);
        }

        // Tolerate map-by-date shape: {"2025-06-15": [ ...events ]}.
        final root = _coerceMap(data);
        root.forEach((k, v) {
          if (v is List) {
            for (final e in v) {
              if (e is Map<String, dynamic>) {
                out.add(CalendarEventItem(<String, dynamic>{'date': k, ...e}));
              } else if (e is Map) {
                out.add(
                  CalendarEventItem(<String, dynamic>{
                    'date': k,
                    ...Map<String, dynamic>.from(e.cast()),
                  }),
                );
              }
            }
          }
        });
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getCalendarDayDetails({
    required String date,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.calendarDay,
      queryParameters: {'date': date},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_coerceMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getHealthRaw({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(PublicApiPaths.health, cancelToken: cancelToken);
    return res.when(
      success: (data) => Result.ok(_coerceMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminVehicleItem>>> getAdminVehicles(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.adminVehicles(adminId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['vehicles']);
        final out = <AdminVehicleItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(AdminVehicleItem(it));
            } else if (it is Map) {
              out.add(AdminVehicleItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<CreditLogItem>>> getCreditLogs(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.creditLogs(adminId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['logs', 'creditLogs'],
        );
        final out = <CreditLogItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(CreditLogItem(it));
            } else if (it is Map) {
              out.add(CreditLogItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminDocumentItem>>> getAdminDocuments(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.documents(adminId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['documents', 'docs', 'files'],
        );
        final out = <AdminDocumentItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(AdminDocumentItem(it));
            } else if (it is Map) {
              out.add(AdminDocumentItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminSettings>> getAdminSettings(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.settings(adminId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(AdminSettings(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminSettings>> updateAdminSettings(
    String adminId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      SuperadminApiPaths.settings(adminId),
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(AdminSettings(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<LocalizationSettings>> getLocalizationSettings({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.localization,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final level1 = _extractMapFromNested(data);
        final level2 = _extractMapFromNested(level1);
        return Result.ok(
          LocalizationSettings(level2.isNotEmpty ? level2 : level1),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateLocalizationSettings(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      SuperadminApiPaths.localization,
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getSmtpConfig({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.smtpSettings,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final level1 = _extractMapFromNested(data);
        final level2 = _extractMapFromNested(level1);
        return Result.ok(level2.isNotEmpty ? level2 : level1);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateSmtpConfig(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      SuperadminApiPaths.smtpSettings,
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> sendTestSmtp({
    required String email,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      SuperadminApiPaths.testSmtp,
      data: <String, dynamic>{'email': email},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  /// Capability check for the superadmin flow:
  /// Postman collection exposes pricing plans under `/admin/pricingplans`
  /// (not `/superadmin/*`). This checks whether the current token can access it.
  ///
  /// Contract:
  /// - 200 => ok(true)
  /// - 401/403 => ok(false)
  /// - other failures => failure (do not treat as false)
  Future<Result<bool>> canAccessAdminPricingPlans({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.pricingPlans,
      queryParameters: const {'limit': 1},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(true),
      failure: (err) {
        if (err is ApiException &&
            (err.statusCode == 401 || err.statusCode == 403)) {
          return Result.ok(false);
        }
        return Result.fail(err);
      },
    );
  }

  /// Pricing plans (Postman collection exposes these under `/admin/pricingplans`,
  /// not `/superadmin/*`).
  Future<Result<List<PricingPlan>>> getPricingPlans({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.pricingPlans,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data);
        final out = <PricingPlan>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(PricingPlan(it));
            } else if (it is Map) {
              out.add(PricingPlan(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<VehicleListItem>>> getVehicles({
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;

    final res = await api.get(
      SuperadminApiPaths.vehicles,
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final payload = _extractMap(data);

        List? list = payload['vehicles'] is List
            ? payload['vehicles'] as List
            : null;
        list ??= root['vehicles'] is List ? root['vehicles'] as List : null;
        list ??= _extractList(
          data,
          extraKeys: const ['vehicles', 'items', 'data'],
        );

        final out = <VehicleListItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(VehicleListItem(it));
            } else if (it is Map) {
              out.add(VehicleListItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<VehicleDetails>> getVehicleDetails(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final baseRes = await api.get(
      SuperadminApiPaths.vehicleDetails(vehicleId),
      cancelToken: cancelToken,
    );

    if (baseRes.isFailure) {
      return Result.fail(baseRes.error!);
    }

    final baseValue = _coerceMap(baseRes.data);
    final basePayload = _extractMap(baseValue);
    final nestedVehicle = _coerceMap(basePayload['data']);
    final vehicle = nestedVehicle.isNotEmpty ? nestedVehicle : basePayload;
    final imei = _string(
      vehicle['imei'] ??
          vehicle['deviceImei'] ??
          vehicle['device_imei'] ??
          (_coerceMap(vehicle['device']))['imei'],
    );

    var mergedVehicle = Map<String, dynamic>.from(vehicle);
    var telemetry = const <String, dynamic>{};

    if (imei.isNotEmpty) {
      final detailRes = await api.get(
        SuperadminApiPaths.vehicleByImeiDetails(imei),
        cancelToken: cancelToken,
      );

      if (detailRes.isSuccess) {
        final detailValue = _coerceMap(detailRes.data);
        final detailPayload = _extractMap(detailValue);
        final nested = _coerceMap(detailPayload['data']);
        final detailVehicle = _coerceMap(
          detailPayload['vehicle'] ?? nested['vehicle'],
        );
        if (detailVehicle.isNotEmpty) {
          mergedVehicle = _deepMergeMaps(mergedVehicle, detailVehicle);
        }

        final detailTelemetry = _coerceMap(
          detailPayload['telemetry'] ?? nested['telemetry'],
        );
        if (detailTelemetry.isNotEmpty) {
          telemetry = detailTelemetry;
        }
      }
    }

    return Result.ok(
      VehicleDetails({
        'data': {'vehicle': mergedVehicle, 'telemetry': telemetry},
      }),
    );
  }

  Future<Result<List<VehicleLogItem>>> getVehicleLogs(
    String imei, {
    String? from,
    String? to,
    String? query,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (from != null && from.trim().isNotEmpty) qp['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty) qp['to'] = to.trim();
    if (limit != null) qp['limit'] = limit;
    if (page != null) qp['page'] = page;
    if (query != null && query.trim().isNotEmpty) qp['search'] = query.trim();

    final res = await api.get(
      SuperadminApiPaths.vehicleByImeiLogs(imei),
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['logs', 'items', 'events', 'history'],
        );
        final out = <VehicleLogItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(VehicleLogItem(it));
            } else if (it is Map) {
              out.add(VehicleLogItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<VehicleLocation>> getVehicleLocation(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.vehicleByImeiDetails(imei),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final payload = _extractMap(data);
        final locationCandidate = payload['location'] ?? payload['position'];

        final loc = locationCandidate is Map
            ? Map<String, dynamic>.from(locationCandidate.cast())
            : Map<String, dynamic>.from(payload);

        if (loc['updatedAt'] == null && payload['updatedAt'] != null) {
          loc['updatedAt'] = payload['updatedAt'];
        }
        if (loc['updatedAt'] == null && root['updatedAt'] != null) {
          loc['updatedAt'] = root['updatedAt'];
        }

        return Result.ok(VehicleLocation(loc));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<VehicleDetails>> getSuperadminVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.vehicleByImeiDetails(imei),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final payload = _extractMap(data);
        final nested = _coerceMap(payload['data']);
        final nestedFromRoot = _extractMapFromNested(payload);

        final vehicle = _coerceMap(
          payload['vehicle'] ??
              nested['vehicle'] ??
              nestedFromRoot['vehicle'] ??
              root['vehicle'],
        );
        final telemetry = _coerceMap(
          payload['telemetry'] ??
              nested['telemetry'] ??
              nestedFromRoot['telemetry'] ??
              root['telemetry'],
        );

        final mergedVehicle = vehicle.isNotEmpty
            ? vehicle
            : (nested.isNotEmpty
                  ? nested
                  : (nestedFromRoot.isNotEmpty
                        ? nestedFromRoot
                        : (payload.isNotEmpty ? payload : root)));

        return Result.ok(
          VehicleDetails({
            'data': {'vehicle': mergedVehicle, 'telemetry': telemetry},
          }),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      GeocodingApiPaths.reverse,
      queryParameters: <String, dynamic>{'lat': lat, 'lng': lng},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final level1 = _extractMap(data);
        final level2 = _extractMapFromNested(level1);
        final level3 = _extractMapFromNested(level2);

        final address = _firstNonEmpty([
          level3['address'],
          level2['address'],
          level1['address'],
          root['address'],
          level3['formattedAddress'],
          level2['formattedAddress'],
          level1['formattedAddress'],
          root['formattedAddress'],
          level3['display_name'],
          level2['display_name'],
          level1['display_name'],
          root['display_name'],
        ]);

        return Result.ok(address.isEmpty ? 'Address unavailable' : address);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<CommandOption>>> getCommandOptions(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.commandTypes,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['commandtypes', 'commands', 'items'],
        );
        final out = <CommandOption>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(CommandOption(it));
            } else if (it is Map) {
              out.add(CommandOption(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> sendCommand(
    String imei,
    String commandCode,
    Map<String, dynamic>? payloadJson,
    bool confirmFlag, {
    CancelToken? cancelToken,
  }) async {
    final body = <String, dynamic>{
      'imei': imei,
      'command': commandCode,
      'payload': payloadJson ?? <String, dynamic>{},
      'confirm': confirmFlag,
    };

    final res = await api.post(
      SuperadminApiPaths.customCommands,
      data: body,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SentCommandItem>>> getRecentCommands(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.customCommands,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['commands', 'customcommands', 'items'],
        );
        final out = <SentCommandItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(SentCommandItem(it));
            } else if (it is Map) {
              out.add(SentCommandItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<VehicleConfig>> getVehicleConfig(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.vehicleConfig(vehicleId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(VehicleConfig(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateVehicleConfig(
    String vehicleId,
    VehicleConfigUpdate payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      AdminApiPaths.vehicleConfig(vehicleId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<TicketListItem>>> getTickets({
    String? status,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (status != null && status.trim().isNotEmpty) qp['status'] = status;
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;

    final res = await api.get(
      SuperadminApiPaths.supportTickets,
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['tickets']);
        final out = <TicketListItem>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(TicketListItem(it));
            } else if (it is Map) {
              out.add(TicketListItem(Map<String, dynamic>.from(it.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createTicket({
    required String message,
    required String priority,
    required String category,
    String? subject,
    String? adminId,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'message': message,
      'priority': priority,
      'category': category,
    };
    if (subject != null && subject.trim().isNotEmpty) {
      payload['subject'] = subject.trim();
    }
    if (adminId != null && adminId.trim().isNotEmpty) {
      payload['adminId'] = adminId.trim();
    }
    final res = await api.post(
      SuperadminApiPaths.supportTickets,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  /// Roles endpoint is not stable across deployments.
  /// Probe known candidates and normalize into a list of role maps.
  Future<Result<List<Map<String, dynamic>>>> getRoles({
    CancelToken? cancelToken,
  }) async {
    final endpoints = <String>[
      ApiPaths.superadminRoles,
      ApiPaths.superadminRoleList,
      ApiPaths.adminRoles,
      ApiPaths.adminRoleList,
    ];

    for (final endpoint in endpoints) {
      final res = await api.get(endpoint, cancelToken: cancelToken);

      if (res.isSuccess) {
        final data = res.data;
        final list = _extractList(
          data,
          extraKeys: const ['roles', 'items', 'rows', 'permissions'],
        );

        final out = <Map<String, dynamic>>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              out.add(it);
            } else if (it is Map) {
              out.add(Map<String, dynamic>.from(it.cast()));
            }
          }
          return Result.ok(out);
        }

        final single = _extractMapFromNested(data);
        if (single.isNotEmpty) {
          return Result.ok(<Map<String, dynamic>>[single]);
        }
        return Result.ok(const <Map<String, dynamic>>[]);
      }

      final err = res.error;
      if (err is ApiException && err.statusCode == 404) {
        continue;
      }
      if (err != null) return Result.fail(err);
      return Result.fail(const ApiException(message: 'Failed to load roles.'));
    }

    return Result.ok(const <Map<String, dynamic>>[]);
  }

  Future<Result<Map<String, dynamic>>> getTicketDetails(
    String ticketId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.supportTicketDetails(ticketId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final level1 = _extractMap(data);
        final level2 = _extractMapFromNested(level1);
        final payload = level2.isNotEmpty ? level2 : level1;
        return Result.ok(payload);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<TicketMessageItem?>> sendTicketMessage(
    String ticketId,
    String message, {
    bool internal = false,
    PickedFilePayload? attachment,
    CancelToken? cancelToken,
  }) async {
    final endpoint = ApiPaths.superadminSupportTicketMessages(ticketId);
    Result<dynamic> res;

    if (attachment != null) {
      final form = FormData.fromMap({
        'message': message,
        if (internal) 'type': 'INTERNAL',
        'file': MultipartFile.fromBytes(
          attachment.bytes,
          filename: attachment.filename,
        ),
      });
      res = await api.post(
        endpoint,
        data: form,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
    } else {
      final payload = <String, dynamic>{'message': message};
      if (internal) {
        payload['type'] = 'INTERNAL';
      }
      res = await api.post(endpoint, data: payload, cancelToken: cancelToken);
    }

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        if (map.isNotEmpty) {
          return Result.ok(TicketMessageItem(map));
        }
        return Result.ok(null);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateTicketStatus(
    String ticketId,
    String status, {
    CancelToken? cancelToken,
  }) async {
    final endpoint = ApiPaths.superadminSupportTicketStatus(ticketId);
    final payload = <String, dynamic>{'status': status};

    // Prefer PATCH (matches admin endpoints). Fallback to POST for legacy.
    final patchRes = await api.patch(
      endpoint,
      data: payload,
      cancelToken: cancelToken,
    );

    if (patchRes.isSuccess) {
      return Result.ok(null);
    }

    final err = patchRes.error;
    if (err is ApiException &&
        (err.statusCode == 404 || err.statusCode == 405)) {
      final postRes = await api.post(
        endpoint,
        data: payload,
        cancelToken: cancelToken,
      );
      return postRes.when(
        success: (_) => Result.ok(null),
        failure: (e) => Result.fail(e),
      );
    }

    return Result.fail(err ?? Exception('Update status failed'));
  }

  Future<Result<SuperadminAdoptionGraph>> getAdoptionGraph({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.dashboardAdoptionGraph,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(SuperadminAdoptionGraph(_coerceMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  /// Vertical slice: Superadmin dashboard recent vehicles.
  Future<Result<List<SuperadminRecentVehicle>>> getRecentVehicles({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.dashboardRecentVehicles,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data);
        final vehicles = <SuperadminRecentVehicle>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              vehicles.add(SuperadminRecentVehicle(it));
            } else if (it is Map) {
              vehicles.add(
                SuperadminRecentVehicle(Map<String, dynamic>.from(it.cast())),
              );
            }
          }
        }
        return Result.ok(vehicles);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<SuperadminTotalCounts>> getTotalCounts({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.dashboardTotalCounts,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(SuperadminTotalCounts(_coerceMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SuperadminRecentUser>>> getRecentUsers({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.dashboardRecentUsers,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['users']);
        final users = <SuperadminRecentUser>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              users.add(SuperadminRecentUser(it));
            } else if (it is Map) {
              users.add(
                SuperadminRecentUser(Map<String, dynamic>.from(it.cast())),
              );
            }
          }
        }
        return Result.ok(users);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SuperadminRecentTransaction>>> getRecentTransactions({
    int? page,
    int? limit,
    String? adminId,
    String? from,
    String? to,
    String? status,
    String? q,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;
    if (adminId != null && adminId.isNotEmpty) qp['adminId'] = adminId;
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    if (status != null && status.isNotEmpty) qp['status'] = status;
    if (q != null && q.isNotEmpty) qp['q'] = q;

    final res = await api.get(
      SuperadminApiPaths.transactions,
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['transactions', 'records'],
        );
        final transactions = <SuperadminRecentTransaction>[];
        if (list != null) {
          for (final it in list) {
            if (it is Map<String, dynamic>) {
              transactions.add(SuperadminRecentTransaction(it));
            } else if (it is Map) {
              transactions.add(
                SuperadminRecentTransaction(
                  Map<String, dynamic>.from(it.cast()),
                ),
              );
            }
          }
        }
        return Result.ok(transactions);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<Map<String, dynamic>>>> getAdminActivityLogs(
    String adminId, {
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      SuperadminApiPaths.adminActivityLogs(adminId),
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['items', 'logs', 'activities'],
        );
        final items = <Map<String, dynamic>>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              items.add(item);
            } else if (item is Map) {
              items.add(Map<String, dynamic>.from(item.cast()));
            }
          }
        }
        return Result.ok(items);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> assignCredits(
    String adminId, {
    required int credits,
    required String activity,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      SuperadminApiPaths.assignCredits(adminId),
      data: {'credits': credits.toString(), 'activity': activity},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<String>> loginAsAdmin(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      SuperadminApiPaths.adminLogin(adminId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final token = AuthRepository.extractToken(data);
        if (token == null || token.trim().isEmpty) {
          return Result.fail(
            ApiException(
              statusCode: 401,
              message: 'Token not found in admin login response.',
              details: data,
            ),
          );
        }
        return Result.ok(token);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> recordManualTransaction(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      SuperadminApiPaths.transactionsManual,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    return ApiEnvelope.list(
      data,
      listKeys: <String>[
        'data',
        'items',
        'result',
        'results',
        ...extraKeys,
        'vehicles',
      ],
      maxDepth: 5,
    );
  }

  Map<String, dynamic> _coerceMap(Object? data) {
    return ApiEnvelope.asMap(data);
  }

  Map<String, dynamic> _extractMap(Object? data) {
    return ApiEnvelope.payload(
      data,
      mapKeys: const [
        'data',
        'item',
        'result',
        'ticket',
        'payload',
        'response',
        'config',
        'settings',
      ],
    );
  }

  Map<String, dynamic> _extractMapFromNested(Object? data) {
    return ApiEnvelope.nestedMap(
      data,
      mapKeys: const [
        'data',
        'item',
        'result',
        'items',
        'config',
        'settings',
        'payload',
      ],
      maxDepth: 5,
    );
  }

  List<Map<String, dynamic>>? _toMapList(Object? value) {
    final list = ApiEnvelope.mapList(value, maxDepth: 3);
    if (list.isEmpty) return null;
    return list;
  }

  String _string(Object? value) {
    return ApiEnvelope.text(value);
  }

  String _firstNonEmpty(List<Object?> values) {
    return ApiEnvelope.firstNonEmpty(values);
  }

  Map<String, dynamic> _deepMergeMaps(
    Map<String, dynamic> base,
    Map<String, dynamic> incoming,
  ) {
    final merged = Map<String, dynamic>.from(base);

    incoming.forEach((key, value) {
      final existing = merged[key];
      if (existing is Map && value is Map) {
        merged[key] = _deepMergeMaps(_coerceMap(existing), _coerceMap(value));
      } else {
        merged[key] = value;
      }
    });

    return merged;
  }

  Future<Result<void>> requestEmailOtp({CancelToken? cancelToken}) async {
    final res = await api.post(
      SuperadminApiPaths.profileVerifyEmailRequest,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> requestWhatsappOtp({CancelToken? cancelToken}) async {
    final res = await api.post(
      SuperadminApiPaths.profileVerifyWhatsappRequest,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }
}
