import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_linked_vehicle.dart';
import 'package:fleet_stack/core/models/superadmin_document_type.dart';
import 'package:fleet_stack/core/models/admin_document_item.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

class AdminUsersRepository {
  final ApiClient api;

  const AdminUsersRepository({required this.api});

  Future<Result<AdminUserListItem>> createUser({
    required String name,
    required String email,
    required String mobilePrefix,
    required String mobileNumber,
    required String username,
    required String password,
    required String companyName,
    required String address,
    required String countryCode,
    required String stateCode,
    required String city,
    required String pincode,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'mobilePrefix': mobilePrefix.trim(),
      'mobileNumber': mobileNumber.trim(),
      'username': username.trim(),
      'password': password,
      'companyName': companyName.trim(),
      'address': address.trim(),
      'countryCode': countryCode.trim(),
      'stateCode': stateCode.trim(),
      'city': city.trim(),
      'pincode': pincode.trim(),
    };

    final res = await api.post(
      '/admin/users',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        return Result.ok(AdminUserListItem.fromRaw(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminUserListItem>>> getUsers({
    String? search,
    String? status,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;
    query['rk'] = DateTime.now().millisecondsSinceEpoch;

    final res = await api.get(
      '/admin/users',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['userslist', 'users', 'items'],
        );
        final users = list
            .whereType<Map>()
            .map(
              (item) => AdminUserListItem.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();
        return Result.ok(users);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminUserDetails>> getUserDetails(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/users/$userId', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        return Result.ok(AdminUserDetails.fromRaw(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<String>> loginAsUser(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/userlogin/$userId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final token = _extractToken(data);
        if (token == null || token.trim().isEmpty) {
          return Result.fail(
            ApiException(
              statusCode: 401,
              message: 'Token not found in user login response.',
              details: data,
            ),
          );
        }
        return Result.ok(token);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminVehicleListItem>>> getUserLinkedVehicles(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/linkvehicles/$userId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['vehicles', 'items', 'data'],
        );
        return Result.ok(
          list
              .whereType<Map>()
              .map(
                (item) => AdminVehicleListItem.fromRaw(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item.cast()),
                ),
              )
              .toList(),
        );
      },
      failure: (err) async {
        // Backward-compatible fallback for APIs that expect query param form.
        final fallback = await api.get(
          '/admin/linkvehicles',
          queryParameters: <String, dynamic>{'userId': userId},
          cancelToken: cancelToken,
        );
        return fallback.when(
          success: (data) {
            final list = _extractList(
              data,
              listKeys: const ['vehicles', 'items', 'data'],
            );
            return Result.ok(
              list
                  .whereType<Map>()
                  .map(
                    (item) => AdminVehicleListItem.fromRaw(
                      item is Map<String, dynamic>
                          ? item
                          : Map<String, dynamic>.from(item.cast()),
                    ),
                  )
                  .toList(),
            );
          },
          failure: (_) => Result.fail(err),
        );
      },
    );
  }

  Future<Result<List<AdminVehicleListItem>>> getUnlinkedVehicles({
    String? userId,
    CancelToken? cancelToken,
  }) async {
    Future<Result<List<AdminVehicleListItem>>> parseResult(
      Future<Result<dynamic>> req,
    ) async {
      final res = await req;
      return res.when(
        success: (data) {
          final list = _extractList(
            data,
            listKeys: const ['vehicles', 'items', 'data'],
          );
          return Result.ok(
            list
                .whereType<Map>()
                .map(
                  (item) => AdminVehicleListItem.fromRaw(
                    item is Map<String, dynamic>
                        ? item
                        : Map<String, dynamic>.from(item.cast()),
                  ),
                )
                .toList(),
          );
        },
        failure: (err) => Result.fail(err),
      );
    }

    final first = await parseResult(
      api.get('/admin/unlinkvehicles', cancelToken: cancelToken),
    );
    if (first is Success<List<AdminVehicleListItem>>) return first;

    if (userId != null && userId.trim().isNotEmpty) {
      final byPath = await parseResult(
        api.get('/admin/unlinkvehicles/$userId', cancelToken: cancelToken),
      );
      if (byPath is Success<List<AdminVehicleListItem>>) return byPath;

      final byQuery = await parseResult(
        api.get(
          '/admin/unlinkvehicles',
          queryParameters: <String, dynamic>{'userId': userId},
          cancelToken: cancelToken,
        ),
      );
      if (byQuery is Success<List<AdminVehicleListItem>>) return byQuery;
    }

    return first;
  }

  Future<Result<void>> assignVehicleToUser({
    required String userId,
    required String vehicleId,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/admin/linkusers/$vehicleId',
      data: <String, dynamic>{'userId': int.tryParse(userId) ?? userId},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminDriverListItem>>> getUserLinkedDrivers(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/users/unlinkeddrivers/$userId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['drivers', 'items', 'data'],
        );
        return Result.ok(
          list
              .whereType<Map>()
              .map(
                (item) => AdminDriverListItem.fromRaw(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item.cast()),
                ),
              )
              .toList(),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminDocumentItem>>> getUserDocuments(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/documents/$userId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['documents', 'items', 'data'],
        );
        return Result.ok(
          list
              .whereType<Map>()
              .map(
                (item) => AdminDocumentItem(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item.cast()),
                ),
              )
              .toList(),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SuperadminDocumentType>>> getDocumentTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/documenttypes/USER', cancelToken: cancelToken);
    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['data', 'documentTypes', 'types'],
        );
        final out = <SuperadminDocumentType>[];
        for (final it in list.whereType<Map>()) {
          out.add(
            SuperadminDocumentType.fromJson(
              it is Map<String, dynamic>
                  ? it
                  : Map<String, dynamic>.from(it.cast()),
            ),
          );
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
    final mediaType = (contentType == null || contentType.trim().isEmpty)
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
      '/admin/uploaddoc',
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
    final mediaType = (contentType == null || contentType.trim().isEmpty)
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
      '/admin/uploaddoc/$documentId',
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

  Future<Result<void>> deleteDocumentFile(
    String documentId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      '/admin/uploaddoc/$documentId',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminTicketListItem>>> getUserTickets(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/tickets',
      queryParameters: <String, dynamic>{'userId': userId},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['tickets', 'items', 'data'],
        );
        return Result.ok(
          list
              .whereType<Map>()
              .map(
                (item) => AdminTicketListItem(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item.cast()),
                ),
              )
              .toList(),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminTransactionItem>>> getUserPayments(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/payments',
      queryParameters: <String, dynamic>{
        'page': 1,
        'limit': 1000,
        'userId': userId,
      },
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['payments', 'transactions', 'items', 'data'],
        );
        return Result.ok(
          list
              .whereType<Map>()
              .map(
                (item) => AdminTransactionItem.fromRaw(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item.cast()),
                ),
              )
              .toList(),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateUserStatus(
    String userId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/users/$userId',
      data: <String, dynamic>{'isActive': isActive},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is! Map) return const <String, dynamic>{};

    final level0 = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data.cast());

    final nestedData = level0['data'];
    if (nestedData is Map) {
      final level1 = Map<String, dynamic>.from(nestedData.cast());
      final level2Data = level1['data'];
      if (level2Data is Map) {
        return Map<String, dynamic>.from(level2Data.cast());
      }
      final level1Candidates = [
        level1['item'],
        level1['user'],
        level1['result'],
      ];
      for (final candidate in level1Candidates) {
        if (candidate is Map<String, dynamic>) return candidate;
        if (candidate is Map) {
          return Map<String, dynamic>.from(candidate.cast());
        }
      }
      return level1;
    }

    final level0Candidates = [
      level0['item'],
      level0['user'],
      level0['result'],
      level0['settings'],
      level0['config'],
    ];
    for (final candidate in level0Candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) return Map<String, dynamic>.from(candidate.cast());
    }

    return level0;
  }

  Future<Result<List<AdminLinkedVehicle>>> getLinkedVehicles({
    required String userId,
    CancelToken? cancelToken,
  }) async {
    final rk = DateTime.now().millisecondsSinceEpoch;
    final res = await api.get(
      '/admin/linkvehicles/$userId',
      queryParameters: {'rk': rk},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data);
        return Result.ok(
          list
              .whereType<Map>()
              .map(
                (e) => AdminLinkedVehicle.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e.cast()),
                ),
              )
              .toList(),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> renewVehicles({
    required String userId,
    required List<int> vehicleIds,
    required String paymentMode,
    required double amount,
    CancelToken? cancelToken,
  }) async {
    final payload = {
      'userId': int.tryParse(userId) ?? userId,
      'vehicleIds': vehicleIds,
      'paymentMode': paymentMode,
    };

    final res = await api.post(
      '/admin/payments/renew',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  List _extractList(Object? data, {List<String> listKeys = const <String>[]}) {
    final keys = <String>['data', 'items', 'result', 'results', ...listKeys];

    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }

      for (final value in map.values) {
        if (value is Map || value is List) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0) ?? const [];
  }

  String? _extractToken(Object? data) {
    if (data is Map) {
      String? asToken(Object? v) {
        if (v is String && v.trim().isNotEmpty) return v;
        return null;
      }

      final direct = asToken(
        data['token'] ?? data['accessToken'] ?? data['access_token'],
      );
      if (direct != null) return direct;

      for (final key in const ['data', 'result', 'item', 'payload', 'response']) {
        final nested = data[key];
        if (nested is Map) {
          final token = _extractToken(nested);
          if (token != null) return token;
        } else if (nested is List) {
          for (final item in nested) {
            if (item is Map) {
              final token = _extractToken(item);
              if (token != null) return token;
            }
          }
        }
      }
    }
    return null;
  }
}
