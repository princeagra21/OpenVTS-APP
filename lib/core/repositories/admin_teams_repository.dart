import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_team_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminTeamsRepository {
  final ApiClient api;

  const AdminTeamsRepository({required this.api});

  Future<Result<List<AdminTeamListItem>>> getTeams({
    String? search,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      '/admin/teams',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data);
        final out = list
            .whereType<Map>()
            .map(
              (item) => AdminTeamListItem.fromRaw(
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

  Future<Result<void>> updateTeamStatus(
    String teamId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/teams/$teamId',
      data: <String, dynamic>{'isActive': isActive},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  List _extractList(Object? data) {
    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;
      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());
      final candidates = [
        map['data'],
        map['items'],
        map['list'],
        map['results'],
      ];
      for (final c in candidates) {
        final result = walk(c, depth + 1);
        if (result != null) return result;
      }
      return null;
    }

    return walk(data, 0) ?? const [];
  }
}
