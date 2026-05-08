import 'dart:typed_data';

import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/features/documents/document_permissions.dart';

class DocumentFormValidators {
  const DocumentFormValidators._();

  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  static String? validatePickedFile(Uint8List? bytes) {
    if (bytes == null) {
      return 'Unable to read selected file.';
    }
    if (bytes.length > maxFileSizeBytes) {
      return 'File must be 5 MB or smaller.';
    }
    return null;
  }

  static String? validateBeforeSubmit({
    required bool isEdit,
    required DocumentPermissions permissions,
    required SuperadminDocumentType? selectedDocType,
    required String title,
    required String associateId,
    required Uint8List? selectedFileBytes,
    required String? selectedFileName,
    required String documentId,
  }) {
    if (isEdit && !permissions.canUpdate) {
      return 'You do not have permission to edit documents.';
    }

    if (!isEdit && !permissions.canUpload) {
      return 'You do not have permission to upload documents.';
    }

    if (selectedDocType == null) {
      return 'Please select a document type.';
    }

    if (title.isEmpty) {
      return 'Please enter a title.';
    }

    if (!isEdit &&
        permissions.requireAssociateOnCreate &&
        associateId.isEmpty) {
      return 'Please select an associate.';
    }

    if (!isEdit && permissions.fileRequiredOnCreate) {
      if (selectedFileBytes == null || selectedFileName == null) {
        return 'Please upload a file.';
      }
    }

    if (isEdit && documentId.isEmpty) {
      return 'Document id is missing.';
    }

    return null;
  }
}
