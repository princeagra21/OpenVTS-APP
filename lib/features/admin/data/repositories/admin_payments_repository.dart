import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

class AdminPaymentsRepository {
  final LegacyApiTransport api;

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
      AdminApiPaths.paymentsRenew,
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
