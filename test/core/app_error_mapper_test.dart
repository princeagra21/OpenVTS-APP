import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_exception.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';

void main() {
  test('maps ApiException status codes to typed AppError', () {
    final error = AppErrorMapper.fromObject(
      const ApiException(message: 'Forbidden', statusCode: 403),
    );

    expect(error, isA<PermissionAppError>());
    expect(error.statusCode, 403);
  });

  test('maps Dio connection failure to NetworkError', () {
    final dioError = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
      error: 'offline',
    );

    final error = AppErrorMapper.fromDio(dioError);

    expect(error, isA<NetworkError>());
  });
}
