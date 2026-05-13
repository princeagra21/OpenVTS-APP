import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_feedback.dart';
import 'package:open_vts/features/documents/presentation/controllers/document_form_actions.dart';
import 'package:open_vts/features/documents/presentation/controllers/document_form_controller.dart';
import 'package:open_vts/features/documents/data/repositories/document_repository.dart';
import 'package:open_vts/features/documents/domain/entities/document_models.dart';
import 'package:open_vts/features/documents/domain/permissions/document_permissions.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_expiry_picker.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_file_picker.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_form_header.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_form_submit_bar.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_text_fields.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_type_selector.dart';
import 'package:open_vts/features/documents/presentation/widgets/document_visibility_toggle.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class DocumentFormScreen extends StatefulWidget {
  const DocumentFormScreen({
    super.key,
    required this.input,
    required this.repository,
    required this.permissions,
  });

  final DocumentFormInput input;
  final DocumentRepositoryAdapter repository;
  final DocumentPermissions permissions;

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  late final DocumentFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DocumentFormController(
      input: widget.input,
      repository: widget.repository,
      permissions: widget.permissions,
    );
    _controller.addListener(_handleControllerChanged);
    unawaited(_loadDocumentTypes());
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    updateLocalUiState(this, () {});
  }

  Future<void> _loadDocumentTypes() async {
    final message = await _controller.initialize();
    if (!mounted || message == null) {
      return;
    }
    _showDocTypeError(message);
  }

  Future<void> _retryLoadDocumentTypes() async {
    final message = await _controller.loadDocumentTypes();
    if (!mounted || message == null) {
      return;
    }
    _showDocTypeError(message);
  }

  Future<void> _pickExpiryDate() async {
    final selectedDate = await DocumentFormActions.pickExpiryDate(context);
    if (selectedDate == null) {
      return;
    }
    _controller.setExpiryDate(selectedDate);
  }

  Future<void> _pickFile() async {
    final file = await DocumentFormActions.pickDocumentFile();
    if (file == null) {
      return;
    }

    final error = _controller.applyPickedFile(file);
    if (error != null) {
      _showSnack(error);
    }
  }

  Future<void> _openDocumentTypePicker() async {
    final state = _controller.state;
    if (state.loadingDocTypes) {
      return;
    }

    final selected = await DocumentFormActions.openDocumentTypePicker(
      context: context,
      docTypes: state.docTypes,
      selectedDocType: state.selectedDocType,
      loadingDocTypes: state.loadingDocTypes,
    );

    if (selected != null) {
      _controller.setSelectedDocType(selected);
    }
  }

  Future<void> _submit() async {
    final result = await _controller.submit();
    if (!mounted || result.message == null) {
      return;
    }

    _showSnack(result.message!);
    if (result.isSuccess) {
      Navigator.pop(context, true);
    }
  }

  void _showDocTypeError(String message) {
    if (!mounted) {
      return;
    }
    OpenVtsFeedback.error(
      context,
      message,
      actionLabel: 'Retry',
      onAction: () {
        unawaited(_retryLoadDocumentTypes());
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    OpenVtsFeedback.info(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final isEdit = _controller.isEdit;

    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width);
    final labelSize = AdaptiveUtils.getTitleFontSize(width);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocumentFormHeader(
                isEdit: isEdit,
                titleSize: titleSize,
                labelSize: labelSize,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEdit) ...[
                        _AssociateBanner(
                          associateLabel: _controller.associateLabel,
                          labelSize: labelSize,
                        ),
                        const SizedBox(height: 24),
                      ],
                      DocumentTypeSelectorField(
                        screenWidth: width,
                        labelSize: labelSize,
                        selectedType: state.selectedDocType,
                        loading: state.loadingDocTypes,
                        onTap: _openDocumentTypePicker,
                      ),
                      const SizedBox(height: 24),
                      DocumentTitleField(
                        contextForDecoration: context,
                        screenWidth: width,
                        labelSize: labelSize,
                        titleController: _controller.titleController,
                      ),
                      const SizedBox(height: 24),
                      DocumentExpiryPicker(
                        screenWidth: width,
                        labelSize: labelSize,
                        selectedExpiryLabel: state.selectedExpiryLabel,
                        onTap: _pickExpiryDate,
                      ),
                      if (widget.permissions.canSetVisibility) ...[
                        const SizedBox(height: 24),
                        DocumentVisibilityToggle(
                          screenWidth: width,
                          value: state.isVisible,
                          onChanged: _controller.setVisibility,
                        ),
                      ],
                      const SizedBox(height: 24),
                      DocumentTagsAndDescriptionFields(
                        contextForDecoration: context,
                        screenWidth: width,
                        labelSize: labelSize,
                        tagsController: _controller.tagsController,
                        descriptionController:
                            _controller.descriptionController,
                      ),
                      const SizedBox(height: 24),
                      DocumentFilePicker(
                        isEdit: isEdit,
                        screenWidth: width,
                        labelSize: labelSize,
                        selectedFileName: state.selectedFileName,
                        selectedFileSize: state.selectedFileSize,
                        currentFileName: _controller.currentFileName,
                        onTap: _pickFile,
                      ),
                      const SizedBox(height: 32),
                      DocumentFormSubmitBar(
                        isEdit: isEdit,
                        submitting: state.submitting,
                        onCancel: () => Navigator.pop(context),
                        onSubmit: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssociateBanner extends StatelessWidget {
  const _AssociateBanner({
    required this.associateLabel,
    required this.labelSize,
  });

  final String associateLabel;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Text(
        associateLabel,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: AppFonts.roboto(
          fontSize: labelSize,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
