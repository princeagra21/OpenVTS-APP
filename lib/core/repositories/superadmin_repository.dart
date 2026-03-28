import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/calendar_event_item.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/core/models/admin_document_item.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/models/admin_settings.dart';
import 'package:fleet_stack/core/models/admin_vehicle_item.dart';
import 'package:fleet_stack/core/models/command_option.dart';
import 'package:fleet_stack/core/models/credit_log_item.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/models/localization_settings.dart';
import 'package:fleet_stack/core/models/pricing_plan.dart';
import 'package:fleet_stack/core/models/sent_command_item.dart';
import 'package:fleet_stack/core/models/ssl_certificate_item.dart';
import 'package:fleet_stack/core/models/server_overall_status.dart';
import 'package:fleet_stack/core/models/server_postgres_status.dart';
import 'package:fleet_stack/core/models/server_service_item.dart';
import 'package:fleet_stack/core/models/superadmin_adoption_graph.dart';
import 'package:fleet_stack/core/models/superadmin_profile.dart';
import 'package:fleet_stack/core/models/superadmin_recent_transaction.dart';
import 'package:fleet_stack/core/models/superadmin_recent_vehicle.dart';
import 'package:fleet_stack/core/models/superadmin_recent_user.dart';
import 'package:fleet_stack/core/models/superadmin_total_counts.dart';
import 'package:fleet_stack/core/models/ticket_list_item.dart';
import 'package:fleet_stack/core/models/ticket_message_item.dart';
import 'package:fleet_stack/core/models/vehicle_config.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/models/vehicle_log_item.dart';
import 'package:fleet_stack/core/models/vehicle_location.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/repositories/auth_repository.dart';

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
      '/superadmin/adminlist',
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
      '/superadmin/admin/$adminId',
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
    final res = await api.get('/superadmin/profile', cancelToken: cancelToken);

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
      '/superadmin/updateadmin/$adminId',
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
      '/superadmin/adminpasswordupdate',
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
    final res = await api.post(
      '/superadmin/activateadmin/$adminId',
      data: <String, dynamic>{'isActive': isActive},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> deleteAdmin(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      '/superadmin/deleteadmin/$adminId',
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
      '/superadmin/vehicles/$vehicleId',
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
      '/superadmin/map-telemetry',
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
      '/superadmin/domainlist',
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
      '/superadmin/server/overview',
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
    final res = await api.get('/health/databases', cancelToken: cancelToken);
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
            if (name.contains('primary') || name.contains('fleetstack')) {
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
    final res = await api.get('/health/logs-db', cancelToken: cancelToken);
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
    final res = await api.get('/health/address-db', cancelToken: cancelToken);
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
      '/superadmin/server/overview',
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
      '/superadmin/server/overview',
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
      '/superadmin/calendar/events',
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
      '/superadmin/calendar/day',
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
    final res = await api.get('/health', cancelToken: cancelToken);
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
      '/superadmin/adminvehicles/$adminId',
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
      '/superadmin/creditlogs/$adminId',
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
      '/superadmin/documents/$adminId',
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
      '/superadmin/settings/$adminId',
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
      '/superadmin/settings/$adminId',
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
      '/superadmin/localization',
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
      '/superadmin/localization',
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
      '/superadmin/smtpsettings',
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
      '/superadmin/smtpsettings',
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
      '/superadmin/testsmtp',
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
      '/admin/pricingplans',
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
    final res = await api.get('/admin/pricingplans', cancelToken: cancelToken);

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
      '/superadmin/vehicles',
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
      '/superadmin/vehicles/$vehicleId',
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
        '/superadmin/vehicles/by-imei/$imei/details',
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
      '/superadmin/vehicles/by-imei/$imei/logs',
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
      '/superadmin/vehicles/by-imei/$imei/details',
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

  Future<Result<List<CommandOption>>> getCommandOptions(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/superadmin/commandtypes',
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
      '/superadmin/customcommands',
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
      '/superadmin/customcommands',
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
      '/admin/vehicles/$vehicleId/config',
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
      '/admin/vehicles/$vehicleId/config',
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
      '/superadmin/support/tickets',
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
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/superadmin/support/tickets',
      data: <String, dynamic>{
        'message': message,
        'priority': priority,
        'category': category,
      },
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
    const endpoints = <String>[
      '/superadmin/roles',
      '/superadmin/rolelist',
      '/admin/roles',
      '/admin/rolelist',
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
      '/superadmin/support/tickets/$ticketId',
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
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{'message': message};
    if (internal) {
      payload['type'] = 'INTERNAL';
    }
    final res = await api.post(
      '/superadmin/support/tickets/$ticketId/messages',
      data: payload,
      cancelToken: cancelToken,
    );

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
    final res = await api.post(
      '/superadmin/support/tickets/$ticketId/status',
      data: <String, dynamic>{'status': status},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<SuperadminAdoptionGraph>> getAdoptionGraph({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/superadmin/dashboard/adoptiongraph',
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
      '/superadmin/dashboard/recentvehicles',
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
      '/superadmin/dashboard/totalcounts',
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
      '/superadmin/dashboard/recentusers',
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
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (page != null) qp['page'] = page;
    if (limit != null) qp['limit'] = limit;

    final res = await api.get(
      '/superadmin/transactions',
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

  Future<Result<String>> loginAsAdmin(
    String adminId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/superadmin/adminlogin/$adminId',
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
      '/superadmin/transactions/manual',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    if (data is List) return data;

    final keys = <String>[
      'data',
      'items',
      'result',
      'results',
      ...extraKeys,
      'vehicles',
    ];

    List? walk(Object? node, int depth) {
      if (depth > 5) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final m = _coerceMap(node);
      for (final key in keys) {
        final value = m[key];
        if (value is List) return value;
      }

      for (final value in m.values) {
        if (value is Map || value is List) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }
      return null;
    }

    return walk(data, 0);
  }

  Map<String, dynamic> _coerceMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _extractMap(Object? data) {
    final m = _coerceMap(data);
    final candidates = [m['data'], m['item'], m['result']];
    for (final c in candidates) {
      if (c is Map<String, dynamic>) return c;
      if (c is Map) return Map<String, dynamic>.from(c.cast());
    }
    return m;
  }

  Map<String, dynamic> _extractMapFromNested(Object? data) {
    final m = _coerceMap(data);
    final candidates = [
      m['data'],
      m['item'],
      m['result'],
      m['items'],
      m['config'],
      m['settings'],
    ];
    for (final c in candidates) {
      if (c is Map<String, dynamic>) return c;
      if (c is Map) return Map<String, dynamic>.from(c.cast());
    }
    return m;
  }

  List<Map<String, dynamic>>? _toMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Object>()
          .map((e) => e is Map ? _coerceMap(e) : const <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
    }
    return null;
  }

  String _string(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
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
}
