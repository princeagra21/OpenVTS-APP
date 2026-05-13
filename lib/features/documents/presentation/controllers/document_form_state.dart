import 'package:flutter/foundation.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';

const Object _documentFormUnset = Object();

@immutable
class DocumentFormState {
  const DocumentFormState({
    this.loadingDocTypes = false,
    this.submitting = false,
    this.docTypes = const [],
    this.selectedDocType,
    this.selectedExpiryAt,
    this.selectedExpiryLabel,
    this.isVisible = true,
    this.selectedFileBytes,
    this.selectedFileName,
    this.selectedFileSize = 0,
  });

  final bool loadingDocTypes;
  final bool submitting;
  final List<SuperadminDocumentType> docTypes;
  final SuperadminDocumentType? selectedDocType;
  final String? selectedExpiryAt;
  final String? selectedExpiryLabel;
  final bool isVisible;
  final Uint8List? selectedFileBytes;
  final String? selectedFileName;
  final int selectedFileSize;

  bool get hasPickedFile =>
      selectedFileBytes != null && selectedFileName != null;

  DocumentFormState copyWith({
    bool? loadingDocTypes,
    bool? submitting,
    List<SuperadminDocumentType>? docTypes,
    Object? selectedDocType = _documentFormUnset,
    Object? selectedExpiryAt = _documentFormUnset,
    Object? selectedExpiryLabel = _documentFormUnset,
    bool? isVisible,
    Object? selectedFileBytes = _documentFormUnset,
    Object? selectedFileName = _documentFormUnset,
    int? selectedFileSize,
  }) {
    return DocumentFormState(
      loadingDocTypes: loadingDocTypes ?? this.loadingDocTypes,
      submitting: submitting ?? this.submitting,
      docTypes: docTypes ?? this.docTypes,
      selectedDocType: identical(selectedDocType, _documentFormUnset)
          ? this.selectedDocType
          : selectedDocType as SuperadminDocumentType?,
      selectedExpiryAt: identical(selectedExpiryAt, _documentFormUnset)
          ? this.selectedExpiryAt
          : selectedExpiryAt as String?,
      selectedExpiryLabel: identical(selectedExpiryLabel, _documentFormUnset)
          ? this.selectedExpiryLabel
          : selectedExpiryLabel as String?,
      isVisible: isVisible ?? this.isVisible,
      selectedFileBytes: identical(selectedFileBytes, _documentFormUnset)
          ? this.selectedFileBytes
          : selectedFileBytes as Uint8List?,
      selectedFileName: identical(selectedFileName, _documentFormUnset)
          ? this.selectedFileName
          : selectedFileName as String?,
      selectedFileSize: selectedFileSize ?? this.selectedFileSize,
    );
  }
}
