class SuperadminDocumentType {
  final int id;
  final String name;
  final String docFor;

  const SuperadminDocumentType({
    required this.id,
    required this.name,
    required this.docFor,
  });

  factory SuperadminDocumentType.fromJson(Map<String, dynamic> json) {
    return SuperadminDocumentType(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString().trim(),
      docFor: (json['docFor'] ?? '').toString().trim(),
    );
  }
}
