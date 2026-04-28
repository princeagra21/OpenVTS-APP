import 'package:dio/dio.dart';
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
      '/admin/unlinkvehicles/$userId',
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
