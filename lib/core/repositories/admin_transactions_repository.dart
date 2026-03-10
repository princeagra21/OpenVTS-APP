import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/admin_transactions_summary.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminTransactionsRepository {
  final ApiClient api;

  const AdminTransactionsRepository({required this.api});

  Future<Result<List<AdminTransactionItem>>> getTransactions({
    String? search,
    String? status,
    int? page,
    int? limit,
    String? from,
    String? to,
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
    if (from != null && from.trim().isNotEmpty) query['from'] = from.trim();
    if (to != null && to.trim().isNotEmpty) query['to'] = to.trim();

    final res = await api.get(
      '/admin/transactions',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['transactions', 'items', 'results', 'rows'],
        );

        final out = list
            .whereType<Map>()
            .map(
              (item) => AdminTransactionItem.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();

        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminTransactionsSummary>> getTransactionsSummary({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/transactions/analytics',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractMap(
          data,
          preferredKeys: const ['analytics', 'summary', 'stats', 'totals'],
        );
        return Result.ok(AdminTransactionsSummary.fromRaw(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(
    Object? data, {
    List<String> preferredKeys = const <String>[],
  }) {
    if (data is! Map) return const <String, dynamic>{};

    final keys = <String>['data', 'result', 'results', ...preferredKeys];

    Map<String, dynamic>? walk(Object? node, int depth) {
      if (depth > 6 || node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in keys) {
        final value = map[key];
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value.cast());
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
}
