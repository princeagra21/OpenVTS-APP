import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_dashboard_summary.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminDashboardRepository {
  final ApiClient api;

  const AdminDashboardRepository({required this.api});

  Future<Result<AdminDashboardSummary>> getAdminDashboardSummary({
    int months = 12,
    int listLimit = 10,
    String? currency,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{'months': months, 'listLimit': listLimit};
    if (currency != null && currency.trim().isNotEmpty) {
      query['currency'] = currency.trim();
    }

    final res = await api.get(
      '/admin/dashboard/summary',
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _asMap(data);
        return Result.ok(AdminDashboardSummary(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
