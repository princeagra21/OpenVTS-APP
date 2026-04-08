import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/pricing_plan.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminPricingPlansRepository {
  final ApiClient api;

  const AdminPricingPlansRepository({required this.api});

  Future<Result<List<PricingPlan>>> getPlans({
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

  Future<Result<Map<String, dynamic>>> createPlan({
    required String name,
    required int durationDays,
    required num price,
    required String currency,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'durationDays': durationDays,
      'price': price,
      'currency': currency,
    };

    final res = await api.post(
      '/admin/pricingplans',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_extractMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> updatePlan({
    required String id,
    required String name,
    required int durationDays,
    required num price,
    required String currency,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'durationDays': durationDays,
      'price': price,
      'currency': currency,
    };

    final res = await api.patch(
      '/admin/pricingplans/$id',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(_extractMap(data)),
      failure: (err) => Result.fail(err),
    );
  }

  List? _extractList(Object? data) {
    if (data is List) return data;
    if (data is! Map) return null;

    final keys = <String>['data', 'items', 'result', 'results'];

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
        if (value is List || value is Map) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0);
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return <String, dynamic>{};
  }
}
