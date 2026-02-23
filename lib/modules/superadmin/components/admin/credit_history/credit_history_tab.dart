// components/admin/credit_history_tab.dart
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/add_deduct_credit_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/credit_history_details_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/email_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditHistoryTab extends StatefulWidget {
  final String adminId;

  const CreditHistoryTab({super.key, required this.adminId});

  @override
  State<CreditHistoryTab> createState() => _CreditHistoryTabState();
}

class _CreditHistoryTabState extends State<CreditHistoryTab> {
  DateTime? _startDate;
  DateTime? _endDate;

  final List<_CreditRow> _rows = <_CreditRow>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _loadFailed = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

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

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _token?.cancel('CreditHistoryTab disposed');
    super.dispose();
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
          final mapped = items
              .map(
                (it) => _CreditRow(
                  description: it.description.isNotEmpty ? it.description : '—',
                  date: it.createdAt,
                  amount: it.amount == 0
                      ? (it.isCredit ? '+0' : '-0')
                      : (it.amount > 0 ? '+${it.amount}' : '${it.amount}'),
                  isCredit: it.isCredit,
                ),
              )
              .toList();

          setState(() {
            _loading = false;
            _errorShown = false;
            _loadFailed = false;
            _rows
              ..clear()
              ..addAll(mapped);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _loadFailed = true;
            _rows.clear();
          });
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
      setState(() {
        _loading = false;
        _loadFailed = true;
        _rows.clear();
      });
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double descFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 4;

    final showNoData = !_loading && _rows.isEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TITLE
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "History",
                      style: GoogleFonts.inter(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_loading)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // DATE RANGE PICKER
              GestureDetector(
                onTap: _showDateRangePicker,
                child: Row(
                  children: [
                    Text(
                      _startDate == null || _endDate == null
                          ? "Select Date Range"
                          : "${_startDate!.toIso8601String().substring(0, 10)} - ${_endDate!.toIso8601String().substring(0, 10)}",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // DOWNLOAD + EMAIL + ADD/DEDUCT
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // DOWNLOAD
              GestureDetector(
                onTap: () {
                  // TODO: implement download logic
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.download,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Download",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // EMAIL
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreditHistoryEmailScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Email",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // ADD/DEDUCT CREDIT
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddDeductCreditScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Add/Deduct",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 12),

          if (_loading)
            Column(
              children: List<Widget>.generate(
                3,
                (_) => _buildHistorySkeleton(colorScheme),
              ),
            ),
          if (showNoData && !_loadFailed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No credit history found.',
                style: GoogleFonts.inter(
                  fontSize: descFontSize,
                  color: colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          if (showNoData && _loadFailed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Couldn't load credit history.",
                      style: GoogleFonts.inter(
                        fontSize: descFontSize,
                        color: colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ),
                  TextButton(onPressed: _loadLogs, child: const Text('Retry')),
                ],
              ),
            ),
          if (!showNoData && !_loading)
            Column(
              children: _rows
                  .map(
                    (r) => _buildTransactionItem(
                      description: r.description,
                      date: r.date,
                      amount: r.amount,
                      color: r.isCredit
                          ? colorScheme.primary
                          : colorScheme.error,
                      descFontSize: descFontSize,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySkeleton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: double.infinity, height: 14, radius: 8),
                SizedBox(height: 6),
                AppShimmer(width: 160, height: 12, radius: 8),
              ],
            ),
          ),
          SizedBox(width: 12),
          AppShimmer(width: 46, height: 16, radius: 8),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String description,
    required String date,
    required String amount,
    required Color color,
    required double descFontSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditHistoryDetailsScreen(
              date: date,
              description: description,
              amount: amount,
              balance: "8000",
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditRow {
  final String description;
  final String date;
  final String amount;
  final bool isCredit;

  const _CreditRow({
    required this.description,
    required this.date,
    required this.amount,
    required this.isCredit,
  });
}
