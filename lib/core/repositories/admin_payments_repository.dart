import 'package:dio/dio.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/network/api_paths.dart';

class AdminPaymentsRepository {
  final ApiClient api;

  const AdminPaymentsRepository({required this.api});

  Future<Result<void>> createRenewPayment({
    required String userId,
    required List<String> vehicleIds,
    required String amount,
    required String paymentMode,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'userId': _toNumOrString(userId.trim()),
      'vehicleIds': vehicleIds.map(_toNumOrString).toList(),
      'amount': amount.trim(),
      'paymentMode': paymentMode.trim(),
    };

    final res = await api.post(
      ApiPaths.path('/admin/payments/renew'),
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
