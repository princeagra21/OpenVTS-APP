import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/utils/request_control.dart';

/// Minimal HTTP transport contract for legacy repositories that have not yet
/// been migrated to generated Retrofit services.
///
/// New feature code should depend on Retrofit services/use cases instead of
/// this interface. Keeping the old transport behind this small contract lets us
/// shrink direct [ApiClient] usage while legacy screens are migrated safely.
abstract interface class LegacyApiTransport {
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  });

  Future<Result<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  });

  Future<Result<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  });

  Future<Result<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  });

  Future<Result<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  });
}
