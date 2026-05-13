class SupportTicketListResponse {
  const SupportTicketListResponse({required this.items, required this.total});
  final List<Map<String, dynamic>> items;
  final int total;
  factory SupportTicketListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final source = data is Map ? Map<String, dynamic>.from(data.cast()) : json;
    final rawItems = source['tickets'] ?? source['items'] ?? source['data'] ?? const [];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e.cast())).toList()
        : <Map<String, dynamic>>[];
    return SupportTicketListResponse(
      items: items,
      total: int.tryParse((source['total'] ?? source['count'] ?? items.length).toString()) ?? items.length,
    );
  }
  Map<String, dynamic> toJson() => {'items': items, 'total': total};
}

class SupportTicketResponse {
  const SupportTicketResponse({required this.data});
  final Map<String, dynamic> data;
  factory SupportTicketResponse.fromJson(Map<String, dynamic> json) => SupportTicketResponse(data: json);
  Map<String, dynamic> toJson() => data;
}
