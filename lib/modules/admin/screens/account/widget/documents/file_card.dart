import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/documents/edit_document.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FileCard extends StatelessWidget {
  final Map<String, dynamic>? document;
  final String? fileName;
  final String? version;
  final String? fileSize;
  final String? type;
  final List<String>? tags;
  final String? uploadedDate;
  final String? expiryDate;
  final String? status;
  final Future<void> Function()? onChanged;

  const FileCard({
    super.key,
    this.document,
    this.fileName,
    this.version,
    this.fileSize,
    this.type,
    this.tags,
    this.uploadedDate,
    this.expiryDate,
    this.status,
    this.onChanged,
  });

  String _safe(Object? value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw.trim());
    if (dt == null) return _safe(raw);
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year $hour:$minute';
  }

  String _displayFileType(String fileType, String fallbackName) {
    final t = fileType.trim().toLowerCase();
    if (t.isNotEmpty && t != '-') return t;
    final lower = fallbackName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'document';
    return 'file';
  }

  IconData _documentIcon(String fileType, String fallbackName) {
    final key = '${fileType.toLowerCase()} ${fallbackName.toLowerCase()}';
    if (key.contains('pdf')) return CupertinoIcons.doc_fill;
    if (key.contains('image') ||
        key.contains('jpg') ||
        key.contains('jpeg') ||
        key.contains('png') ||
        key.contains('webp')) {
      return CupertinoIcons.photo_fill_on_rectangle_fill;
    }
    if (key.contains('csv') ||
        key.contains('xls') ||
        key.contains('xlsx') ||
        key.contains('sheet')) {
      return Icons.table_chart_rounded;
    }
    if (key.contains('doc')) return CupertinoIcons.doc_text_fill;
    return CupertinoIcons.doc_fill;
  }

  Map<String, dynamic> _legacyMap() {
    return <String, dynamic>{
      'fileName': fileName,
      'fileType': type,
      'title': fileName,
      'description': '',
      'tags': tags ?? const <String>[],
      'createdAt': uploadedDate,
      'expiryAt': expiryDate,
      'isVisible': status?.toLowerCase().contains('valid') ?? true,
      'filePath': '',
      'associateType': '',
      'associateUserId': '',
      'associateDriverId': '',
      'associateVehicleId': '',
      'uploadedByType': '',
      'uploadedByUserId': '',
      'uploadedByDriverId': '',
    };
  }

  Future<void> _openDocument(
    BuildContext context,
    Map<String, dynamic> doc,
  ) async {
    final filePath = _safe(
      doc['filePath'] ?? doc['fileUrl'] ?? doc['url'] ?? doc['path'],
      fallback: '',
    );
    if (filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document file path is missing.')),
      );
      return;
    }

    final baseUrl = AppConfig.fromDartDefine().baseUrl.trim();
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      final uri = Uri.tryParse(filePath);
      if (uri != null) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open document.')),
          );
        }
        return;
      }
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = filePath.startsWith('/') ? filePath : '/$filePath';
    final uri = Uri.tryParse('$normalizedBase$normalizedPath');
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid document URL.')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open document.')));
    }
  }

  Future<void> _editDocument(
    BuildContext context,
    Map<String, dynamic> doc,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditDocumentScreen(document: doc)),
    );
    if (updated == true) {
      await onChanged?.call();
    }
  }

  Future<void> _deleteDocument(
    BuildContext context,
    Map<String, dynamic> doc,
  ) async {
    final id = _safe(doc['id'], fallback: '');
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document id is missing.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Delete document?'),
          content: const Text('This document will be removed permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final repo = AdminUsersRepository(
      api: ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      ),
    );
    final res = await repo.deleteDocumentFile(id);
    if (!context.mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted successfully')),
      );
      await onChanged?.call();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Couldn't delete document.")));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final cardPadding = AdaptiveUtils.getHorizontalPadding(width) + 4;
    final fsMain = 14 * scale;
    final fsMeta = 11 * scale;
    final iconSize = 16 * scale;

    final doc = document ?? _legacyMap();
    final displayName = _safe(doc['fileName'], fallback: 'Untitled document');
    final displayType = _displayFileType(_safe(doc['fileType']), displayName);
    final createdAt = _formatDateTime(_safe(doc['createdAt']));
    final expiryAt = _formatDateTime(_safe(doc['expiryAt']));
    final title = _safe(doc['title'], fallback: displayName);
    final isVisible = doc['isVisible'] == true;
    final statusColor = isVisible ? Colors.green : cs.onSurfaceVariant;
    final uploadedByType = _safe(doc['uploadedByType']);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: AdaptiveUtils.getHorizontalPadding(width),
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? cs.surfaceVariant
                        : Colors.grey.shade50,
                    border: Border.all(color: cs.outline.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _documentIcon(displayType, displayName),
                    size: 18 * scale,
                    color: cs.primary,
                  ),
                ),
                SizedBox(width: spacing * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.roboto(
                          fontSize: fsMain,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        softWrap: true,
                      ),
                      SizedBox(height: spacing * 0.4),
                      Text(
                        '$displayType · $createdAt',
                        style: GoogleFonts.roboto(
                          fontSize: fsMeta,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing + 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? statusColor.withOpacity(0.15)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: fsMeta + 2,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? statusColor
                            : cs.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVisible ? 'Visible' : 'Hidden',
                        style: GoogleFonts.roboto(
                          fontSize: fsMeta,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? statusColor
                              : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editDocument(context, doc);
                    } else if (value == 'delete') {
                      _deleteDocument(context, doc);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: spacing),
            _detailRow(
              context,
              spacing: spacing,
              iconSize: iconSize,
              fsMeta: fsMeta,
              fsMain: fsMain,
              leftIcon: Icons.cloud_upload_outlined,
              leftLabel: 'Uploaded By',
              leftValue: uploadedByType,
              rightIcon: Icons.schedule_outlined,
              rightLabel: 'Expiry',
              rightValue: expiryAt,
            ),
            SizedBox(height: spacing),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: spacing * 1.2,
                vertical: spacing - 2,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: iconSize,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Title',
                        style: GoogleFonts.roboto(
                          fontSize: fsMeta,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: fsMain,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDocument(context, doc),
                icon: const Icon(Icons.description_rounded, size: 18),
                label: const Text('Open Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required double spacing,
    required double iconSize,
    required double fsMeta,
    required double fsMain,
    required IconData leftIcon,
    required String leftLabel,
    required String leftValue,
    required IconData rightIcon,
    required String rightLabel,
    required String rightValue,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _detailBox(
              context,
              spacing: spacing,
              iconSize: iconSize,
              fsMeta: fsMeta,
              fsMain: fsMain,
              icon: leftIcon,
              label: leftLabel,
              value: leftValue,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _detailBox(
              context,
              spacing: spacing,
              iconSize: iconSize,
              fsMeta: fsMeta,
              fsMain: fsMain,
              icon: rightIcon,
              label: rightLabel,
              value: rightValue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(
    BuildContext context, {
    required double spacing,
    required double iconSize,
    required double fsMeta,
    required double fsMain,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing * 1.2,
        vertical: spacing - 2,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: iconSize, color: cs.onSurface.withOpacity(0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: fsMeta,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: fsMeta + 1,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            maxLines: 2,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
