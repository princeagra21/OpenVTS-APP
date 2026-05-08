import 'dart:typed_data';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/features/documents/document_models.dart';
import 'package:open_vts/features/documents/document_permissions.dart';
import 'package:open_vts/features/documents/document_repository.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  CancelToken? _loadToken;
  CancelToken? _submitToken;

  bool _loadingDocTypes = false;
  bool _submitting = false;
  bool _docTypesErrorShown = false;

  List<SuperadminDocumentType> _docTypes = const [];
  SuperadminDocumentType? _selectedDocType;

  String? _selectedExpiryAt;
  String? _selectedExpiryLabel;
  bool _isVisible = true;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int _selectedFileSize = 0;

  bool get _isEdit => widget.input.isEdit;
  Map<String, dynamic> get _document => widget.input.initialDocument ?? const {};

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _prefillFromDocument();
    }
    _loadDocumentTypes();
  }

  @override
  void dispose() {
    _loadToken?.cancel('DocumentFormScreen disposed');
    _submitToken?.cancel('DocumentFormScreen disposed');
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _prefillFromDocument() {
    _titleController.text = _safe(
      _document['title'],
      fallback: _safe(_document['fileName']),
    );

    final tags = _document['tags'];
    _tagsController.text = tags is List ? tags.join(', ') : _safe(tags);
    _descriptionController.text = _safe(_document['description']);
    _isVisible = _document['isVisible'] == true;

    final rawExpiry = _safe(_document['expiryAt'] ?? _document['expiryDate']);
    final parsed = DateTime.tryParse(rawExpiry);
    if (parsed == null) return;

    final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
    _selectedExpiryAt = dateOnly.toUtc().toIso8601String();
    _selectedExpiryLabel =
        '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDocumentTypes() async {
    if (!widget.permissions.canLoadDocTypes) return;

    _loadToken?.cancel('Reload document types');
    final token = CancelToken();
    _loadToken = token;

    setState(() => _loadingDocTypes = true);

    try {
      final result = await widget.repository.getDocumentTypes(cancelToken: token);
      if (!mounted) return;

      result.when(
        success: (items) {
          final existingDocTypeId = _safeInt(_document['docTypeId']);
          setState(() {
            _loadingDocTypes = false;
            _docTypesErrorShown = false;
            _docTypes = items;

            if (_isEdit && existingDocTypeId != null) {
              for (final item in items) {
                if (item.id == existingDocTypeId) {
                  _selectedDocType = item;
                  break;
                }
              }
            }

            _selectedDocType ??= items.isNotEmpty ? items.first : null;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingDocTypes = false);
          if (_docTypesErrorShown) return;
          _docTypesErrorShown = true;

          final message =
              err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403)
              ? 'Not authorized to view document types.'
              : "Couldn't load document types.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _loadDocumentTypes,
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDocTypes = false);
      if (_docTypesErrorShown) return;
      _docTypesErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load document types."),
          action: SnackBarAction(label: 'Retry', onPressed: _loadDocumentTypes),
        ),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(12),
      value: const [],
    );

    if (result == null || result.isEmpty || result.first == null) return;

    final date = result.first!;
    setState(() {
      final dateOnly = DateTime(date.year, date.month, date.day);
      _selectedExpiryAt = dateOnly.toUtc().toIso8601String();
      _selectedExpiryLabel =
          '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowMultiple: false,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'webp',
      ],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _showSnack('Unable to read selected file.');
      return;
    }

    const maxFileSize = 5 * 1024 * 1024;
    if (bytes.length > maxFileSize) {
      _showSnack('File must be 5 MB or smaller.');
      return;
    }

    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileName = file.name;
      _selectedFileSize = bytes.length;
    });
  }

  Future<void> _openDocumentTypePicker() async {
    if (_loadingDocTypes) return;

    final searchController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = _docTypes.where((item) {
              if (query.isEmpty) return true;
              return item.name.toLowerCase().contains(query) ||
                  item.docFor.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Document Type',
                      style: AppFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search document type...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: _loadingDocTypes
                          ? ListView.separated(
                              itemCount: 5,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, __) => const AppShimmer(
                                width: double.infinity,
                                height: 56,
                                radius: 12,
                              ),
                            )
                          : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No document types found',
                                style: AppFonts.roboto(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, index) {
                                final item = filtered[index];
                                final isSelected = _selectedDocType?.id == item.id;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  title: Text(
                                    item.name,
                                    style: AppFonts.roboto(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.docFor.isEmpty
                                        ? '—'
                                        : item.docFor.toUpperCase(),
                                    style: AppFonts.roboto(
                                      color: cs.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(Icons.check, color: cs.primary)
                                      : null,
                                  onTap: () {
                                    setState(() => _selectedDocType = item);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: AppFonts.roboto(
        color: cs.onSurface.withValues(alpha: 0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(w),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
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

  Future<void> _submit() async {
    if (_submitting) return;

    if (_isEdit && !widget.permissions.canUpdate) {
      _showSnack('You do not have permission to edit documents.');
      return;
    }
    if (!_isEdit && !widget.permissions.canUpload) {
      _showSnack('You do not have permission to upload documents.');
      return;
    }

    if (_selectedDocType == null) {
      _showSnack('Please select a document type.');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Please enter a title.');
      return;
    }

    final associateId = widget.input.associateId?.trim() ?? '';
    if (!_isEdit && widget.permissions.requireAssociateOnCreate && associateId.isEmpty) {
      _showSnack('Please select an associate.');
      return;
    }

    if (!_isEdit && widget.permissions.fileRequiredOnCreate) {
      if (_selectedFileBytes == null || _selectedFileName == null) {
        _showSnack('Please upload a file.');
        return;
      }
    }

    final documentId = _safe(_document['id'], fallback: '');
    if (_isEdit && documentId.isEmpty) {
      _showSnack('Document id is missing.');
      return;
    }

    _submitToken?.cancel('DocumentFormScreen submit');
    final token = CancelToken();
    _submitToken = token;

    setState(() => _submitting = true);

    try {
      final result = _isEdit
          ? await widget.repository.updateDocument(
              documentId: documentId,
              docTypeId: _selectedDocType!.id,
              title: title,
              description: _descriptionController.text.trim(),
              tags: _tagsController.text.trim(),
              expiryAt: _selectedExpiryAt,
              isVisible: widget.permissions.canSetVisibility ? _isVisible : null,
              fileBytes: _selectedFileBytes,
              filename: _selectedFileName,
              contentType: _contentTypeFor(_selectedFileName),
              cancelToken: token,
            )
          : await widget.repository.uploadDocument(
              associateType: widget.input.associateType,
              associateId: associateId,
              docTypeId: _selectedDocType!.id,
              title: title,
              fileBytes: _selectedFileBytes!,
              filename: _selectedFileName!,
              description: _descriptionController.text.trim(),
              tags: _tagsController.text.trim(),
              expiryAt: _selectedExpiryAt,
              isVisible: widget.permissions.canSetVisibility ? _isVisible : true,
              contentType: _contentTypeFor(_selectedFileName),
              cancelToken: token,
            );

      if (!mounted) return;
      if (result.isSuccess) {
        _showSnack(
          _isEdit
              ? 'Document updated successfully'
              : 'Document uploaded successfully',
        );
        Navigator.pop(context, true);
        return;
      }

      final err = result.error;
      if (err is ApiException && (err.statusCode == 401 || err.statusCode == 403)) {
        _showSnack(
          _isEdit
              ? 'Not authorized to update document.'
              : 'Not authorized to upload document.',
        );
      } else {
        _showSnack(_isEdit ? "Couldn't update document." : "Couldn't upload document.");
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(_isEdit ? "Couldn't update document." : "Couldn't upload document.");
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final labelSize = AdaptiveUtils.getTitleFontSize(w);

    final associateLabel =
        widget.input.associateName?.trim().isNotEmpty == true
        ? widget.input.associateName!.trim()
        : 'Select associate';

    final currentFileName = _safe(_document['fileName'], fallback: 'Current file');

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit Document' : 'Add Document',
                    style: AppFonts.roboto(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _isEdit ? 'Update document details' : 'Upload a new document',
                style: AppFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isEdit) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.12),
                            ),
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
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Document Type *',
                        style: AppFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openDocumentTypePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDocType?.name ?? 'Select document type',
                                  style: AppFonts.roboto(
                                    fontSize: labelSize,
                                    color: _selectedDocType == null
                                        ? cs.onSurface.withValues(alpha: 0.5)
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              _loadingDocTypes
                                  ? const AppShimmer(
                                      width: 16,
                                      height: 16,
                                      radius: 8,
                                    )
                                  : Icon(
                                      Icons.expand_more,
                                      color: cs.onSurface.withValues(alpha: 0.6),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Title *',
                        style: AppFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: AppFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _fieldDecoration(
                          context,
                          hint: 'e.g., Driving License',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Expiry Date (optional)',
                        style: AppFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickExpiryDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedExpiryLabel ?? 'Select date',
                                  style: AppFonts.roboto(
                                    fontSize: labelSize,
                                    color: _selectedExpiryLabel == null
                                        ? cs.onSurface.withValues(alpha: 0.5)
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.permissions.canSetVisibility) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'Visible To Admin',
                              style: AppFonts.roboto(
                                fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                                height: 16 / 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isVisible,
                              onChanged: (value) {
                                setState(() => _isVisible = value);
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Tags (optional)',
                        style: AppFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagsController,
                        style: AppFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _fieldDecoration(
                          context,
                          hint: 'insurance, permit',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Press Enter or comma to add tags.',
                        style: AppFonts.roboto(
                          fontSize: labelSize - 4,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description (optional)',
                        style: AppFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        style: AppFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Optional details about this document',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isEdit
                            ? 'File Selection (optional)'
                            : 'File Selection *',
                        style: AppFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName ??
                                    (_isEdit
                                        ? currentFileName
                                        : 'Click to upload'),
                                style: AppFonts.roboto(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isEdit
                                    ? 'Choose a new file only if you want to replace the current document.'
                                    : 'JPG, JPEG, PNG, PDF, DOC, DOCX, WEBP (max 5.0 MB per file)',
                                style: AppFonts.roboto(
                                  fontSize: labelSize - 4,
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              if (_selectedFileSize > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  style: AppFonts.roboto(
                                    fontSize: labelSize - 4,
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.25),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppFonts.roboto(
                                  fontSize: labelSize,
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _submitting
                                  ? const AppShimmer(
                                      width: 36,
                                      height: 14,
                                      radius: 7,
                                    )
                                  : Text(
                                      _isEdit ? 'Save' : 'Upload',
                                      style: AppFonts.roboto(
                                        fontSize: labelSize,
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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
