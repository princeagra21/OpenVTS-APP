import 'dart:typed_data';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_document_type.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDocumentScreen extends StatefulWidget {
  final String? associateId;
  final String associateType;
  final String? associateName;

  const AddDocumentScreen({
    super.key,
    this.associateId,
    this.associateType = 'USER',
    this.associateName,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _docTypeSearchController = TextEditingController();

  ApiClient? _api;
  AdminUsersRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _submitToken;

  bool _loadingDocTypes = false;
  bool _uploading = false;
  bool _docTypesErrorShown = false;
  List<SuperadminDocumentType> _docTypes = const [];
  SuperadminDocumentType? _selectedDocType;

  String? _selectedExpiryAt;
  String? _selectedExpiryLabel;
  bool _isVisible = true;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int _selectedFileSize = 0;

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  @override
  void dispose() {
    _loadToken?.cancel('AddDocumentScreen disposed');
    _submitToken?.cancel('AddDocumentScreen disposed');
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _docTypeSearchController.dispose();
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = AdminUsersRepository(api: _api!);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadDocumentTypes() async {
    _ensureRepo();
    _loadToken?.cancel('reload doc types');
    _loadToken = CancelToken();

    if (!mounted) return;
    setState(() => _loadingDocTypes = true);

    try {
      final res = await _repo!.getDocumentTypes(cancelToken: _loadToken);
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _loadingDocTypes = false;
            _docTypesErrorShown = false;
            _docTypes = items;
            _selectedDocType ??= items.isNotEmpty ? items.first : null;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingDocTypes = false);
          if (_docTypesErrorShown) return;
          _docTypesErrorShown = true;
          final msg = err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403)
              ? 'Not authorized to view document types.'
              : "Couldn't load document types.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(label: 'Retry', onPressed: _loadDocumentTypes),
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

    if (result != null && result.isNotEmpty && result.first != null) {
      final date = result.first!;
      setState(() {
        _selectedExpiryAt = DateTime(
          date.year,
          date.month,
          date.day,
        ).toUtc().toIso8601String();
        _selectedExpiryLabel =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
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
      _snack('Unable to read selected file.');
      return;
    }
    const maxSize = 5 * 1024 * 1024;
    if (bytes.length > maxSize) {
      _snack('File must be 5 MB or smaller.');
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
            final filtered = _docTypes.where((d) {
              if (query.isEmpty) return true;
              return d.name.toLowerCase().contains(query) ||
                  d.docFor.toLowerCase().contains(query);
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
                        color: cs.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Document Type',
                      style: GoogleFonts.roboto(
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
                                    style: GoogleFonts.roboto(
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, i) {
                                    final item = filtered[i];
                                    final isSelected = _selectedDocType?.id == item.id;
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      title: Text(
                                        item.name,
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        item.docFor.isEmpty
                                            ? '—'
                                            : item.docFor.toUpperCase(),
                                        style: GoogleFonts.roboto(
                                          color: cs.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              Icons.check,
                                              color: cs.primary,
                                            )
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
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        color: cs.onSurface.withOpacity(0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  Future<void> _upload() async {
    if (_uploading) return;
    final title = _titleController.text.trim();
    if (_selectedDocType == null) {
      _snack('Please select a document type.');
      return;
    }
    if (widget.associateId == null || widget.associateId!.trim().isEmpty) {
      _snack('Please select an associate.');
      return;
    }
    if (title.isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    if (_selectedFileBytes == null || _selectedFileName == null) {
      _snack('Please upload a file.');
      return;
    }

    _ensureRepo();
    _submitToken?.cancel('AddDocumentScreen submit');
    _submitToken = CancelToken();
    setState(() => _uploading = true);

    try {
      final res = await _repo!.uploadDocument(
        associateType: widget.associateType,
        associateId: widget.associateId!,
        docTypeId: _selectedDocType!.id,
        title: title,
        fileBytes: _selectedFileBytes!,
        filename: _selectedFileName!,
        description: _descriptionController.text.trim(),
        tags: _tagsController.text.trim(),
        expiryAt: _selectedExpiryAt,
        isVisible: _isVisible,
        cancelToken: _submitToken,
      );

      if (!mounted) return;
      if (res.isSuccess) {
        _snack('Document uploaded successfully');
        Navigator.pop(context, true);
        return;
      }

      final err = res.error;
      if (err is ApiException &&
          (err.statusCode == 401 || err.statusCode == 403)) {
        _snack('Not authorized to upload document.');
      } else {
        _snack("Couldn't upload document.");
      }
    } catch (_) {
      if (!mounted) return;
      _snack("Couldn't upload document.");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final associateLabel = widget.associateName?.trim().isNotEmpty == true
        ? widget.associateName!.trim()
        : 'Select associate';

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Document',
                    style: GoogleFonts.roboto(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Upload a new document',
                style: GoogleFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.87),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          associateLabel,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.roboto(
                            fontSize: labelSize,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Document Type *',
                        style: GoogleFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
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
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDocType?.name ?? 'Select document type',
                                  style: GoogleFonts.roboto(
                                    fontSize: labelSize,
                                    color: _selectedDocType == null
                                        ? cs.onSurface.withOpacity(0.5)
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
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Title *',
                        style: GoogleFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.roboto(
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
                        style: GoogleFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
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
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedExpiryLabel ?? 'Select date',
                                  style: GoogleFonts.roboto(
                                    fontSize: labelSize,
                                    color: _selectedExpiryLabel == null
                                        ? cs.onSurface.withOpacity(0.5)
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_month_outlined,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Visible To Admin',
                            style: GoogleFonts.roboto(
                              fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Switch.adaptive(
                            value: _isVisible,
                            onChanged: (value) => setState(() {
                              _isVisible = value;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tags (optional)',
                        style: GoogleFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagsController,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Type and press Enter…',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Press Enter or comma to add tags.',
                        style: GoogleFonts.roboto(
                          fontSize: labelSize - 4,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description (optional)',
                        style: GoogleFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Additional description…',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'File Selection *',
                        style: GoogleFonts.roboto(
                          fontSize: 12 * (w / 420).clamp(0.9, 1.0),
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                            color: cs.surface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName ?? 'Click to upload',
                                style: GoogleFonts.roboto(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedFileName == null
                                      ? cs.onSurface.withOpacity(0.6)
                                      : cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'JPG, JPEG, PNG, PDF, DOC, DOCX, WEBP (max 5.0 MB per file)',
                                style: GoogleFonts.roboto(
                                  fontSize: labelSize - 4,
                                  color: cs.onSurface.withOpacity(0.55),
                                ),
                              ),
                              if (_selectedFileName != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFileSize > 0
                                      ? '${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB'
                                      : '',
                                  style: GoogleFonts.roboto(
                                    fontSize: labelSize - 4,
                                    color: cs.onSurface.withOpacity(0.55),
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
                            child: GestureDetector(
                              onTap: _uploading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.roboto(
                                      fontSize: labelSize,
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _uploading ? null : _upload,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: _uploading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              cs.onPrimary,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Upload',
                                          style: GoogleFonts.roboto(
                                            fontSize: labelSize,
                                            color: cs.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
