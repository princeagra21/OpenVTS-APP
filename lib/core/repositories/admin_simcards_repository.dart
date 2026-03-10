import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_sim_card_item.dart';
import 'package:fleet_stack/core/models/sim_provider_option.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminSimCardsRepository {
  final ApiClient api;

  const AdminSimCardsRepository({required this.api});

  Future<Result<List<AdminSimCardItem>>> getSimCards({
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
      '/admin/simcards',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['simcards', 'sims', 'items', 'results'],
        );
        final out = list
            .whereType<Map>()
            .map(
              (item) => AdminSimCardItem.fromRaw(
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

  Future<Result<List<SimProviderOption>>> getSimProviders({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/simproviders', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['simproviders', 'providers', 'items', 'results'],
        );
        final out = list
            .whereType<Map>()
            .map(
              (item) => SimProviderOption.fromRaw(
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

  Future<Result<void>> updateSimCardStatus(
    String simId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/simcards/$simId',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> addSimCard(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/admin/simcards',
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
}
