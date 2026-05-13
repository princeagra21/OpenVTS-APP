import 'package:open_vts/core/api/api_response.dart';

/// Centralized helper for defensive API-envelope normalization.
///
/// Some backend endpoints return the standard envelope:
/// `{ status, data: { action, message, data }, timestamp }`.
/// Other endpoints return raw lists/maps or wrap records under keys such as
/// `items`, `rows`, `result`, or `records`.
///
/// This class intentionally contains no feature-specific business rules. Feature
/// mappers can pass preferred keys when a legacy endpoint uses a domain-specific
/// key such as `userslist`, `devices`, or `countries`.
final class ApiResponseNormalizer {
  const ApiResponseNormalizer._();

  static const List<String> defaultPayloadKeys = <String>[
    'data',
    'items',
    'rows',
    'result',
    'records',
    'payload',
  ];

  static const int defaultMaxDepth = 6;

  /// Returns a defensive map view of [value].
  ///
  /// By default malformed values return an empty map. Pass [strict] to surface a
  /// malformed response as a [FormatException].
  static Map<String, Object?> mapOf(Object? value, {bool strict = false}) {
    final normalized = _normalizeApiResponse(value);
    if (normalized is Map) {
      return <String, Object?>{
        for (final entry in normalized.entries) entry.key.toString(): entry.value,
      };
    }
    if (strict) {
      throw FormatException('Expected an API response map, got ${normalized.runtimeType}.');
    }
    return const <String, Object?>{};
  }

  /// Returns a defensive dynamic map for generated Retrofit bridge code.
  ///
  /// Feature mappers should prefer [mapOf] so domain and mapper code stays
  /// typed as `Object?`. This method only exists because the existing
  /// `ApiResponse.fromJson` API is still `Map<String, dynamic>` based.
  static Map<String, dynamic> dynamicMapOf(Object? value, {bool strict = false}) {
    final map = mapOf(value, strict: strict);
    return <String, dynamic>{for (final entry in map.entries) entry.key: entry.value};
  }

  /// Extracts a list from a raw API response/envelope.
  ///
  /// [preferredKeys] should contain only endpoint-shape aliases, not business
  /// transformation rules. Default envelope keys are always checked after the
  /// preferred keys.
  static List<Object?> listOf(
    Object? raw, {
    Iterable<String> preferredKeys = const <String>[],
    bool strict = false,
    int maxDepth = defaultMaxDepth,
  }) {
    final result = _walkForList(
      _normalizeApiResponse(raw),
      _keys(preferredKeys),
      depth: 0,
      maxDepth: maxDepth,
    );
    if (result != null) return List<Object?>.from(result);
    if (strict) {
      throw FormatException('Expected an API response list, got ${raw.runtimeType}.');
    }
    return const <Object?>[];
  }

  /// Extracts a map from a raw API response/envelope.
  ///
  /// If no nested preferred/default key matches, this returns the nearest map
  /// payload rather than throwing. Pass [strict] to fail on malformed input.
  static Map<String, Object?> mapPayloadOf(
    Object? raw, {
    Iterable<String> preferredKeys = const <String>[],
    bool strict = false,
    int maxDepth = defaultMaxDepth,
  }) {
    final result = _walkForMap(
      _normalizeApiResponse(raw),
      _keys(preferredKeys),
      depth: 0,
      maxDepth: maxDepth,
    );
    if (result != null) return result;
    if (strict) {
      throw FormatException('Expected an API response object map, got ${raw.runtimeType}.');
    }
    return const <String, Object?>{};
  }

  /// Extracts the most likely payload object without forcing a list/map shape.
  static Object? payloadOf(
    Object? raw, {
    Iterable<String> preferredKeys = const <String>[],
    bool strict = false,
    int maxDepth = defaultMaxDepth,
  }) {
    final normalized = _normalizeApiResponse(raw);
    final result = _walkForPayload(
      normalized,
      _keys(preferredKeys),
      depth: 0,
      maxDepth: maxDepth,
    );
    if (result != null) return result;
    if (strict) {
      throw FormatException('Expected an API response payload, got ${raw.runtimeType}.');
    }
    return null;
  }


  /// Returns true when a standard envelope explicitly contains `data: null`.
  ///
  /// This lets repositories distinguish a valid empty list from a malformed or
  /// intentionally empty backend payload without making the normalizer throw.
  static bool hasExplicitNullPayload(Object? raw) {
    final normalized = _normalizeApiResponse(raw);
    if (normalized is Map) {
      final root = mapOf(normalized);
      final rootData = root['data'];
      if (rootData is Map) {
        final dataMap = mapOf(rootData);
        return dataMap.containsKey('data') && dataMap['data'] == null;
      }
      return root.containsKey('data') && root['data'] == null;
    }
    return false;
  }

