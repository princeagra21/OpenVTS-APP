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

  Future<Result<AdminTeamListItem>> getTeamDetails(
    String teamId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/teams/$teamId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        return Result.ok(AdminTeamListItem.fromRaw(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateTeamPassword(
    String teamId,
    String password, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/teams/$teamId',
      data: <String, dynamic>{'password': password},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateTeam({
    required String teamId,
    required String name,
    required String email,
    required String mobilePrefix,
    required String mobileNumber,
    required String username,
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/teams/$teamId',
      data: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'mobilePrefix': mobilePrefix.trim(),
        'mobileNumber': mobileNumber.trim(),
        'username': username.trim(),
      },
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createTeam({
    required String name,
    required String email,
    required String mobilePrefix,
    required String mobileNumber,
    required String username,
    required String password,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/admin/teams',
      data: <String, dynamic>{
        'name': name,
        'email': email,
        'mobilePrefix': mobilePrefix,
        'mobileNumber': mobileNumber,
        'username': username,
        'password': password,
      },
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

  Map<String, dynamic> _extractMap(Object? data) {
    Object? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is Map) {
        final map = node is Map<String, dynamic>
            ? node
            : Map<String, dynamic>.from(node.cast());
        final candidates = [
          map['data'],
          map['item'],
          map['team'],
          map['result'],
        ];
        for (final c in candidates) {
          final result = walk(c, depth + 1);
          if (result is Map<String, dynamic>) return result;
        }
        return map;
      }
      return null;
    }

    final result = walk(data, 0);
    if (result is Map<String, dynamic>) return result;
    if (result is Map) return Map<String, dynamic>.from(result.cast());
    return const <String, dynamic>{};
  }
}
