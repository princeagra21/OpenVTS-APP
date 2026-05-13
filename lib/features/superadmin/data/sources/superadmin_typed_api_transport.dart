import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/api/api_result.dart' as legacy;
import 'package:open_vts/core/api/legacy_api_transport.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:retrofit/retrofit.dart';

part 'superadmin_typed_api_transport.g.dart';

class TypedApiRequestBody {
  const TypedApiRequestBody(this.value);
  final Map<String, dynamic> value;
  Map<String, dynamic> toJson() => value;
}

@RestApi()
abstract class SuperadminTypedApiService {
  factory SuperadminTypedApiService(Dio dio, {String? baseUrl}) = _SuperadminTypedApiService;

  @GET('{path}')
  Future<ApiResponse<Map<String, dynamic>>> getMap(
    @Path('path') String path, {
    @Queries() Map<String, Object?>? query,
  });

  @POST('{path}')
  Future<ApiResponse<Map<String, dynamic>>> postMap(
    @Path('path') String path, {
    @Body() TypedApiRequestBody? body,
    @Queries() Map<String, Object?>? query,
  });

  @PATCH('{path}')
  Future<ApiResponse<Map<String, dynamic>>> patchMap(
    @Path('path') String path, {
    @Body() TypedApiRequestBody? body,
    @Queries() Map<String, Object?>? query,
  });

  @PUT('{path}')
  Future<ApiResponse<Map<String, dynamic>>> putMap(
    @Path('path') String path, {
    @Body() TypedApiRequestBody? body,
    @Queries() Map<String, Object?>? query,
  });


  @POST('{path}')
  Future<ApiResponse<Map<String, dynamic>>> postForm(
    @Path('path') String path,
    @Body() FormData body, {
    @Queries() Map<String, Object?>? query,
  });

  @PATCH('{path}')
  Future<ApiResponse<Map<String, dynamic>>> patchForm(
    @Path('path') String path,
    @Body() FormData body, {
    @Queries() Map<String, Object?>? query,
  });

  @DELETE('{path}')
  Future<ApiResponse<Map<String, dynamic>>> deleteMap(
    @Path('path') String path, {
    @Body() TypedApiRequestBody? body,
    @Queries() Map<String, Object?>? query,
  });
}

/// Compatibility adapter used only by repositories being migrated away from
/// LegacyApiTransport. It keeps older repository method signatures stable while
/// the HTTP boundary is now a generated, typed Retrofit service.
class SuperadminTypedApiTransport implements LegacyApiTransport {
  SuperadminTypedApiTransport({required SuperadminTypedApiService api}) : _api = api;

  factory SuperadminTypedApiTransport.fromDio(Dio dio) {
    return SuperadminTypedApiTransport(api: SuperadminTypedApiService(dio));
  }

  final SuperadminTypedApiService _api;

  Future<legacy.Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _send(() => _api.getMap(path, query: _objectQuery(queryParameters)));
  }

  Future<legacy.Result<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    if (data is FormData) {
      return _send(() => _api.postForm(path, data, query: _objectQuery(queryParameters)));
    }
    return _send(() => _api.postMap(path, body: _requestBody(data), query: _objectQuery(queryParameters)));
  }

  Future<legacy.Result<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    if (data is FormData) {
      return _send(() => _api.patchForm(path, data, query: _objectQuery(queryParameters)));
    }
    return _send(() => _api.patchMap(path, body: _requestBody(data), query: _objectQuery(queryParameters)));
  }

  Future<legacy.Result<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(() => _api.putMap(path, body: _requestBody(data), query: _objectQuery(queryParameters)));
  }

  Future<legacy.Result<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(() => _api.deleteMap(path, body: _requestBody(data), query: _objectQuery(queryParameters)));
  }

  Future<legacy.Result<dynamic>> _send(Future<ApiResponse<Map<String, dynamic>>> Function() request) async {
    try {
      final response = await request();
      if (!response.action) {
        return legacy.Result.fail(ServerError(response.message.trim().isEmpty ? 'Request failed' : response.message.trim()));
      }
      return legacy.Result.ok(response.payload ?? const <String, dynamic>{});
    } on DioException catch (error) {
      return legacy.Result.fail(AppErrorMapper.fromDio(error));
    } catch (error) {
      return legacy.Result.fail(AppErrorMapper.fromObject(error));
    }
  }


  TypedApiRequestBody? _requestBody(Object? data) {
    if (data == null) return null;
    if (data is TypedApiRequestBody) return data;
    if (data is Map<String, dynamic>) return TypedApiRequestBody(data);
    if (data is Map) {
      return TypedApiRequestBody(<String, dynamic>{
        for (final entry in data.entries) entry.key.toString(): entry.value,
      });
    }
    try {
      final json = (data as dynamic).toJson();
      if (json is Map<String, dynamic>) return TypedApiRequestBody(json);
      if (json is Map) {
        return TypedApiRequestBody(<String, dynamic>{
          for (final entry in json.entries) entry.key.toString(): entry.value,
        });
      }
    } catch (_) {
      // Fall through to an empty request body for legacy callers.
    }
    return const TypedApiRequestBody(<String, dynamic>{});
  }

  Map<String, Object?>? _objectQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    return <String, Object?>{for (final entry in query.entries) entry.key: entry.value};
  }
}
