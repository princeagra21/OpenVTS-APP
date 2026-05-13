part of 'transaction.dart';

extension _TransactionScreenExport on _TransactionScreenState {
  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  Future<void> _exportCsv(List<AdminTransactionItem> items) async {
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
      final name = _transactionName(t);
      final email = _transactionEmail(t);
      rows.add([
        t.id,
        name,
        email,
        (t.amount ?? 0).toString(),
        t.currency,
        t.statusLabel,
        t.raw['paymentMode']?.toString() ?? '',
        t.raw['paymentType']?.toString() ?? '',
        t.raw['reference']?.toString() ?? '',
        t.createdAt,
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported CSV: ${file.path}')));
  }

  void _showExportOptions(List<AdminTransactionItem> items) {
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

  Future<void> _exportPdf(List<AdminTransactionItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    final total = items.length;
    final successCount = items
        .where((t) => t.statusLabel.toLowerCase().contains('success'))
        .length;
    final pendingCount = items
        .where(
          (t) =>
              t.statusLabel.toLowerCase().contains('pending') ||
              t.statusLabel.toLowerCase().contains('processing'),
        )
        .length;
    final failedCount = items
        .where(
          (t) =>
              t.statusLabel.toLowerCase().contains('fail') ||
              t.statusLabel.toLowerCase().contains('decline'),
        )
        .length;
    final generatedAtText = _formatDateTime(
      DateTime.now().toIso8601String(),
    ).replaceAll('\n', ' ');

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
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final tableCellStyle = pw.TextStyle(fontSize: 8, color: PdfColors.black);

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
                'Generated from Open VTS User',
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
          pw.Container(
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
                    pw.Text('Transactions Report', style: headerStyle),
                    pw.SizedBox(height: 6),
                    pw.Text('Status Filter', style: labelStyle),
                    pw.Text(_statusFilter, style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated', style: labelStyle),
                    pw.Text(generatedAtText, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 6),
                    pw.Text('Total Records', style: labelStyle),
                    pw.Text('$total', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _pdfSummaryCard(
                'Total',
                '$total',
                PdfColors.blue900,
                labelStyle,
                valueStyle,
              ),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                'Success',
                '$successCount',
                PdfColors.green800,
                labelStyle,
                valueStyle,
              ),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                'Pending',
                '$pendingCount',
                PdfColors.orange800,
                labelStyle,
                valueStyle,
              ),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                'Failed',
                '$failedCount',
                PdfColors.red800,
                labelStyle,
                valueStyle,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _pdfTransactionsTable(items, tableHeaderStyle, tableCellStyle),
        ],
      ),
    );

    final filename =
        'user_transactions_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  pw.Widget _pdfSummaryCard(
    String label,
    String value,
    PdfColor color,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: labelStyle),
            pw.SizedBox(height: 6),
            pw.Text(value, style: valueStyle.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfTransactionsTable(
    List<AdminTransactionItem> items,
    pw.TextStyle tableHeaderStyle,
    pw.TextStyle tableCellStyle,
  ) {
    final headers = ['Date', 'Name', 'Amount', 'Status', 'Mode', 'Reference'];

    final data = items.map((t) {
      final date = _formatDateTime(t.createdAt).replaceAll('\n', ' ');
      final name = _transactionName(t);
      final amount = _formatAmount(t.amount, t.currency);
      final status = t.statusLabel;
      final mode = _titleCase(t.raw['paymentMode']?.toString() ?? '—');
      final reference = t.raw['reference']?.toString() ?? t.reference;
      return [date, name, amount, status, mode, reference];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      headerStyle: tableHeaderStyle,
      cellStyle: tableCellStyle,
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.7),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(2.4),
      },
    );
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
}
