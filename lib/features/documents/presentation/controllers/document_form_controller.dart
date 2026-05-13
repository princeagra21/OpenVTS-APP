import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/core/error/legacy_error_presenter.dart';
import 'package:open_vts/features/documents/presentation/controllers/document_form_state.dart';
import 'package:open_vts/features/documents/domain/validators/document_form_validators.dart';
import 'package:open_vts/features/documents/data/repositories/document_repository.dart';
import 'package:open_vts/features/documents/domain/entities/document_models.dart';
import 'package:open_vts/features/documents/domain/permissions/document_permissions.dart';
import 'package:open_vts/core/state/listenable_controller.dart';

@immutable
class DocumentFormSubmitResult {
  const DocumentFormSubmitResult._({
    required this.isSuccess,
    required this.message,
  });

  const DocumentFormSubmitResult.success(String message)
    : this._(isSuccess: true, message: message);

  const DocumentFormSubmitResult.failure(String message)
    : this._(isSuccess: false, message: message);

  const DocumentFormSubmitResult.idle()
    : this._(isSuccess: false, message: null);

  final bool isSuccess;
  final String? message;
}

class DocumentFormController extends ListenableController {
  DocumentFormController({
    required this.input,
    required this.repository,
    required this.permissions,
  }) {
    if (isEdit) {
      _prefillFromDocument();
    }
  }

  final DocumentFormInput input;
  final DocumentRepositoryAdapter repository;
  final DocumentPermissions permissions;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  AppCancellationHandle? _loadToken;
  AppCancellationHandle? _submitToken;

  DocumentFormState _state = const DocumentFormState();
  bool _docTypesErrorShown = false;
  bool _disposed = false;

  DocumentFormState get state => _state;
  bool get isEdit => input.isEdit;
  Map<String, dynamic> get document => input.initialDocument ?? const {};

  String get associateLabel {
    if (input.associateName?.trim().isNotEmpty == true) {
      return input.associateName!.trim();
    }
    return 'Select associate';
  }

  String get currentFileName =>
      _safe(document['fileName'], fallback: 'Current file');

  Future<String?> initialize() {
    return loadDocumentTypes();
  }

  Future<String?> loadDocumentTypes() async {
    if (!permissions.canLoadDocTypes) {
      return null;
    }

    _loadToken?.cancel('Reload document types');
    final token = AppCancellationHandle();
    _loadToken = token;

    _emitState(_state.copyWith(loadingDocTypes: true));

    try {
      final result = await repository.getDocumentTypes(cancelToken: token);
      if (_disposed) {
        return null;
      }

      String? message;
      result.when(
        success: (items) {
          final existingDocTypeId = _safeInt(document['docTypeId']);

          SuperadminDocumentType? selected = _state.selectedDocType;
          if (isEdit && existingDocTypeId != null) {
            for (final item in items) {
              if (item.id == existingDocTypeId) {
                selected = item;
                break;
              }
            }
          }

          selected ??= items.isNotEmpty ? items.first : null;

          _docTypesErrorShown = false;
          _emitState(
            _state.copyWith(
              loadingDocTypes: false,
              docTypes: items,
              selectedDocType: selected,
            ),
          );
        },
        failure: (err) {
          _emitState(_state.copyWith(loadingDocTypes: false));

          if (_docTypesErrorShown) {
            return;
          }
          _docTypesErrorShown = true;

          message =
              LegacyErrorPresenter.isApiFailure(err) &&
                  (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)
              ? 'Not authorized to view document types.'
              : "Couldn't load document types.";
        },
      );

      return message;
    } catch (_) {
      if (_disposed) {
        return null;
      }

      _emitState(_state.copyWith(loadingDocTypes: false));
      if (_docTypesErrorShown) {
        return null;
      }

      _docTypesErrorShown = true;
      return "Couldn't load document types.";
    }
  }

  void setSelectedDocType(SuperadminDocumentType type) {
    _emitState(_state.copyWith(selectedDocType: type));
  }

  void setVisibility(bool value) {
    _emitState(_state.copyWith(isVisible: value));
  }

