import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserPaymentsTab extends StatelessWidget {
  final List<AdminTransactionItem> items;
  final bool loading;
  final double bodyFontSize;
  final double smallFontSize;

  const AdminUserPaymentsTab({
    super.key,
    required this.items,
    required this.loading,
    required this.bodyFontSize,
    required this.smallFontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final double titleSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double scale = AdaptiveUtils.getTitleFontSize(screenWidth) / 14;
    final double headerSize = 18 * scale;

    int success = 0;
    int pending = 0;
    int failed = 0;
    for (final t in items) {
      final s = t.normalizedStatus.toLowerCase();
      if (s.contains('success')) {
        success++;
      } else if (s.contains('pending') || s.contains('processing')) {
        pending++;
      } else if (s.contains('fail') || s.contains('decline')) {
        failed++;
      }
    }

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
                    value: loading ? '—' : success.toString(),
                    labelSize: labelSize,
                    valueSize: titleSize,
                  ),
                  _metricCard(
                    context,
                    width: cardWidth,
                    label: 'Pending',
                    value: loading ? '—' : pending.toString(),
                    labelSize: labelSize,
                    valueSize: titleSize,
                  ),
                  _metricCard(
                    context,
                    width: cardWidth,
                    label: 'Failed',
                    value: loading ? '—' : failed.toString(),
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
                if (loading)
                  Text(
                    'Loading...',
                    style: GoogleFonts.roboto(
                      fontSize: labelSize,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  )
                else if (items.isEmpty)
                  Text(
                    'No transactions found.',
                    style: GoogleFonts.roboto(
                      fontSize: labelSize,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  )
                else
                  Column(
                    children: items
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _transactionRow(BuildContext context, AdminTransactionItem t) {
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final name = _safeText(
      t.raw['fromUser'] is Map
          ? (t.raw['fromUser'] as Map)['name']?.toString()
          : null,
    );
    final date = _formatDateTimeWithSeconds(t.createdAt);
    final modeRaw = t.method;
    final mode = _titleCase(modeRaw.replaceAll('_', ' '));
    final reference = _safeText(t.reference);
    final amountText = _formatAmount(t.amount, currency: t.currency);
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                      amountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      ),
                      child: Text(
                        t.statusLabel,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: valueSize + 1,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: labelSize,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _safeText(String? value, {String fallback = '—'}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return fallback;
    return trimmed;
  }

  String _formatAmount(double? amount, {String currency = 'INR'}) {
    if (amount == null) return '—';
    final hasDecimals = amount % 1 != 0;
    final number =
        hasDecimals ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
    return '$currency $number';
  }
}
