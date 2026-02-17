class AdminDocumentItem {
  final Map<String, dynamic> raw;

  const AdminDocumentItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['docId'] ??
        raw['doc_id'] ??
        raw['documentId'] ??
        raw['document_id'] ??
        raw['uuid'] ??
        raw['uid'],
  );

  String get title => _string(
    raw['title'] ??
        raw['fileName'] ??
        raw['filename'] ??
        raw['name'] ??
        raw['documentName'],
  );

  String get type => _string(
    raw['type'] ?? raw['docType'] ?? raw['docTypeName'] ?? raw['category'],
  );

  String get status => _string(
    raw['status'] ?? raw['health'] ?? raw['state'] ?? raw['docStatus'],
  );

  int get sizeBytes => _int(
    raw['sizeBytes'] ??
        raw['size_bytes'] ??
        raw['fileSizeBytes'] ??
        raw['file_size_bytes'] ??
        raw['size'],
  );

  String get uploadedAt => _string(
    raw['uploadedAt'] ??
        raw['uploaded_at'] ??
        raw['createdAt'] ??
        raw['created_at'] ??
        raw['uploadedDate'],
  );

  String get expiresAt => _string(
    raw['expiresAt'] ??
        raw['expires_at'] ??
        raw['expiryAt'] ??
        raw['expiry_at'] ??
        raw['expiryDate'],
  );

  String get fileUrl => _string(
    raw['fileUrl'] ??
        raw['url'] ??
        raw['file'] ??
        raw['path'] ??
        raw['downloadUrl'],
  );

  List<String> get tags {
    final t = raw['tags'];
    if (t is List) {
      return t.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (t is String && t.trim().isNotEmpty) {
      return t
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  bool get isExpired {
    final s = status.trim().toLowerCase();
    if (s.contains('expired')) return true;
    if (expiresAt.trim().isEmpty) return false;
    final dt = DateTime.tryParse(expiresAt.trim());
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  bool get isWarning {
    final s = status.trim().toLowerCase();
    if (s.contains('expiring') || s.contains('warning')) return true;
    if (expiresAt.trim().isEmpty) return false;
    final dt = DateTime.tryParse(expiresAt.trim());
    if (dt == null) return false;
    return dt.difference(DateTime.now()).inDays <= 30 &&
        !dt.isBefore(DateTime.now());
  }

  bool get isValid {
    final s = status.trim().toLowerCase();
    if (s.contains('valid') || s.contains('ok')) return true;
    if (isExpired || isWarning) return false;
    return false;
  }

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static int _int(Object? v) {
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
