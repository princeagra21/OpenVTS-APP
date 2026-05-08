import 'package:flutter/material.dart';
import 'package:open_vts/features/documents/document_form_view.dart';
import 'package:open_vts/features/documents/document_models.dart';
import 'package:open_vts/features/documents/document_permissions.dart';
import 'package:open_vts/features/documents/document_repository.dart';

export 'package:open_vts/features/documents/document_form_view.dart'
    show DocumentFormScreen;

class AdminAddDocumentScreen extends StatelessWidget {
  const AdminAddDocumentScreen({
    super.key,
    this.associateId,
    this.associateType = 'USER',
    this.associateName,
    this.repository,
    this.permissions = DocumentPermissions.admin,
  });

  final String? associateId;
  final String associateType;
  final String? associateName;
  final DocumentRepositoryAdapter? repository;
  final DocumentPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return DocumentFormScreen(
      input: DocumentFormInput(
        role: DocumentFeatureRole.admin,
        mode: DocumentFormMode.create,
        associateId: associateId,
        associateType: associateType,
        associateName: associateName,
      ),
      repository: repository ?? AdminDocumentRepositoryAdapter(),
      permissions: permissions,
    );
  }
}

class AdminEditDocumentScreen extends StatelessWidget {
  const AdminEditDocumentScreen({
    super.key,
    required this.document,
    this.repository,
    this.permissions = DocumentPermissions.admin,
  });

  final Map<String, dynamic> document;
  final DocumentRepositoryAdapter? repository;
  final DocumentPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return DocumentFormScreen(
      input: DocumentFormInput(
        role: DocumentFeatureRole.admin,
        mode: DocumentFormMode.edit,
        initialDocument: document,
      ),
      repository: repository ?? AdminDocumentRepositoryAdapter(),
      permissions: permissions,
    );
  }
}

class SuperadminAddDocumentScreen extends StatelessWidget {
  const SuperadminAddDocumentScreen({
    super.key,
    this.associateId,
    this.associateType = 'USER',
    this.associateName,
    this.repository,
    this.permissions = DocumentPermissions.superadmin,
  });

  final String? associateId;
  final String associateType;
  final String? associateName;
  final DocumentRepositoryAdapter? repository;
  final DocumentPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return DocumentFormScreen(
      input: DocumentFormInput(
        role: DocumentFeatureRole.superadmin,
        mode: DocumentFormMode.create,
        associateId: associateId,
        associateType: associateType,
        associateName: associateName,
      ),
      repository: repository ?? SuperadminDocumentRepositoryAdapter(),
      permissions: permissions,
    );
  }
}

class SuperadminEditDocumentScreen extends StatelessWidget {
  const SuperadminEditDocumentScreen({
    super.key,
    required this.document,
    this.repository,
    this.permissions = DocumentPermissions.superadmin,
  });

  final Map<String, dynamic> document;
  final DocumentRepositoryAdapter? repository;
  final DocumentPermissions permissions;

  @override
  Widget build(BuildContext context) {
    return DocumentFormScreen(
      input: DocumentFormInput(
        role: DocumentFeatureRole.superadmin,
        mode: DocumentFormMode.edit,
        initialDocument: document,
      ),
      repository: repository ?? SuperadminDocumentRepositoryAdapter(),
      permissions: permissions,
    );
  }
}
