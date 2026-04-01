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

  Future<void> _loadLogs() async {
    _token?.cancel('Reload credit logs');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                        builder: (_) => AddDeductCreditScreen(
                          adminId: widget.adminId,
                        ),
                          ),
                        );
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                        builder: (_) => AddDeductCreditScreen(
                          adminId: widget.adminId,
                        ),
                          ),
                        );
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      billToUser,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      billToEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported CSV: ${file.path}')),
    );
  }

  Future<void> _exportPdf() async {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No credit logs to export.')),
      );
      return;
    }
    final lines = <String>[
      'Statement ${_statementId(widget.adminId, _lastActivity)}',
      'Bill To: ${_billToName()}',
      'User: ${_billToUserName()}',
      'Email: ${_billToEmail()}',
      '',
      'Generated: ${_formatDate(_statementGeneratedAt())}, ${_formatTime(_statementGeneratedAt())}',
      'Current Balance: $_currentCredits',
      'Entries: $_entryCount',
      '',
      'Logs:',
    ];
    for (final log in _logs) {
      final dt = DateTime.tryParse(log.createdAt)?.toLocal();
      final dateText = dt == null
          ? '—'
          : '${_formatDate(dt)}, ${_formatTime(dt)}';
      final desc = _logDescription(log);
      final amount = log.isCredit ? '+${log.amount}' : '-${log.amount.abs()}';
      lines.add('$dateText | $desc | $amount | Log #${log.id}');
    }

    final pdf = _simplePdf(lines);
    final filename = _exportFilename('pdf');
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsBytes(pdf);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported PDF: ${file.path}')),
    );
  }

  List<int> _simplePdf(List<String> lines) {
    String esc(String s) =>
        s.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');

    final text = StringBuffer();
    text.writeln('BT');
    text.writeln('/F1 12 Tf');
    text.writeln('50 780 Td');
    for (int i = 0; i < lines.length; i++) {
      final line = esc(lines[i]);
      if (i == 0) {
        text.writeln('($line) Tj');
      } else {
        text.writeln('0 -16 Td');
        text.writeln('($line) Tj');
      }
    }
    text.writeln('ET');
    final content = text.toString();

    final objects = <String>[];
    objects.add('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
    objects.add('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');
    objects.add(
      '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj',
    );
    objects.add('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
    objects.add(
      '5 0 obj << /Length ${content.length} >> stream\n$content\nendstream endobj',
    );

    final xref = <int>[];
    final buffer = StringBuffer();
    buffer.writeln('%PDF-1.4');
    int offset = buffer.length;
    for (final obj in objects) {
      xref.add(offset);
      buffer.writeln(obj);
      offset = buffer.length;
    }
    final xrefStart = offset;
    buffer.writeln('xref');
    buffer.writeln('0 ${objects.length + 1}');
    buffer.writeln('0000000000 65535 f ');
    for (final off in xref) {
      buffer.writeln(off.toString().padLeft(10, '0') + ' 00000 n ');
    }
    buffer.writeln('trailer << /Size ${objects.length + 1} /Root 1 0 R >>');
    buffer.writeln('startxref');
    buffer.writeln(xrefStart);
    buffer.writeln('%%EOF');
    return buffer.toString().codeUnits;
  }

  String _exportFilename(String ext) {
    final date = (_lastActivity ?? DateTime.now()).toLocal();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'credit-history-admin-${widget.adminId}-$y-$m-$d.$ext';
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
      final desc = (vehicleId != null && vehicleId.isNotEmpty)
          ? 'Credits used for Vehicle #$vehicleId'.toLowerCase()
          : 'Credit Added By Super Admin'.toLowerCase();
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
            height: lineHeight,
            child: Text(
              subValue ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    final t = log.type.trim().toUpperCase();
    if (t == 'ASSIGN' || t == 'CREDIT' || t == 'ADD') return 'Assign';
    if (t == 'DEDUCT' || t == 'DEBIT' || t == 'REMOVE') return 'Use';
    return log.isCredit ? 'Assign' : 'Use';
  }

  String _exportActionLabel(CreditLogItem log) {
    final t = log.type.trim().toUpperCase();
    if (t == 'ASSIGN' || t == 'CREDIT' || t == 'ADD') return 'Add';
    if (t == 'DEDUCT' || t == 'DEBIT' || t == 'REMOVE') return 'Use';
    return log.isCredit ? 'Add' : 'Use';
  }

  String _logDescription(CreditLogItem log) {
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
