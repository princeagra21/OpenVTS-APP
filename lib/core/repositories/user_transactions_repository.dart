import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/user_transactions_page.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserTransactionsRepository {
  final ApiClient api;

  const UserTransactionsRepository({required this.api});

  Future<Result<UserTransactionsPage>> getTransactions({
    String? query,
    String? status,
    int page = 1,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    if (query != null && query.trim().isNotEmpty) {
      queryParameters['q'] = query.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    final res = await api.get(
      '/user/transactions',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _extractMap(data);
        final items = _extractList(root['items'])
            .whereType<Map>()
            .map(
              (item) => AdminTransactionItem.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();

        return Result.ok(
          UserTransactionsPage(
            items: items,
            page: _readInt(root['page']) ?? page,
            limit: _readInt(root['limit']) ?? limit,
            total: _readInt(root['total']) ?? items.length,
          ),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? data) {
    Map<String, dynamic>? walk(Object? node, int depth) {
      if (depth > 6 || node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      final candidates = <Object?>[
        map['data'],
        map['result'],
        map['results'],
        map['items'],
      ];
      for (final candidate in candidates) {
        if (candidate is Map<String, dynamic>) return candidate;
        if (candidate is Map) {
          return Map<String, dynamic>.from(candidate.cast());
        }
      }

      for (final value in map.values) {
        if (value is Map) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return map;
    }

    return walk(data, 0) ?? const <String, dynamic>{};
  }

  List _extractList(Object? data) {
    if (data is List) return data;
    return const [];
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }
}
