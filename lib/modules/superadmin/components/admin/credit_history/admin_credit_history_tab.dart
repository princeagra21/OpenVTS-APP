import 'dart:io';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/credit_log_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/add_deduct_credit_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminCreditHistoryTab extends StatefulWidget {
  final String adminId;

  const AdminCreditHistoryTab({super.key, required this.adminId});

  @override
  State<AdminCreditHistoryTab> createState() => _AdminCreditHistoryTabState();
}

class _AdminCreditHistoryTabState extends State<AdminCreditHistoryTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  CancelToken? _profileToken;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _totalAssigned = 0;
  int _totalDeducted = 0;
  int _currentCredits = 0;
  int _entryCount = 0;
  DateTime? _lastActivity;
  List<CreditLogItem> _logs = const [];

  ApiClient? _api;
  SuperadminRepository? _repo;
  String? _companyName;
  String? _adminName;
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadCompanyName();
    _searchController.addListener(() {
      final next = _searchController.text;
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
  }

  @override
  void dispose() {
    _token?.cancel('AdminCreditHistoryTab disposed');
    _profileToken?.cancel('AdminCreditHistoryTab disposed');
    _searchController.dispose();
    super.dispose();
  }

  void _showDateRangePicker() async {
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: [_startDate, _endDate],
    );

    if (values != null && values.length == 2) {
      setState(() {
        _startDate = values[0];
        _endDate = values[1];
      });
    }
  }

  Future<void> _loadLogs({bool showShimmer = true}) async {
    _token?.cancel('Reload credit logs');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    if (showShimmer) {
      setState(() => _loading = true);
    }

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getCreditLogs(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          if (!mounted) return;
          final totals = _computeTotals(items);
          final companyName = _extractCompanyName(items);
          setState(() {
            _loading = false;
            _totalAssigned = totals.totalAssigned;
            _totalDeducted = totals.totalDeducted;
            _currentCredits = totals.currentCredits;
            _entryCount = totals.entryCount;
            _lastActivity = totals.lastActivity;
            _companyName = companyName ?? _companyName;
            _logs = items;
          });
          if (_companyName == null || _companyName!.trim().isEmpty) {
            _loadCompanyName();
          }
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to view credit history.'
                  : "Couldn't load credit history.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(label: 'Retry', onPressed: _loadLogs),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load credit history."),
          action: SnackBarAction(label: 'Retry', onPressed: _loadLogs),
        ),
      );
    }
  }

  Future<void> _loadCompanyName() async {
    _profileToken?.cancel('Reload admin profile');
    final token = CancelToken();
    _profileToken = token;
    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdminProfile(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (profile) {
          final name = profile.companyName.trim();
          final adminName = profile.fullName.trim();
          final adminEmail = profile.email.trim();
          setState(() {
            if (name.isNotEmpty) _companyName = name;
            if (adminName.isNotEmpty) _adminName = adminName;
            if (adminEmail.isNotEmpty) _adminEmail = adminEmail;
          });
        },
        failure: (_) {},
      );
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(
        width: double.infinity,
        height: 360,
        radius: 12,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double descFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 4;
    final double scale = fontSize / 14;
    final double headerSize = 18 * scale;

    final lastActivityDate = _lastActivity == null
        ? '—'
        : _formatDate(_lastActivity!);
    final lastActivityMeta = _lastActivity == null
        ? '—'
        : '${_formatTime(_lastActivity!)} · $_entryCount entries';

    final statementId = _statementId(widget.adminId, _lastActivity);
    final billToName = _billToName();
    final billToUser = _billToUserName();
    final billToEmail = _billToEmail();
    final generatedAt = _statementGeneratedAt();
    final generatedAtText =
        '${_formatDate(generatedAt)}, ${_formatTime(generatedAt)}';
    final filteredLogs = _filteredLogs();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: GoogleFonts.roboto(
                      fontSize: headerSize,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showDateRangePicker,
                    child: Row(
                      children: [
                        Text(
                          _startDate == null || _endDate == null
                              ? "Select Date Range"
                              : "${_startDate!.toIso8601String().substring(0, 10)} - ${_endDate!.toIso8601String().substring(0, 10)}",
                          style: GoogleFonts.roboto(
                            fontSize: descFontSize,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showExportOptions();
                  },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: colorScheme.onSurface.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                      label: Text(
                        "Download",
                        style: GoogleFonts.roboto(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddDeductCreditScreen(
                              adminId: widget.adminId,
                              initialAction: 'add',
                              lockAction: true,
                            ),
                          ),
                        );
                        if (updated == true) {
                          _loadLogs(showShimmer: false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Assign",
                        style: GoogleFonts.roboto(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddDeductCreditScreen(
                              adminId: widget.adminId,
                              initialAction: 'deduct',
                              lockAction: true,
                            ),
                          ),
                        );
                        if (updated == true) {
                          _loadLogs(showShimmer: false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: colorScheme.onSurface.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.remove,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                      label: Text(
                        "Deduct",
                        style: GoogleFonts.roboto(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'CREDITS',
                style: GoogleFonts.roboto(
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Credit History',
                style: GoogleFonts.roboto(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const AppShimmer(width: double.infinity, height: 120, radius: 12)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 12.0;
                    final cardWidth = (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _metricCard(
                          context,
                          width: cardWidth,
                          label: 'Current Credits',
                          value: _currentCredits.toString(),
                        ),
                        _metricCard(
                          context,
                          width: cardWidth,
                          label: 'Total Assigned',
                          value: _totalAssigned.toString(),
                        ),
                        _metricCard(
                          context,
                          width: cardWidth,
                          label: 'Total Deducted',
                          value: _totalDeducted.toString(),
                        ),
                        _metricCard(
                          context,
                          width: cardWidth,
                          label: 'Last Activity',
                          value: lastActivityDate,
                          subValue: lastActivityMeta,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRANSACTIONS',
                style: GoogleFonts.roboto(
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Credit Logs',
                style: GoogleFonts.roboto(
                  fontSize: fontSize + 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search history...',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: descFontSize,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATEMENT #',
                      style: GoogleFonts.roboto(
                        fontSize: fontSize - 2,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statementId,
                      style: GoogleFonts.roboto(
                        fontSize: fontSize + 1,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'BILL TO',
                      style: GoogleFonts.roboto(
                        fontSize: fontSize - 2,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      billToName,
                      style: GoogleFonts.roboto(
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      billToUser,
                      style: GoogleFonts.roboto(
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      billToEmail,
                      style: GoogleFonts.roboto(
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(
                      'STATEMENT DETAILS',
                      style: GoogleFonts.roboto(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                          const SizedBox(height: 8),
                          _detailRow(
                            context,
                            label: 'Generated',
                            value: generatedAtText,
                          ),
                          const SizedBox(height: 6),
                          _detailRow(
                            context,
                            label: 'Current Balance',
                            value: _currentCredits.toString(),
                          ),
                          const SizedBox(height: 6),
                          _detailRow(
                            context,
                            label: 'Entries',
                            value: _entryCount.toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const AppShimmer(width: double.infinity, height: 120, radius: 12)
              else if (filteredLogs.isEmpty)
                Text(
                  'No credit logs found.',
                  style: GoogleFonts.roboto(
                    fontSize: descFontSize,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              else
                Column(
                  children: filteredLogs
                      .map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _logCard(context, log),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportOptions() {
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
                  'Download Statement',
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(
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
                    await _exportCsv();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportPdf();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  Future<void> _exportCsv() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credit logs to export.')),
      );
      return;
    }
    final headers = [
      'Date & Time',
      'Description',
      '+/-',
      'Balance',
      'Action',
    ];
    final rows = <List<String>>[];
    final sorted = [..._logs];
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    int running = 0;
    for (final log in sorted) {
      final dt = DateTime.tryParse(log.createdAt)?.toLocal();
      final dateText = dt == null
          ? '—'
          : '${_formatDate(dt)}, ${_formatTimeWithSeconds(dt)}';
      final amount = log.isCredit ? log.amount.abs() : -log.amount.abs();
      running += amount;
      rows.add([
        dateText,
        _logDescription(log),
        amount > 0 ? '+${amount.abs()}' : '-${amount.abs()}',
        running.toString(),
        _exportActionLabel(log),
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename = _exportFilename('csv');
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

  Future<void> _exportPdf() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credit logs to export.')),
      );
      return;
    }

    final statementId = _statementId(widget.adminId, _lastActivity);
    final generatedAt = _statementGeneratedAt();
    final generatedAtText = '${_formatDate(generatedAt)} ${_formatTime(generatedAt)}';

    final sorted = [..._logs];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

    final doc = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final labelStyle = pw.TextStyle(
      fontSize: 9,
      color: PdfColors.grey700,
    );
    final valueStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final tableCellStyle = pw.TextStyle(fontSize: 9, color: PdfColors.black);

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
                'Generated from Open VTS Admin',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) {
          return [
            _buildPdfHeader(
              statementId: statementId,
              generatedAtText: generatedAtText,
              headerStyle: headerStyle,
              labelStyle: labelStyle,
            ),
            pw.SizedBox(height: 16),
            _buildPdfSummarySection(
              currentCredits: _currentCredits,
              totalAssigned: _totalAssigned,
              totalDeducted: _totalDeducted,
              entryCount: _entryCount,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            pw.SizedBox(height: 16),
            _buildPdfAccountSection(
              company: _billToName(),
              admin: _billToUserName(),
              email: _billToEmail(),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
            pw.SizedBox(height: 16),
            _buildPdfTransactionTable(
              logs: sorted,
              tableHeaderStyle: tableHeaderStyle,
              tableCellStyle: tableCellStyle,
            ),
          ];
        },
      ),
    );

    final filename = _exportFilename('pdf');
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

  pw.Widget _buildPdfHeader({
    required String statementId,
    required String generatedAtText,
    required pw.TextStyle headerStyle,
    required pw.TextStyle labelStyle,
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
              pw.Text('Credit History Statement', style: headerStyle),
              pw.SizedBox(height: 6),
              pw.Text('Statement ID', style: labelStyle),
              pw.Text(statementId, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Generated', style: labelStyle),
              pw.Text(generatedAtText, style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummarySection({
    required int currentCredits,
    required int totalAssigned,
    required int totalDeducted,
    required int entryCount,
    required pw.TextStyle labelStyle,
    required pw.TextStyle valueStyle,
  }) {
    pw.Widget card(String label, String value, PdfColor color) {
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            card('Current Credits', currentCredits.toString(), PdfColors.blue900),
            pw.SizedBox(width: 8),
            card('Total Assigned', totalAssigned.toString(), PdfColors.green800),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            card('Total Deducted', totalDeducted.toString(), PdfColors.red800),
            pw.SizedBox(width: 8),
            card('Total Entries', entryCount.toString(), PdfColors.grey800),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfAccountSection({
    required String company,
    required String admin,
    required String email,
    required pw.TextStyle labelStyle,
    required pw.TextStyle valueStyle,
  }) {
    pw.Widget row(String label, String value) {
      return pw.Row(
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: labelStyle)),
          pw.Expanded(child: pw.Text(value, style: valueStyle.copyWith(fontSize: 10))),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Account Information', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          row('Company', company.isEmpty ? '—' : company),
          pw.SizedBox(height: 4),
          row('Admin', admin.isEmpty ? '—' : admin),
          pw.SizedBox(height: 4),
          row('Email', email.isEmpty ? '—' : email),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTransactionTable({
    required List<CreditLogItem> logs,
    required pw.TextStyle tableHeaderStyle,
    required pw.TextStyle tableCellStyle,
  }) {
    final headers = ['Date', 'Description', 'Amount', 'Balance', 'Action'];
    final asc = [...logs]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    int running = 0;
    final rows = <Map<String, dynamic>>[];
    for (final log in asc) {
      final delta = log.isCredit ? log.amount.abs() : -log.amount.abs();
      running += delta;
      final balance = log.balanceAfter != 0 ? log.balanceAfter : running;
      rows.add({
        'log': log,
        'balance': balance,
      });
    }

    final desc = rows.reversed.toList();
    final data = desc.map((row) {
      final log = row['log'] as CreditLogItem;
      final balance = row['balance'] as int;
      final dt = DateTime.tryParse(log.createdAt)?.toLocal();
      final dateText =
          dt == null ? '—' : '${_formatDate(dt)} ${_formatTime(dt)}';
      final amount = log.isCredit ? '+${log.amount.abs()}' : '-${log.amount.abs()}';
      return [
        dateText,
        _logDescription(log),
        amount,
        balance.toString(),
        _exportActionLabel(log),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Transactions', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          headerStyle: tableHeaderStyle,
          cellStyle: tableCellStyle,
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3.5),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.2),
          },
          cellAlignments: {
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  String _exportFilename(String ext) {
    final date = (_lastActivity ?? DateTime.now()).toLocal();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');
    return 'credit-history-admin-${widget.adminId}-$y-$m-$d-$hh$mm$ss.$ext';
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
        final dl = Directory(
          '$home${Platform.pathSeparator}Downloads',
        );
        if (await dl.exists()) return dl;
      }
    }
    return Directory.systemTemp;
  }

  _Totals _computeTotals(List<CreditLogItem> items) {
    int assigned = 0;
    int deducted = 0;
    DateTime? last;
    for (final it in items) {
      if (it.isCredit) {
        assigned += it.amount.abs();
      } else {
        deducted += it.amount.abs();
      }
      final dt = DateTime.tryParse(it.createdAt);
      if (dt != null) {
        if (last == null || dt.isAfter(last)) last = dt;
      }
    }
    final current = assigned - deducted;
    return _Totals(
      totalAssigned: assigned,
      totalDeducted: deducted,
      currentCredits: current,
      entryCount: items.length,
      lastActivity: last?.toLocal(),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.month}/${d.day}/${d.year}';
  }

  String _formatTime(DateTime dt) {
    final t = dt.toLocal();
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final amPm = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  String _formatTimeWithSeconds(DateTime dt) {
    final t = dt.toLocal();
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final second = t.second.toString().padLeft(2, '0');
    final amPm = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $amPm';
  }

  List<CreditLogItem> _filteredLogs() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _logs;
    return _logs.where((log) {
      final id = log.id.toLowerCase();
      final type = log.type.toLowerCase();
      final created = log.createdAt.toLowerCase();
      final vehicleId = (log.raw['vehicleId'] ?? log.raw['vehicle_id'])
          ?.toString()
          .toLowerCase();
      final amount = log.amount.toString();
      final desc = _logDescription(log).toLowerCase();
      return id.contains(query) ||
          type.contains(query) ||
          created.contains(query) ||
          amount.contains(query) ||
          (vehicleId?.contains(query) ?? false) ||
          desc.contains(query);
    }).toList();
  }

  DateTime _statementGeneratedAt() {
    return (_lastActivity ?? DateTime.now()).toLocal();
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 3;
    final double valueSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _billToName() {
    final name = _companyName;
    if (name == null || name.trim().isEmpty) return '—';
    return name.trim();
  }

  String _billToUserName() {
    final name = _adminName;
    if (name == null || name.trim().isEmpty) return '—';
    return name.trim();
  }

  String _billToEmail() {
    final email = _adminEmail;
    if (email == null || email.trim().isEmpty) return '—';
    return email.trim();
  }

  String? _extractCompanyName(List<CreditLogItem> items) {
    for (final item in items) {
      final raw = item.raw;
      final company = raw['company'] ?? raw['companyName'] ?? raw['orgName'];
      if (company is String && company.trim().isNotEmpty) {
        return company.trim();
      }
      if (company is Map) {
        final name = company['name'] ?? company['companyName'];
        if (name is String && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
      final admin = raw['admin'] ?? raw['adminUser'];
      if (admin is Map) {
        final adminCompany = admin['companyName'] ?? admin['company'];
        if (adminCompany is String && adminCompany.trim().isNotEmpty) {
          return adminCompany.trim();
        }
      }
    }
    return null;
  }

  String _statementId(String adminId, DateTime? ts) {
    final date = (ts ?? DateTime.now()).toLocal();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'STMT-$adminId-$y$m$d';
  }

  Widget _metricCard(
    BuildContext context, {
    required double width,
    required String label,
    required String value,
    String? subValue,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double subSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 3;

    final double lineHeight = subSize * 1.2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            child: Text(
              subValue ?? '',
              style: GoogleFonts.roboto(
                fontSize: subSize,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logCard(BuildContext context, CreditLogItem log) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final dt = DateTime.tryParse(log.createdAt)?.toLocal();
    final dateText = dt == null
        ? '—'
        : '${_formatDate(dt)}, ${_formatTime(dt)}';
    final desc = _logDescription(log);
    final logId = log.id.isNotEmpty ? 'Log #${log.id}' : 'Log #—';
    final amount = log.isCredit ? '+${log.amount}' : '-${log.amount.abs()}';
    final actionLabel = _actionLabel(log);
    final balance = log.balanceAfter != 0 ? log.balanceAfter : _currentCredits;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.roboto(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            logId,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill(
                context,
                text: amount,
              ),
              const Spacer(),
              Text(
                balance.toString(),
                style: GoogleFonts.roboto(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _pill(
                context,
                text: actionLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _actionLabel(CreditLogItem log) {
    return log.isCredit ? 'Assign' : 'Use';
  }

  String _exportActionLabel(CreditLogItem log) {
    return log.isCredit ? 'Add' : 'Use';
  }

  String _logDescription(CreditLogItem log) {
    if (log.description.isNotEmpty) {
      return log.description;
    }
    final vehicleId = log.raw['vehicleId'] ?? log.raw['vehicle_id'];
    if (vehicleId != null) {
      return 'Credits used for Vehicle #$vehicleId';
    }
    return 'Credit Added By Super Admin';
  }

  Widget _pill(BuildContext context, {required String text}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: AdaptiveUtils.getSubtitleFontSize(
                MediaQuery.of(context).size.width,
              ) -
              2,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _Totals {
  final int totalAssigned;
  final int totalDeducted;
  final int currentCredits;
  final int entryCount;
  final DateTime? lastActivity;

  const _Totals({
    required this.totalAssigned,
    required this.totalDeducted,
    required this.currentCredits,
    required this.entryCount,
    required this.lastActivity,
  });
}
