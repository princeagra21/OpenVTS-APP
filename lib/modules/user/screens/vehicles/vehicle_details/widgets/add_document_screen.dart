import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';

class UserVehicleAddDocumentScreen extends StatefulWidget {
  const UserVehicleAddDocumentScreen({
    super.key,
    required this.docTypes,
    required this.vehicleLabel,
    required this.loadingDocTypes,
    required this.onReloadTypes,
    required this.onSubmit,
  });

  final List<SuperadminDocumentType> docTypes;
  final String vehicleLabel;
  final bool loadingDocTypes;
  final Future<void> Function() onReloadTypes;
  final Future<String?> Function({
    required String title,
    required int docTypeId,
    required PlatformFile file,
    required String tags,
    required String description,
    required String? expiryAt,
    required bool isVisible,
  })
  onSubmit;

  @override
  State<UserVehicleAddDocumentScreen> createState() =>
      _UserVehicleAddDocumentScreenState();
}

class _UserVehicleAddDocumentScreenState
    extends State<UserVehicleAddDocumentScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isVisible = true;
  bool _uploading = false;
  SuperadminDocumentType? _selectedDocType;
  String? _selectedExpiryAt;
  String? _selectedExpiryLabel;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _selectedDocType = widget.docTypes.isNotEmpty
        ? widget.docTypes.first
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
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

    if (result == null || result.isEmpty || result.first == null) {
      return;
    }

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

    const maxSizeBytes = 5 * 1024 * 1024;
    if (bytes.length > maxSizeBytes) {
      _snack('File must be 5 MB or smaller.');
      return;
    }

    setState(() => _selectedFile = file);
  }

  Future<void> _openDocumentTypePicker() async {
    final searchController = TextEditingController();
    await OpenVtsModal.showBottomSheet<void>(
      context: context,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return StatefulBuilder(
            builder: (context, setModalState) {
              final query = searchController.text.trim().toLowerCase();
              final filtered = widget.docTypes.where((docType) {
                if (query.isEmpty) return true;
                return docType.name.toLowerCase().contains(query) ||
                    docType.docFor.toLowerCase().contains(query);
              }).toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Document Type',
                      style: AppFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No document types found',
                                style: AppFonts.roboto(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, index) {
                                final item = filtered[index];
                                final selected =
                                    _selectedDocType?.id == item.id;
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
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check,
                                          color: colorScheme.primary,
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
              );
            },
          );
        },
      ),
    );
    searchController.dispose();
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: AppFonts.roboto(
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(
          MediaQuery.of(context).size.width,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
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
    if (title.isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    if (_selectedFile == null) {
      _snack('Please upload a file.');
      return;
    }

    setState(() => _uploading = true);
    final error = await widget.onSubmit(
      title: title,
      docTypeId: _selectedDocType!.id,
      file: _selectedFile!,
      tags: _tagsController.text.trim(),
      description: _descriptionController.text.trim(),
      expiryAt: _selectedExpiryAt,
      isVisible: _isVisible,
    );

    if (!mounted) return;
    setState(() => _uploading = false);
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }

    _snack(error);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width);
    final labelSize = AdaptiveUtils.getTitleFontSize(width);

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                    style: AppFonts.roboto(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Upload a new document',
                style: AppFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
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
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.vehicleLabel,
                          style: AppFonts.roboto(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(context, 'Document Type *', width),
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDocType?.name ??
                                      'Select document type',
                                  style: AppFonts.roboto(
                                    fontSize: labelSize,
                                    color: _selectedDocType == null
                                        ? colorScheme.onSurface.withValues(
                                            alpha: 0.5,
                                          )
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              widget.loadingDocTypes
                                  ? const AppShimmer(
                                      width: 16,
                                      height: 16,
                                      radius: 8,
                                    )
                                  : Icon(
                                      Icons.expand_more,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(context, 'Title *', width),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: _fieldDecoration(
                          context,
                          hint: 'e.g., Registration Certificate',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(context, 'Expiry Date (optional)', width),
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
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
                                        ? colorScheme.onSurface.withValues(
                                            alpha: 0.5,
                                          )
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_month_outlined,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionLabel(context, 'Visible To Admin', width),
                          Switch.adaptive(
                            value: _isVisible,
                            onChanged: (value) =>
                                setState(() => _isVisible = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(context, 'Tags (optional)', width),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagsController,
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Type and press Enter…',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(context, 'Description (optional)', width),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: _fieldDecoration(
                          context,
                          hint: 'Additional description…',
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(context, 'File Selection *', width),
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                            ),
                            color: colorScheme.surface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile?.name ?? 'Click to upload',
                                style: AppFonts.roboto(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedFile == null
                                      ? colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        )
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'JPG, JPEG, PNG, PDF, DOC, DOCX, WEBP (max 5.0 MB per file)',
                                style: AppFonts.roboto(
                                  fontSize: labelSize - 4,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
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
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: AppFonts.roboto(
                                      fontSize: labelSize,
                                      color: colorScheme.onSurface,
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
                                  color: colorScheme.primary,
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
                                                  colorScheme.onPrimary,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Upload',
                                          style: AppFonts.roboto(
                                            fontSize: labelSize,
                                            color: colorScheme.onPrimary,
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

  Widget _sectionLabel(BuildContext context, String label, double width) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: AppFonts.roboto(
        fontSize: 12 * (width / 420).clamp(0.9, 1.0),
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}
