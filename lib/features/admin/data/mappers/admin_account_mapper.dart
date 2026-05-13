import 'package:open_vts/core/api/api_envelope.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

class AdminAccountMapper {
  const AdminAccountMapper();

  List<AdminUserListItem> users(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['userslist', 'users', 'items', 'data'])
        .map(AdminUserListItem.fromRaw)
        .toList(growable: false);
  }

  AdminUserDetails userDetails(ApiResponse<Map<String, Object?>> response) {
    return AdminUserDetails.fromRaw(_payloadMap(response.payload));
  }

  List<AdminVehicleListItem> vehicles(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['vehicles', 'items', 'data'])
        .map(AdminVehicleListItem.fromRaw)
        .toList(growable: false);
  }

  List<AdminDriverListItem> drivers(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['drivers', 'items', 'data'])
        .map(AdminDriverListItem.fromRaw)
        .toList(growable: false);
  }

  List<AdminDocumentItem> documents(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['documents', 'items', 'data'])
        .map(AdminDocumentItem.new)
        .toList(growable: false);
  }

  List<SuperadminDocumentType> documentTypes(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['data', 'documentTypes', 'types'])
        .map(SuperadminDocumentType.fromJson)
        .toList(growable: false);
  }

  List<AdminTicketListItem> tickets(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['tickets', 'items', 'data'])
        .map(AdminTicketListItem.new)
        .toList(growable: false);
  }

  List<Map<String, Object?>> activityLogs(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['items', 'logs', 'activities'])
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }

  List<AdminTransactionItem> payments(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['payments', 'transactions', 'items', 'data'])
        .map(AdminTransactionItem.fromRaw)
        .toList(growable: false);
  }

  AdminProfile profile(ApiResponse<Map<String, Object?>> response) {
    return AdminProfile(Map<String, dynamic>.from(_payloadMap(response.payload)));
  }

  Map<String, Object?> companyDetails(ApiResponse<Map<String, Object?>> response) {
    return Map<String, Object?>.from(_payloadMap(response.payload));
  }

  String loginToken(ApiResponse<Map<String, Object?>> response) {
    return _extractToken(response.payload) ?? '';
  }

  String uploadedFileUrl(ApiResponse<Map<String, Object?>> response) {
    final map = _payloadMap(response.payload);
    return (map['url'] ?? map['path'] ?? '').toString();
  }

  List<AdminLinkedVehicle> linkedVehicles(ApiResponse<Map<String, Object?>> response) {
    return _mapList(response.payload, const ['vehicles', 'items', 'data'])
        .map(AdminLinkedVehicle.fromJson)
        .toList(growable: false);
  }

  Map<String, Object?> _payloadMap(Object? value) {
    final nested = ApiEnvelope.payload(
      value,
      mapKeys: const ['data', 'item', 'user', 'result', 'settings', 'config', 'payload', 'response'],
    );
    if (nested.isNotEmpty) return Map<String, Object?>.from(nested);
    return ApiEnvelope.asMap(value);
  }

  List<Map<String, Object?>> _mapList(Object? value, List<String> keys) {
    return ApiEnvelope.mapList(value, listKeys: keys)
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }

  String? _extractToken(Object? value) {
    final map = ApiEnvelope.asMap(value);
    if (map.isEmpty) return null;
    String? asToken(Object? candidate) {
      if (candidate is String && candidate.trim().isNotEmpty) return candidate.trim();
      return null;
    }

    final direct = asToken(map['token'] ?? map['accessToken'] ?? map['access_token']);
    if (direct != null) return direct;

    for (final key in const ['data', 'result', 'item', 'payload', 'response']) {
      final nested = map[key];
      if (nested is Map) {
        final token = _extractToken(nested);
        if (token != null) return token;
      } else if (nested is List) {
        for (final item in nested) {
          final token = _extractToken(item);
          if (token != null) return token;
        }
      }
    }
    return null;
  }
}
