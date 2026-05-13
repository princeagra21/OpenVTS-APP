// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_data_api_service.dart';

class _ReferenceDataApiService implements ReferenceDataApiService {
  _ReferenceDataApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getCountries() async {
    final response = await _dio.get<Object?>('/countries');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getStates(String countryCode) async {
    final response = await _dio.get<Object?>('/states/$countryCode');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getCities(String countryCode, String stateCode) async {
    final response = await _dio.get<Object?>('/cities/$countryCode/$stateCode');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getMobilePrefixes() async {
    final response = await _dio.get<Object?>('/mobileprefix');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getVehicleTypes() async {
    final response = await _dio.get<Object?>('/vehicletypes');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getLanguages() async {
    final response = await _dio.get<Object?>('/languages');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getDateFormats() async {
    final response = await _dio.get<Object?>('/dateformats');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getTimezones() async {
    final response = await _dio.get<Object?>('/timezones');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }
}
