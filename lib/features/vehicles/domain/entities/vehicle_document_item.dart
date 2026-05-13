class VehicleDocumentItem {
  VehicleDocumentItem(Object? source)
      : id = source is VehicleDocumentItem ? source.id : _readString(source, const ['id', 'documentId', 'document_id']),
        fileName = source is VehicleDocumentItem ? source.fileName : _readString(source, const ['fileName', 'filename', 'name', 'title', 'originalName']),
        type = source is VehicleDocumentItem ? source.type : _readString(source, const ['type', 'documentType', 'docType']),
        status = source is VehicleDocumentItem ? source.status : _readString(source, const ['status', 'health', 'state']),
        sizeBytes = source is VehicleDocumentItem ? source.sizeBytes : _readInt(source, const ['sizeBytes', 'size', 'fileSize']),
        uploadedAt = source is VehicleDocumentItem ? source.uploadedAt : _readString(source, const ['uploadedAt', 'uploadedDate']),
        expiresAt = source is VehicleDocumentItem ? source.expiresAt : _readString(source, const ['expiresAt', 'expiryDate']),
        url = source is VehicleDocumentItem ? source.url : _readString(source, const ['fileUrl', 'url', 'path']);

  const VehicleDocumentItem.typed({
    required this.id,
    required this.fileName,
    required this.type,
    required this.status,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.expiresAt,
    required this.url,
  });

  final String id;
  final String fileName;
  final String type;
  final String status;
  final int sizeBytes;
  final String uploadedAt;
  final String expiresAt;
  final String url;

  Map<String, Object?> get raw => <String, Object?>{
        'id': id,
        'documentId': id,
        'fileName': fileName,
        'filename': fileName,
        'name': fileName,
        'title': fileName,
        'type': type,
        'documentType': type,
        'docType': type,
        'status': status,
        'sizeBytes': sizeBytes,
        'uploadedAt': uploadedAt,
        'expiresAt': expiresAt,
        'fileUrl': url,
        'url': url,
        'path': url,
      };

  Object? valueFor(String key) {
    switch (key) {
      case 'id':
      case 'documentId':
      case 'document_id':
        return id;
      case 'fileName':
      case 'filename':
      case 'name':
      case 'title':
      case 'originalName':
        return fileName;
      case 'type':
      case 'documentType':
      case 'docType':
        return type;
      case 'status':
      case 'health':
      case 'state':
        return status;
      case 'sizeBytes':
      case 'size':
      case 'fileSize':
        return sizeBytes;
      case 'uploadedAt':
      case 'uploadedDate':
        return uploadedAt;
      case 'expiresAt':
      case 'expiryDate':
        return expiresAt;
      case 'fileUrl':
      case 'url':
      case 'path':
        return url;
    }
    return null;
  }

  static String _readString(Object? source, List<String> keys) {
    final map = _objectMap(source);
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static int _readInt(Object? source, List<String> keys) {
    final text = _readString(source, keys).replaceAll(',', '').trim();
    return int.tryParse(text) ?? 0;
  }

  static Map<String, Object?> _objectMap(Object? source) {
    if (source is VehicleDocumentItem) {
      return <String, Object?>{
        'id': source.id,
        'fileName': source.fileName,
        'type': source.type,
        'status': source.status,
        'sizeBytes': source.sizeBytes,
        'uploadedAt': source.uploadedAt,
        'expiresAt': source.expiresAt,
        'url': source.url,
      };
    }
    if (source is Map) {
      return <String, Object?>{for (final e in source.entries) e.key.toString(): e.value};
    }
    return const <String, Object?>{};
  }
}
