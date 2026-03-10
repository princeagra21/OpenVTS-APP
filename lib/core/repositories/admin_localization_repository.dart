import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_localization_settings.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminLocalizationRepository {
  final ApiClient api;

  const AdminLocalizationRepository({required this.api});

  Future<Result<AdminLocalizationSettings>> getLocalization({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/localization', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final level1 = _extractMapFromNested(data);
        final level2 = _extractMapFromNested(level1);
        return Result.ok(
          AdminLocalizationSettings(level2.isNotEmpty ? level2 : level1),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateLocalization(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/localization',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMapFromNested(Object? data) {
    if (data is Map<String, dynamic>) {
      final nestedKeys = [
        'data',
        'result',
        'item',
        'items',
        'config',
        'settings',
      ];
      for (final key in nestedKeys) {
        final next = data[key];
        if (next is Map<String, dynamic>) return next;
        if (next is Map) return Map<String, dynamic>.from(next.cast());
      }
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }
}
