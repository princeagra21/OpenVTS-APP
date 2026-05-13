class UserDashboardResponse {
  const UserDashboardResponse({required this.data});
  final Map<String, dynamic> data;
  factory UserDashboardResponse.fromJson(Map<String, dynamic> json) => UserDashboardResponse(data: json);
  Map<String, dynamic> toJson() => data;
}

class UserVehicleListResponse {
  const UserVehicleListResponse({required this.items, required this.total});
  final List<Map<String, dynamic>> items;
  final int total;
  factory UserVehicleListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map ? Map<String, dynamic>.from(data.cast()) : json;
    final rawItems = source['vehicles'] ?? source['items'] ?? source['data'] ?? const [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e.cast())).toList()
        : <Map<String, dynamic>>[];
    return UserVehicleListResponse(items: items, total: int.tryParse((source['total'] ?? items.length).toString()) ?? items.length);
  }
  Map<String, dynamic> toJson() => {'items': items, 'total': total};
}