  void setExpiryDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    _emitState(
      _state.copyWith(
        selectedExpiryAt: dateOnly.toUtc().toIso8601String(),
        selectedExpiryLabel:
            '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}',
      ),
    );
  }

  String? applyPickedFile(PlatformFile file) {
    final bytes = file.bytes;
    final validationError = DocumentFormValidators.validatePickedFile(bytes);
    if (validationError != null) {
      return validationError;
    }

    _emitState(
      _state.copyWith(
        selectedFileBytes: bytes,
        selectedFileName: file.name,
        selectedFileSize: bytes!.length,
      ),
    );

    return null;
  }

  Future<DocumentFormSubmitResult> submit() async {
    if (_state.submitting) {
      return const DocumentFormSubmitResult.idle();
    }

    final title = titleController.text.trim();
    final associateId = input.associateId?.trim() ?? '';
    final documentId = _safe(document['id'], fallback: '');

    final validationError = DocumentFormValidators.validateBeforeSubmit(
      isEdit: isEdit,
      permissions: permissions,
      selectedDocType: _state.selectedDocType,
      title: title,
      associateId: associateId,
      selectedFileBytes: _state.selectedFileBytes,
      selectedFileName: _state.selectedFileName,
      documentId: documentId,
    );

    if (validationError != null) {
      return DocumentFormSubmitResult.failure(validationError);
    }

    _submitToken?.cancel('DocumentFormScreen submit');
    final token = AppCancellationHandle();
    _submitToken = token;

    _emitState(_state.copyWith(submitting: true));

    try {
      final result = isEdit
          ? await repository.updateDocument(
              documentId: documentId,
              docTypeId: _state.selectedDocType!.id,
              title: title,
              description: descriptionController.text.trim(),
              tags: tagsController.text.trim(),
              expiryAt: _state.selectedExpiryAt,
              isVisible: permissions.canSetVisibility ? _state.isVisible : null,
              fileBytes: _state.selectedFileBytes,
              filename: _state.selectedFileName,
              contentType: _contentTypeFor(_state.selectedFileName),
              cancelToken: token,
            )
          : await repository.uploadDocument(
              associateType: input.associateType,
              associateId: associateId,
              docTypeId: _state.selectedDocType!.id,
              title: title,
              fileBytes: _state.selectedFileBytes!,
              filename: _state.selectedFileName!,
              description: descriptionController.text.trim(),
              tags: tagsController.text.trim(),
              expiryAt: _state.selectedExpiryAt,
              isVisible: permissions.canSetVisibility ? _state.isVisible : true,
              contentType: _contentTypeFor(_state.selectedFileName),
              cancelToken: token,
            );

      if (result.isSuccess) {
        return DocumentFormSubmitResult.success(
          isEdit
              ? 'Document updated successfully'
              : 'Document uploaded successfully',
        );
      }

      final err = result.error;
      if (LegacyErrorPresenter.isApiFailure(err) &&
          (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)) {
        return DocumentFormSubmitResult.failure(
          isEdit
              ? 'Not authorized to update document.'
              : 'Not authorized to upload document.',
        );
      }

      return DocumentFormSubmitResult.failure(
        isEdit ? "Couldn't update document." : "Couldn't upload document.",
      );
    } catch (_) {
      return DocumentFormSubmitResult.failure(
        isEdit ? "Couldn't update document." : "Couldn't upload document.",
      );
    } finally {
      _emitState(_state.copyWith(submitting: false));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadToken?.cancel('DocumentFormScreen disposed');
    _submitToken?.cancel('DocumentFormScreen disposed');
    titleController.dispose();
    tagsController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String _safe(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int? _safeInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  String? _contentTypeFor(String? fileName) {
    final lower = fileName?.toLowerCase() ?? '';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return null;
  }

  void _prefillFromDocument() {
    titleController.text = _safe(
      document['title'],
      fallback: _safe(document['fileName']),
    );

    final tags = document['tags'];
    tagsController.text = tags is List ? tags.join(', ') : _safe(tags);
    descriptionController.text = _safe(document['description']);

    final rawExpiry = _safe(document['expiryAt'] ?? document['expiryDate']);
    final parsed = DateTime.tryParse(rawExpiry);
    if (parsed == null) {
      _state = _state.copyWith(isVisible: document['isVisible'] == true);
      return;
    }

    final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
    _state = _state.copyWith(
      isVisible: document['isVisible'] == true,
      selectedExpiryAt: dateOnly.toUtc().toIso8601String(),
      selectedExpiryLabel:
          '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}',
    );
  }

  void _emitState(DocumentFormState newState) {
    if (_disposed) {
      return;
    }
    _state = newState;
    notifyListeners();
  }
}
