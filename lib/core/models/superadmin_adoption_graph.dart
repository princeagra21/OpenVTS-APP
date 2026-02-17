class SuperadminAdoptionGraph {
  final Map<String, dynamic> raw;

  const SuperadminAdoptionGraph(this.raw);

  /// Returns 12 points (pads with zeros or truncates from the left).
  List<double> vehicles({int points = 12}) =>
      _normalized(_seriesForMetric('vehicles'), points);

  List<double> users({int points = 12}) =>
      _normalized(_seriesForMetric('users'), points);

  List<double> licenses({int points = 12}) =>
      _normalized(_seriesForMetric('licenses'), points);

  List<double> _seriesForMetric(String metric) {
    final root = _coerceMap(raw);
    final data = root['data'];

    // Common shape: { data: { vehicles: [...], users: [...], licenses: [...] } }
    if (data is Map) {
      final m = _coerceMap(data);
      final direct = m[metric];
      final list = _coerceNumList(direct);
      if (list != null) return list;
    }

    // Common shape: { vehicles: [...], users: [...], licenses: [...] }
    final direct = root[metric];
    final list = _coerceNumList(direct);
    if (list != null) return list;

    // Common shape: { data/items/results: [ { month, vehicles, users, licenses }, ... ] }
    final rows = _extractList(root);
    if (rows != null) {
      final out = <double>[];
      for (final it in rows) {
        if (it is Map) {
          final v =
              it[metric] ??
              it['${metric}Count'] ??
              it['${metric}_count'] ??
              it['total${_cap(metric)}'];
          out.add(_num(v));
        }
      }
      if (out.isNotEmpty) return out;
    }

    return const <double>[];
  }

  static List? _extractList(Map m) {
    final keys = const ['data', 'items', 'result', 'results'];
    for (final k in keys) {
      final v = m[k];
      if (v is List) return v;
      if (v is Map) {
        for (final kk in keys) {
          final vv = v[kk];
          if (vv is List) return vv;
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _coerceMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  static List<double>? _coerceNumList(Object? v) {
    if (v is List) {
      final out = <double>[];
      for (final it in v) {
        out.add(_num(it));
      }
      return out;
    }
    return null;
  }

  static double _num(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '').trim()) ?? 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  static List<double> _normalized(List<double> inList, int points) {
    if (points <= 0) return const <double>[];
    if (inList.length == points) return inList;
    if (inList.length > points) {
      return inList.sublist(inList.length - points);
    }
    final pad = List<double>.filled(points - inList.length, 0);
    return <double>[...pad, ...inList];
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
