import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/reference_data/data/mappers/reference_data_mapper.dart';
import 'package:open_vts/features/reference_data/data/repositories/reference_data_repository_impl.dart';
import 'package:open_vts/features/reference_data/data/sources/reference_data_api_service.dart';

void main() {
  test('maps countries DTOs to typed domain options', () async {
    final repo = ReferenceDataRepositoryImpl(
      api: _FakeReferenceDataApiService(
        countries: _okList(const <Object?>[
          <String, Object?>{'name': 'India', 'isoCode': 'IN'},
        ], key: 'countries'),
      ),
      mapper: const ReferenceDataMapper(),
    );

    final result = await repo.getCountries();

    result.when(
      success: (countries) {
        expect(countries.single.name, 'India');
        expect(countries.single.isoCode, 'IN');
      },
      failure: (error) => fail('Expected success, got $error'),
    );
  });

  test('backend action=false maps to ServerError', () async {
    final repo = ReferenceDataRepositoryImpl(
      api: _FakeReferenceDataApiService(
        countries: _response(action: false, message: 'No countries'),
      ),
      mapper: const ReferenceDataMapper(),
    );

    final result = await repo.getCountries();

    expect(result.errorOrNull, isA<ServerError>());
  });

  test('empty data maps to typed ServerError', () async {
    final repo = ReferenceDataRepositoryImpl(
      api: _FakeReferenceDataApiService(
        countries: _response(data: null),
      ),
      mapper: const ReferenceDataMapper(),
    );

    final result = await repo.getCountries();

    expect(result.errorOrNull, isA<ServerError>());
  });

  test('timeout maps to NetworkError', () async {
    final repo = ReferenceDataRepositoryImpl(
      api: _FakeReferenceDataApiService(error: DioException(
        requestOptions: RequestOptions(path: '/countries'),
        type: DioExceptionType.connectionTimeout,
      )),
      mapper: const ReferenceDataMapper(),
    );

    final result = await repo.getCountries();

    expect(result.errorOrNull, isA<NetworkError>());
  });

  test('401 maps to AuthError', () async {
    final repo = ReferenceDataRepositoryImpl(
      api: _FakeReferenceDataApiService(error: DioException(
        requestOptions: RequestOptions(path: '/countries'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/countries'),
          statusCode: 401,
          data: const {'message': 'Unauthorized'},
        ),
      )),
      mapper: const ReferenceDataMapper(),
    );

    final result = await repo.getCountries();

    expect(result.errorOrNull, isA<AuthError>());
  });
}

Map<String, Object?> _okList(List<Object?> items, {String key = 'data'}) {
  return _response(data: <String, Object?>{key: items});
}

Map<String, Object?> _response({bool action = true, String message = '', Object? data = const <String, Object?>{}}) {
  return <String, Object?>{
    'status': action ? 'success' : 'error',
    'data': <String, Object?>{
      'action': action,
      'message': message,
      'data': data,
    },
  };
}

class _FakeReferenceDataApiService implements ReferenceDataApiService {
  _FakeReferenceDataApiService({this.countries, this.error});

  final Object? countries;
  final Object? error;

  @override
  Future<Object?> getCountries() async {
    final e = error;
    if (e != null) throw e;
    return countries ?? _okList(const <Object?>[], key: 'countries');
  }

  @override
  Future<Object?> getStates(String countryCode) async => _okList(const <Object?>[], key: 'states');

  @override
  Future<Object?> getCities(String countryCode, String stateCode) async => _okList(const <Object?>[], key: 'cities');

  @override
  Future<Object?> getMobilePrefixes() async => _okList(const <Object?>[], key: 'mobilePrefixes');

  @override
  Future<Object?> getVehicleTypes() async => _okList(const <Object?>[], key: 'types');

  @override
  Future<Object?> getLanguages() async => _okList(const <Object?>[], key: 'languages');

  @override
  Future<Object?> getDateFormats() async => _okList(const <Object?>[], key: 'dateFormats');

  @override
  Future<Object?> getTimezones() async => _okList(const <Object?>[], key: 'timezones');
}
