class AdminDashboardResponse {
  const AdminDashboardResponse({required this.data});
  final Map<String, dynamic> data;
  factory AdminDashboardResponse.fromJson(Map<String, dynamic> json) => AdminDashboardResponse(data: json);
  Map<String, dynamic> toJson() => data;
}

class AdminUserListResponse {
  const AdminUserListResponse({required this.items, required this.total});
  final List<Map<String, dynamic>> items;
  final int total;
  factory AdminUserListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map ? Map<String, dynamic>.from(data.cast()) : json;
    final rawItems = source['users'] ?? source['items'] ?? source['data'] ?? const [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e.cast())).toList()
        : <Map<String, dynamic>>[];
    return AdminUserListResponse(items: items, total: int.tryParse((source['total'] ?? items.length).toString()) ?? items.length);
  }
  Map<String, dynamic> toJson() => {'items': items, 'total': total};
}
