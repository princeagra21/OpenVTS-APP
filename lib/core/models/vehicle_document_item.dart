class VehicleDocumentItem {
  final Map<String, dynamic> raw;

  const VehicleDocumentItem(this.raw);

  String get id => _s(raw['id'] ?? raw['documentId'] ?? raw['document_id']);

  String get fileName => _s(
    raw['fileName'] ??
        raw['filename'] ??
        raw['name'] ??
        raw['title'] ??
        raw['originalName'],
  );

  String get type => _s(raw['type'] ?? raw['documentType'] ?? raw['docType']);

  String get status => _s(raw['status'] ?? raw['health'] ?? raw['state']);

  int get sizeBytes => _i(raw['sizeBytes'] ?? raw['size'] ?? raw['fileSize']);

  String get uploadedAt => _s(raw['uploadedAt'] ?? raw['uploadedDate']);

  String get expiresAt => _s(raw['expiresAt'] ?? raw['expiryDate']);

  String get url => _s(raw['fileUrl'] ?? raw['url'] ?? raw['path']);

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static int _i(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return int.tryParse(v.toString()) ?? 0;
  }
}

