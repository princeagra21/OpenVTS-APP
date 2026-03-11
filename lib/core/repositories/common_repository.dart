import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class CommonRepository {
  final ApiClient api;

  CommonRepository({required this.api});

  Future<Result<List<ReferenceOption>>> getLanguages({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/languages', cancelToken: cancelToken);

    return res.when(
      success: (data) => Result.ok(
        _parseReferenceOptions(
          data,
          valueKeys: const ['code', 'value', 'id', 'key', 'lang'],
          labelKeys: const ['name', 'label', 'title', 'displayName'],
        ),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<ReferenceOption>>> getDateFormats({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/dateformats', cancelToken: cancelToken);

    return res.when(
      success: (data) => Result.ok(
        _parseReferenceOptions(
          data,
          valueKeys: const ['value', 'format', 'id', 'code'],
          labelKeys: const ['label', 'name', 'title', 'format'],
        ),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<TimezoneOption>>> getTimezones({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/timezones', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final options = _parseTimezoneOptions(data);
        return Result.ok(options);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<CountryOption>>> getCountries({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/countries', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(data);
        final out = <CountryOption>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map) {
              final map = item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item.cast());
              final name = (map['name'] ?? map['label'] ?? '')
                  .toString()
                  .trim();
              final iso =
                  (map['isoCode'] ?? map['countryCode'] ?? map['code'] ?? '')
                      .toString()
                      .trim()
                      .toUpperCase();
              if (name.isEmpty || iso.isEmpty) continue;
              out.add(CountryOption(name: name, isoCode: iso));
            }
          }
        }
        out.sort((a, b) => a.name.compareTo(b.name));
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MobilePrefixOption>>> getMobilePrefixes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/mobileprefix', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(data);
        final out = <MobilePrefixOption>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map) {
              final map = item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item.cast());
              final countryCode =
                  (map['country'] ?? map['countryCode'] ?? map['isoCode'] ?? '')
                      .toString()
                      .trim()
                      .toUpperCase();
              final code = (map['code'] ?? map['mobilePrefix'] ?? '')
                  .toString()
                  .trim();
              if (countryCode.isEmpty || code.isEmpty) continue;
              out.add(MobilePrefixOption(countryCode: countryCode, code: code));
            }
          }
        }
        out.sort((a, b) => a.countryCode.compareTo(b.countryCode));
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<ReferenceOption>>> getVehicleTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/vehicletypes', cancelToken: cancelToken);

    return res.when(
      success: (data) => Result.ok(
        _parseReferenceOptions(
          data,
          valueKeys: const ['id', 'value', 'code'],
          labelKeys: const ['name', 'label', 'title', 'displayName'],
        ),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  List<TimezoneOption> _parseTimezoneOptions(Object? data) {
    // Support common response shapes:
    // - List<String> or List<Map>
    // - { data: [...] } or { items: [...] }
    final list = _extractList(data);
    if (list == null) return const [];

    final out = <TimezoneOption>[];
    for (final item in list) {
      if (item is String) {
        final v = item.trim();
        if (v.isEmpty) continue;
        out.add(TimezoneOption(value: v, label: _labelForString(v)));
        continue;
      }

      if (item is Map) {
        final value =
            (item['offset'] ??
                    item['value'] ??
                    item['code'] ??
                    item['id'] ??
                    item['name'])
                ?.toString();
        if (value == null || value.trim().isEmpty) continue;

        final label =
            (item['label'] ??
                    item['title'] ??
                    item['name'] ??
                    item['displayName'])
                ?.toString();

        out.add(
          TimezoneOption(
            value: value,
            label: (label == null || label.trim().isEmpty)
                ? _labelForString(value)
                : label,
          ),
        );
        continue;
      }
    }

    // Keep deterministic ordering for UI stability.
    out.sort((a, b) => a.label.compareTo(b.label));
    return out;
  }

  List<ReferenceOption> _parseReferenceOptions(
    Object? data, {
    required List<String> valueKeys,
    required List<String> labelKeys,
  }) {
    final list = _extractList(data);
    if (list == null) return const [];

    final out = <ReferenceOption>[];
    for (final item in list) {
      if (item is String) {
        final v = item.trim();
        if (v.isEmpty) continue;
        out.add(ReferenceOption(value: v, label: v));
        continue;
      }

      if (item is Map) {
        String? pickKey(Map m, List<String> keys) {
          for (final k in keys) {
            final v = m[k];
            if (v == null) continue;
            final s = v.toString().trim();
            if (s.isNotEmpty) return s;
          }
          return null;
        }

        final value = pickKey(item, valueKeys) ?? pickKey(item, labelKeys);
        if (value == null || value.trim().isEmpty) continue;
        final label = pickKey(item, labelKeys) ?? value;

        out.add(ReferenceOption(value: value, label: label));
        continue;
      }
    }

    out.sort((a, b) => a.label.compareTo(b.label));
    return out;
  }

  List? _extractList(Object? data) {
    List? walk(Object? node, int depth) {
      if (depth > 5) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      final candidates = [map['data'], map['items'], map['result']];
      for (final candidate in candidates) {
        if (candidate is List) return candidate;
        if (candidate is Map || candidate is List) {
          final found = walk(candidate, depth + 1);
          if (found != null) return found;
        }
      }

      for (final value in map.values) {
        if (value is Map || value is List) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0);
  }

  String _labelForString(String v) {
    // If it looks like an offset, make a nicer label.
    final offsetRe = RegExp(r'^[+-]\\d{2}:\\d{2}$');
    if (offsetRe.hasMatch(v)) return 'GMT$v';
    return v;
  }
}

class TimezoneOption {
  final String value;
  final String label;

  const TimezoneOption({required this.value, required this.label});
}

class ReferenceOption {
  final String value;
  final String label;

  const ReferenceOption({required this.value, required this.label});
}

class CountryOption {
  final String name;
  final String isoCode;

  const CountryOption({required this.name, required this.isoCode});
}

class MobilePrefixOption {
  final String countryCode;
  final String code;

  const MobilePrefixOption({required this.countryCode, required this.code});
}
