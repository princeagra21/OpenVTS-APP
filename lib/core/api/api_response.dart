/// Generic server envelope helper.
///
/// Matches the existing backend style:
/// `{ status, data: { action, message, data }, timestamp }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.data,
    required this.timestamp,
  });

  final String status;
  final ApiData<T> data;
  final String? timestamp;

  bool get action => data.action;
  String get message => data.message;
  T? get payload => data.data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      status: json['status']?.toString() ?? '',
      data: rawData is Map<String, dynamic>
          ? ApiData<T>.fromJson(
              rawData,
              fromJsonT,
              defaultAction: json['status']?.toString().toLowerCase() == 'success',
            )
          : ApiData<T>(
              action: json['status']?.toString().toLowerCase() == 'success',
              message: '',
              data: rawData != null ? fromJsonT(rawData) : null,
            ),
      timestamp: json['timestamp']?.toString(),
    );
  }
}

class ApiData<T> {
  const ApiData({
    required this.action,
    required this.message,
    required this.data,
  });

  final bool action;
  final String message;
  final T? data;

  factory ApiData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT, {
    bool defaultAction = false,
  }) {
    final rawAction = json['action'] ?? json['success'] ?? json['ok'];
    return ApiData<T>(
      action: rawAction == null
          ? defaultAction
          : rawAction is bool
              ? rawAction
              : rawAction.toString().toLowerCase() == 'true',
      message: json['message']?.toString() ?? '',
      data: json.containsKey('data') && json['data'] != null
          ? fromJsonT(json['data'])
          : json.keys.any((key) => key != 'action' && key != 'success' && key != 'ok' && key != 'message')
              ? fromJsonT(json)
              : null,
    );
  }
}


Map<String, dynamic> apiResponseMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value.cast());
  return const <String, dynamic>{};
}

Map<String, dynamic> apiMapDynamic(Object? value) => apiResponseMap(value);

List<Map<String, dynamic>> apiListMapDynamic(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item.cast()))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

ApiResponse<T> apiDecodeResponse<T>(Object? data, T Function(Object? json) fromJsonT) {
  final map = apiResponseMap(data);
  if (map.isEmpty && data is! Map) {
    return ApiResponse<T>(
      status: '',
      timestamp: null,
      data: ApiData<T>(action: false, message: 'Invalid API response', data: null),
    );
  }
  return ApiResponse<T>.fromJson(map, fromJsonT);
}
