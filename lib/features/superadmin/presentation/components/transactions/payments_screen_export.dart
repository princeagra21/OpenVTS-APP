import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/superadmin/presentation/components/transactions/payments_screen.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';

part of 'payments_screen.dart';

extension _PaymentsScreenExport on _PaymentsScreenState {
  String _formatInrCompact(double value) {
    if (value <= 0) return '₹0';
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatDateTime(String raw) {
    if (raw.trim().isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
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
      final m = months[dt.month - 1];
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $m ${dt.year} · $h:$min';
    } catch (_) {
      return '—';
    }
  }

  String _formatCurrency(String amount, String currency) {
    if (amount.trim().isEmpty) return '—';
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : currency;
    return '$symbol${amount.trim()}';
  }

  String _titleCase(String value) {
    final v = value.trim();
    if (v.isEmpty) return '—';
    return v
        .toLowerCase()
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  (String, IconData, Color) _statusMeta(String raw, ColorScheme cs) {
    final s = raw.toLowerCase();
    if (s.contains('success')) {
      return ('SUCCESS', Icons.check_circle, cs.primary);
    }
    if (s.contains('pending') || s.contains('processing')) {
      return ('PENDING', Icons.schedule, cs.primary.withOpacity(0.7));
    }
    if (s.contains('fail') || s.contains('decline')) {
      return ('FAILED', Icons.cancel, cs.primary.withOpacity(0.5));
    }
    return ('UNKNOWN', Icons.help_outline, cs.onSurface.withOpacity(0.6));
  }

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  Future<Directory> _resolveDownloadDir() async {
    if (Platform.isAndroid) {
      final androidDir = Directory('/storage/emulated/0/Download');
      if (await androidDir.exists()) return androidDir;
    }
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.trim().isNotEmpty) {
        final dl = Directory('$home${Platform.pathSeparator}Downloads');
        if (await dl.exists()) return dl;
      }
    }
    return Directory.systemTemp;
  }

