import 'package:flutter/foundation.dart';

enum DocumentFeatureRole { admin, superadmin, user }

enum DocumentFormMode { create, edit }

@immutable
class DocumentFormInput {
  const DocumentFormInput({
    required this.role,
    required this.mode,
    this.associateId,
    this.associateType = 'USER',
    this.associateName,
    this.initialDocument,
  });

  final DocumentFeatureRole role;
  final DocumentFormMode mode;
  final String? associateId;
  final String associateType;
  final String? associateName;
  final Map<String, dynamic>? initialDocument;

  bool get isEdit => mode == DocumentFormMode.edit;
}
