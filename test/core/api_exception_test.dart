import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Maps DioException response status and message', () {
    final req = RequestOptions(path: '/user/profile');
    final res = Response<dynamic>(
      requestOptions: req,
      statusCode: 401,
      statusMessage: 'Unauthorized',
      data: {'message': 'Bad token'},
    );

    final dioEx = DioException(
      requestOptions: req,
      response: res,
      type: DioExceptionType.badResponse,
    );

    final apiEx = ApiException.fromDioException(dioEx);
    expect(apiEx.statusCode, 401);
    expect(apiEx.message, 'Bad token');
    expect(apiEx.details, isA<Map>());
  });
}
