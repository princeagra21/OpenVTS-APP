import 'package:flutter/foundation.dart';
import 'package:open_vts/features/documents/document_models.dart';

@immutable
class DocumentPermissions {
  const DocumentPermissions({
    this.canLoadDocTypes = true,
    this.canUpload = true,
    this.canUpdate = true,
    this.canSetVisibility = true,
    this.fileRequiredOnCreate = true,
    this.requireAssociateOnCreate = true,
  });

  final bool canLoadDocTypes;
  final bool canUpload;
  final bool canUpdate;
  final bool canSetVisibility;
  final bool fileRequiredOnCreate;
  final bool requireAssociateOnCreate;

  static const DocumentPermissions admin = DocumentPermissions();
  static const DocumentPermissions superadmin = DocumentPermissions();
  static const DocumentPermissions user = DocumentPermissions(
    canSetVisibility: false,
  );

  static DocumentPermissions forRole(DocumentFeatureRole role) {
    switch (role) {
      case DocumentFeatureRole.admin:
        return admin;
      case DocumentFeatureRole.superadmin:
        return superadmin;
      case DocumentFeatureRole.user:
        return user;
    }
  }
}
