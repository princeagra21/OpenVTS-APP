class SuperadminAdminsResponse {
  const SuperadminAdminsResponse({required this.items, required this.total});
  final List<Map<String, dynamic>> items;
  final int total;
  factory SuperadminAdminsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map ? Map<String, dynamic>.from(data.cast()) : json;
    final rawItems = source['admins'] ?? source['items'] ?? source['data'] ?? const [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e.cast())).toList()
        : <Map<String, dynamic>>[];
    return SuperadminAdminsResponse(items: items, total: int.tryParse((source['total'] ?? items.length).toString()) ?? items.length);
  }
  Map<String, dynamic> toJson() => {'items': items, 'total': total};
}

class SuperadminDashboardResponse {
  const SuperadminDashboardResponse({required this.data});
  final Map<String, dynamic> data;
  factory SuperadminDashboardResponse.fromJson(Map<String, dynamic> json) => SuperadminDashboardResponse(data: json);
  Map<String, dynamic> toJson() => data;
}
