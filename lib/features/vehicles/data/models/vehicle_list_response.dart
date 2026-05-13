class VehicleListResponse {
  const VehicleListResponse({
    required this.items,
    required this.total,
    this.page = 1,
    this.limit = 20,
  });

  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final int limit;

  factory VehicleListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map ? Map<String, dynamic>.from(data.cast()) : json;
    final rawItems = source['vehicles'] ?? source['items'] ?? source['data'] ?? source['results'] ?? const [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e.cast())).toList()
        : <Map<String, dynamic>>[];
    return VehicleListResponse(
      items: items,
      total: int.tryParse((source['total'] ?? source['count'] ?? items.length).toString()) ?? items.length,
      page: int.tryParse((source['page'] ?? 1).toString()) ?? 1,
      limit: int.tryParse((source['limit'] ?? items.length).toString()) ?? items.length,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'items': items,
        'total': total,
        'page': page,
        'limit': limit,
      };
}

class VehicleResponse {
  const VehicleResponse({required this.data});
  final Map<String, dynamic> data;
  factory VehicleResponse.fromJson(Map<String, dynamic> json) => VehicleResponse(data: json);
  Map<String, dynamic> toJson() => data;
}
