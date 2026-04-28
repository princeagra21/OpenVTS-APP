import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminPaymentsRepository {
  final ApiClient api;

  const AdminPaymentsRepository({required this.api});

  Future<Result<void>> createRenewPayment({
    required String userId,
    required List<String> vehicleIds,
    required String paymentMode,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'userId': _toNumOrString(userId.trim()),
      'vehicleIds': vehicleIds.map(_toNumOrString).toList(),
      'paymentMode': paymentMode.trim(),
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

  Object _toNumOrString(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    return value;
  }
}