  void _showExportOptions(List<SuperadminRecentTransaction> items) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Transactions',
                  style: AppFonts.roboto(
                    fontSize:
                        AdaptiveUtils.getTitleFontSize(
                          MediaQuery.of(context).size.width,
                        ) +
                        1,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('CSV'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportCsv(items);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportPdf(items);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(List<SuperadminRecentTransaction> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    final total = items.length;
    final success = items
        .where((t) => t.status.toLowerCase().contains('success'))
        .toList();
    final revenue = success.fold<double>(
      0,
      (sum, t) => sum + _parseAmount(t.amount),
    );
    final successCount = success.length;
    final pendingCount = items
        .where(
          (t) =>
              t.status.toLowerCase().contains('pending') ||
              t.status.toLowerCase().contains('processing'),
        )
        .length;
    final failedCount = items
        .where(
          (t) =>
              t.status.toLowerCase().contains('fail') ||
              t.status.toLowerCase().contains('decline'),
        )
        .length;

    final filterLabel = _selectedRange ?? 'All Time';
    final adminLabel = _allAdminsSelected
        ? 'All Admins'
        : (_selectedAdmin?.name ?? _selectedAdmin?.id ?? 'Selected Admin');
    final generatedAt = DateTime.now();
    final generatedAtText = _formatDateTime(generatedAt.toIso8601String());

    final doc = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final labelStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final tableCellStyle = pw.TextStyle(fontSize: 7, color: PdfColors.black);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated from Open VTS Super Admin',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (_) => [
          _buildPaymentsPdfHeader(
            headerStyle: headerStyle,
            labelStyle: labelStyle,
            generatedAtText: generatedAtText,
            adminLabel: adminLabel,
            total: total,
            filterLabel: filterLabel,
          ),
          pw.SizedBox(height: 12),
          _buildPaymentsPdfSummary(
            total: total,
            revenue: _formatInrCompact(revenue),
            success: successCount,
            pending: pendingCount,
            failed: failedCount,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          pw.SizedBox(height: 12),
          _buildPaymentsPdfTable(
            items: items,
            tableHeaderStyle: tableHeaderStyle,
            tableCellStyle: tableCellStyle,
          ),
        ],
      ),
    );

    final filename =
        'payments_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final dir = await _resolveDownloadDir();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(await doc.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${file.path}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  pw.Widget _buildPaymentsPdfHeader({
    required pw.TextStyle headerStyle,
    required pw.TextStyle labelStyle,
    required String generatedAtText,
    required String adminLabel,
    required int total,
    required String filterLabel,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Payments Transaction Report', style: headerStyle),
              pw.SizedBox(height: 6),
              pw.Text('Admin Filter', style: labelStyle),
              pw.Text(
                adminLabel,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Generated On', style: labelStyle),
              pw.Text(generatedAtText, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text('Date Range', style: labelStyle),
              pw.Text(
                filterLabel,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentsPdfSummary({
    required int total,
    required String revenue,
    required int success,
    required int pending,
    required int failed,
    required pw.TextStyle labelStyle,
    required pw.TextStyle valueStyle,
  }) {
    pw.Widget card(String label, String value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: labelStyle),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: valueStyle.copyWith(color: color, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Financial Overview',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            card('Total Revenue', revenue, PdfColors.green800),
            pw.SizedBox(width: 8),
            card('Successful', success.toString(), PdfColors.blue900),
            pw.SizedBox(width: 8),
            card('Pending', pending.toString(), PdfColors.orange900),
            pw.SizedBox(width: 8),
            card('Failed', failed.toString(), PdfColors.red900),
            pw.SizedBox(width: 8),
            card('Total Txns', total.toString(), PdfColors.grey800),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentsPdfTable({
    required List<SuperadminRecentTransaction> items,
    required pw.TextStyle tableHeaderStyle,
    required pw.TextStyle tableCellStyle,
  }) {
    final headers = [
      'ID',
      'Name',
      'Amount',
      'Status',
      'Mode',
      'Type',
      'Reference',
      'Date',
    ];

    final data = items.map((t) {
      final name = t.fromUserName.isNotEmpty ? t.fromUserName : t.actorName;
      final amount = '${t.currency} ${t.amount}';
      final mode = _titleCase(t.raw['paymentMode']?.toString() ?? '—');
      final type = _titleCase(t.raw['paymentType']?.toString() ?? '—');
      final reference = t.raw['reference']?.toString() ?? '—';
      final date = _formatDateTime(t.time).replaceAll('\n', ' ');

      return [
        t.id,
        name.length > 20 ? '${name.substring(0, 17)}...' : name,
        amount,
        t.status.toUpperCase(),
        mode,
        type,
        reference.length > 15 ? '${reference.substring(0, 12)}...' : reference,
        date,
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Transaction Details',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey700,
          ),
          headerStyle: tableHeaderStyle,
          cellStyle: tableCellStyle,
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(2.0),
            7: const pw.FlexColumnWidth(2.5),
          },
        ),
      ],
    );
  }

  Future<void> _exportCsv(List<SuperadminRecentTransaction> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }
    final headers = [
      'ID',
      'Name',
      'Email',
      'Amount',
      'Currency',
      'Status',
      'Payment Mode',
      'Payment Type',
      'Reference',
      'Created At',
    ];
    final rows = <List<String>>[];
    for (final t in items) {
      rows.add([
        t.id,
        t.fromUserName.isNotEmpty ? t.fromUserName : t.actorName,
        t.fromUserEmail,
        t.amount,
        t.currency,
        t.status,
        t.raw['paymentMode']?.toString() ?? '',
        t.raw['paymentType']?.toString() ?? '',
        t.raw['reference']?.toString() ?? '',
        t.time,
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'payments_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final dir = await _resolveDownloadDir();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${file.path}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
