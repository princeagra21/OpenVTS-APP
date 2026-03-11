import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
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

  String _formatAmount(double amount, {String currency = 'INR'}) {
    final hasDecimals = amount % 1 != 0;
    final number = hasDecimals
        ? amount.toStringAsFixed(2)
        : amount.toStringAsFixed(0);
    return '$currency $number';
  }

  String _formatItemAmount(AdminTransactionItem item) {
    final amount = item.amount;
    if (amount == null) return '—';
    return _formatAmount(
      amount,
      currency: safeText(item.currency, fallback: 'INR'),
    );
  }

  bool _isOnline(AdminTransactionItem item) {
    final method = item.method.toLowerCase();
    return method.contains('stripe') ||
        method.contains('razor') ||
        method.contains('gateway') ||
        method.contains('card') ||
        method.contains('online');
  }

  DateTime? _parseDate(String raw) => DateTime.tryParse(raw)?.toLocal();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showNoData = !loading && items.isEmpty;

    final now = DateTime.now();
    double todaySettled = 0;
    double monthSettled = 0;
    double online = 0;
    double manual = 0;

    for (final item in items) {
      final amount = item.amount ?? 0;
      final date = _parseDate(item.createdAt);
      final isSuccess = item.normalizedStatus == 'success';

      if (isSuccess && date != null) {
        if (date.year == now.year && date.month == now.month) {
          monthSettled += amount;
          if (date.day == now.day) {
            todaySettled += amount;
          }
        }
      }

      if (_isOnline(item)) {
        online += amount;
      } else {
        manual += amount;
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _statBox(
                    context,
                    'Collected Today',
                    loading ? '—' : _formatAmount(todaySettled),
                    'Settled only',
                  ),
                  _statBox(
                    context,
                    'This Month',
                    loading ? '—' : _formatAmount(monthSettled),
                    'Settled only',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statBox(
                    context,
                    'Online',
                    loading ? '—' : _formatAmount(online),
                    'Gateway / card',
                  ),
                  _statBox(
                    context,
                    'Manual',
                    loading ? '—' : _formatAmount(manual),
                    'Bank / offline',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'History',
                          style: GoogleFonts.inter(
                            fontSize: bodyFontSize + 2,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (loading)
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: AppShimmer(
                                width: 14,
                                height: 14,
                                radius: 7,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${items.length} items',
                    style: GoogleFonts.inter(
                      fontSize: bodyFontSize,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              if (loading)
                Column(
                  children: List<Widget>.generate(
                    3,
                    (_) => _historySkeleton(colorScheme),
                  ),
                ),
              if (showNoData)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No payments found',
                        style: GoogleFonts.inter(
                          fontSize: bodyFontSize,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This user has no payment history yet.',
                        style: GoogleFonts.inter(
                          fontSize: smallFontSize + 1,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!showNoData && !loading)
                Column(
                  children: items
                      .map(
                        (payment) => _historyRow(context, payment, colorScheme),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(
    BuildContext context,
    String title,
    String content,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 108,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: bodyFontSize - 1,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize + 2,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: smallFontSize,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _historySkeleton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
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
          AppShimmer(width: 70, height: 16, radius: 8),
        ],
      ),
    );
  }

  Widget _historyRow(
    BuildContext context,
    AdminTransactionItem payment,
    ColorScheme colorScheme,
  ) {
    final description = safeText(
      payment.description.isNotEmpty ? payment.description : payment.method,
    );
    final amount = _formatItemAmount(payment);
    final amountColor = payment.normalizedStatus == 'failed'
        ? colorScheme.error
        : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: bodyFontSize,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateLabel(payment.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              statusChip(context, payment.statusLabel, smallFontSize),
            ],
          ),
        ],
      ),
    );
  }
}
