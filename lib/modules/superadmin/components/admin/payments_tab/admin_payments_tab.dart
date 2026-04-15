import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_recent_transaction.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPaymentsTab extends StatefulWidget {
  final String adminId;

  const AdminPaymentsTab({super.key, required this.adminId});

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;

  int _successCount = 0;
  int _pendingCount = 0;
  int _failedCount = 0;
  List<SuperadminRecentTransaction> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _token?.cancel('AdminPaymentsTab disposed');
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    _token?.cancel('Reload admin payments');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );

      final res = await _api!.get(
        '/superadmin/transactions',
        queryParameters: {
          'adminId': widget.adminId,
          'page': 1,
          'limit': 50,
          'rk': DateTime.now().millisecondsSinceEpoch,
        },
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (data) {
          final items = _extractTransactions(data);
          int success = 0;
          int pending = 0;
          int failed = 0;
          for (final t in items) {
            final s = t.status.toLowerCase();
            if (s.contains('success')) {
              success++;
            } else if (s.contains('pending') || s.contains('processing')) {
              pending++;
            } else if (s.contains('fail') || s.contains('decline')) {
              failed++;
            }
          }
          setState(() {
            _loading = false;
            _successCount = success;
            _pendingCount = pending;
            _failedCount = failed;
            _items = items;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg = err is ApiException
              ? (err.message.isNotEmpty
                  ? err.message
                  : "Couldn't load payments.")
              : "Couldn't load payments.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load payments.")),
      );
    }
  }

  List<SuperadminRecentTransaction> _extractTransactions(dynamic data) {
    dynamic cursor = data;
    if (cursor is Map && cursor['data'] is Map) {
      cursor = cursor['data'];
    }
    if (cursor is Map && cursor['data'] is Map) {
      cursor = cursor['data'];
    }
    if (cursor is Map && cursor['items'] is List) {
      cursor = cursor['items'];
    } else if (cursor is Map && cursor['transactions'] is List) {
      cursor = cursor['transactions'];
    }
    final out = <SuperadminRecentTransaction>[];
    if (cursor is List) {
      for (final it in cursor) {
        if (it is Map<String, dynamic>) {
          out.add(SuperadminRecentTransaction(it));
        } else if (it is Map) {
          out.add(SuperadminRecentTransaction(Map<String, dynamic>.from(it)));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(
        width: double.infinity,
        height: 320,
        radius: 12,
      );
    }
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final double titleSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double scale = AdaptiveUtils.getTitleFontSize(screenWidth) / 14;
    final double headerSize = 18 * scale;

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final cardWidth = (constraints.maxWidth - (gap * 2)) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _metricCard(
                    context,
                    width: cardWidth,
                    label: 'Successful',
                    value: _loading ? '—' : _successCount.toString(),
                    labelSize: labelSize,
                    valueSize: titleSize,
                  ),
                  _metricCard(
                    context,
                    width: cardWidth,
                    label: 'Pending',
                    value: _loading ? '—' : _pendingCount.toString(),
                    labelSize: labelSize,
                    valueSize: titleSize,
                  ),
                  _metricCard(
                    context,
                    width: cardWidth,
                    label: 'Failed',
                    value: _loading ? '—' : _failedCount.toString(),
                    labelSize: labelSize,
                    valueSize: titleSize,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.roboto(
                    fontSize: headerSize,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  Text(
                    'Loading...',
                    style: GoogleFonts.roboto(
                      fontSize: labelSize,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  )
                else if (_items.isEmpty)
                  Text(
                    'No transactions found.',
                    style: GoogleFonts.roboto(
                      fontSize: labelSize,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  )
                else
                  Column(
                    children: _items
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                _transactionRow(context, t),
                                const SizedBox(height: 10),
                                Divider(
                                  height: 1,
                                  color: cs.onSurface.withOpacity(0.08),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required double width,
    required String label,
    required String value,
    required double labelSize,
    required double valueSize,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: labelSize - 1,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _iconFor(label),
                size: 16,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueSize + 4,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('success')) return Icons.check_circle_outline;
    if (l.contains('pending')) return Icons.schedule_outlined;
    if (l.contains('fail')) return Icons.cancel_outlined;
    return Icons.help_outline;
  }

  Widget _transactionRow(
    BuildContext context,
    SuperadminRecentTransaction t,
  ) {
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final name = t.fromUserName.isNotEmpty ? t.fromUserName : t.actorName;
    final date = _formatDateTimeWithSeconds(
      t.raw['createdAt']?.toString() ?? t.time,
    );
    final modeRaw = t.raw['paymentMode']?.toString() ?? '';
    final mode = _titleCase(modeRaw.replaceAll('_', ' '));
    final reference = t.raw['reference']?.toString() ?? '—';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.currency} ${t.amount}',
                      style: GoogleFonts.roboto(
                        fontSize: valueSize + 2,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        t.status,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mode.isEmpty ? '—' : mode,
                      style: GoogleFonts.roboto(
                        fontSize: valueSize + 1,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reference,
                      style: GoogleFonts.roboto(
                        fontSize: labelSize,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.roboto(
                        fontSize: labelSize,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTimeWithSeconds(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final m = local.month.toString();
    final d = local.day.toString();
    final y = local.year.toString();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$m/$d/$y, $hour:$minute:$second $amPm';
  }

  String _titleCase(String input) {
    return input
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}