  /// Reads backend action/success/ok flags. Missing action defaults to [defaultValue]
  /// because many legacy read endpoints return raw lists without an envelope.
  static bool action(Object? raw, {bool defaultValue = true}) {
    final normalized = _normalizeApiResponse(raw);
    if (normalized is ApiResponse) return normalized.action;
    if (normalized is Map) {
      final root = mapOf(normalized);
      final rootAction = _boolValue(root['action'] ?? root['success'] ?? root['ok']);
      if (rootAction != null) return rootAction;
      final data = root['data'];
      if (data is Map) {
        final dataMap = mapOf(data);
        final nestedAction = _boolValue(dataMap['action'] ?? dataMap['success'] ?? dataMap['ok']);
        if (nestedAction != null) return nestedAction;
      }
    }
    return defaultValue;
  }

  static String message(Object? raw, {String defaultValue = ''}) {
    final normalized = _normalizeApiResponse(raw);
    if (normalized is ApiResponse) return normalized.message;
    if (normalized is Map) {
      final root = mapOf(normalized);
      final rootMessage = _text(root['message'] ?? root['error']);
      if (rootMessage.isNotEmpty) return rootMessage;
      final data = root['data'];
      if (data is Map) {
        final dataMessage = _text(mapOf(data)['message'] ?? mapOf(data)['error']);
        if (dataMessage.isNotEmpty) return dataMessage;
      }
    }
    return defaultValue;
  }

  static String status(Object? raw, {String defaultValue = ''}) {
    final normalized = _normalizeApiResponse(raw);
    if (normalized is ApiResponse) return normalized.status;
    if (normalized is Map) {
      final status = _text(mapOf(normalized)['status']);
      if (status.isNotEmpty) return status;
    }
    return defaultValue;
  }

  static Object? _normalizeApiResponse(Object? value) {
    if (value is ApiResponse) {
      return <String, Object?>{
        'status': value.status,
        'timestamp': value.timestamp,
        'data': <String, Object?>{
          'action': value.action,
          'message': value.message,
          'data': value.payload,
        },
      };
    }
    return value;
  }

  static List<String> _keys(Iterable<String> preferredKeys) {
    return <String>{...preferredKeys, ...defaultPayloadKeys}.toList(growable: false);
  }

  static List<Object?>? _walkForList(
    Object? node,
    List<String> keys, {
    required int depth,
    required int maxDepth,
  }) {
    if (depth > maxDepth) return null;
    if (node is List) return List<Object?>.from(node);
    if (node is! Map) return null;

    final map = mapOf(node);
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      final found = _walkForList(map[key], keys, depth: depth + 1, maxDepth: maxDepth);
      if (found != null) return found;
    }
    return null;
  }

  static Map<String, Object?>? _walkForMap(
    Object? node,
    List<String> keys, {
    required int depth,
    required int maxDepth,
  }) {
    if (depth > maxDepth || node is! Map) return null;
    final map = mapOf(node);

    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      final value = map[key];
      if (value is Map) {
        final nested = _walkForMap(value, keys, depth: depth + 1, maxDepth: maxDepth);
        if (nested != null) return nested;
      }
    }

    return _isEnvelopeMetadataMap(map) ? null : map;
  }

  static Object? _walkForPayload(
    Object? node,
    List<String> keys, {
    required int depth,
    required int maxDepth,
  }) {
    if (depth > maxDepth) return null;
    if (node is List) return List<Object?>.from(node);
    if (node is! Map) return node;

    final map = mapOf(node);
    for (final key in keys) {
      if (!map.containsKey(key)) continue;
      final found = _walkForPayload(map[key], keys, depth: depth + 1, maxDepth: maxDepth);
      if (found != null) return found;
    }
    return map.isEmpty ? null : map;
  }


  static bool _isEnvelopeMetadataMap(Map<String, Object?> map) {
    final hasMetadata = map.containsKey('action') ||
        map.containsKey('success') ||
        map.containsKey('ok') ||
        map.containsKey('message') ||
        map.containsKey('status') ||
        map.containsKey('timestamp');
    return hasMetadata && map.containsKey('data');
  }

  static bool? _boolValue(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = _text(value).toLowerCase();
    if (text.isEmpty) return null;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  static String _text(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text.toLowerCase() == 'null' ? '' : text;
  }
}
