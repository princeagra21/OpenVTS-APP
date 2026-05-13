import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/interceptors/logging_interceptor.dart';

void main() {
  test('logging interceptor exposes only redacted metadata', () {
    final interceptor = SafeDioLoggingInterceptor();
    final options = RequestOptions(
      path: '/users/123?access_token=raw-token',
      method: 'POST',
      queryParameters: <String, Object?>{
        'password': 'secret',
        'search': 'vehicle',
      },
      headers: <String, Object?>{
        'Authorization': 'Bearer abc.def.ghi',
        'x-request-id': 'req-1',
      },
      data: <String, Object?>{'password': 'secret'},
    );

    final context = interceptor.safeRequestContext(options).toString();

    expect(context, isNot(contains('abc.def.ghi')));
    expect(context, isNot(contains('secret')));
    expect(context, isNot(contains('raw-token')));
    expect(context, isNot(contains('Authorization')));
    expect(context, contains('queryKeys'));
    expect(context, contains('headerKeys'));
  });
}
