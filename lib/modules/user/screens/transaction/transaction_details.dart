// screens/transactions/transaction_details_screen.dart
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionDetailsScreen extends StatelessWidget {
  // FleetStack-API-Reference.md confirms:
  // - GET /user/transactions
  //
  // No User transaction-details or receipt endpoint is confirmed in MD/Postman.
  // This screen renders from the tapped list item passed via route extra.
  final String transactionId;
  final AdminTransactionItem? transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    this.transaction,
  });

  String _safe(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String _formatDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    final local = parsed.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year}, '
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  }

  String _formatAmount(AdminTransactionItem? item) {
    if (item == null || item.amount == null) return '—';
    final symbol = item.currency.toUpperCase() == 'INR'
        ? '₹'
        : '${item.currency} ';
    return '$symbol${_formatNumber(item.amount!)}';
  }

  String _formatCredits(AdminTransactionItem? item) {
    if (item == null || item.credits == null) return '—';
    final value = item.credits!;
    if (value > 0) return '+$value';
    return value.toString();
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatNumber(double value) {
    final negative = value < 0;
    final absolute = value.abs().toStringAsFixed(2);
    final parts = absolute.split('.');
    var whole = parts.first;
    final decimals = parts.last;

    if (whole.length > 3) {
      final lastThree = whole.substring(whole.length - 3);
      var prefix = whole.substring(0, whole.length - 3);
      final groups = <String>[];
      while (prefix.length > 2) {
        groups.insert(0, prefix.substring(prefix.length - 2));
        prefix = prefix.substring(0, prefix.length - 2);
      }
      if (prefix.isNotEmpty) {
        groups.insert(0, prefix);
      }
      whole = '${groups.join(',')},$lastThree';
    }

    return '${negative ? '-' : ''}$whole.$decimals';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);
    final item = transaction;
    final reference = _safe(item?.reference);
    final invoice = _safe(
      item?.invoiceNumber.isEmpty == true ? null : item?.invoiceNumber,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaction Details",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                "Status",
                style: GoogleFonts.inter(
                  fontSize: fs - 2,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                item?.statusLabel ?? '—',
                style: GoogleFonts.inter(
                  fontSize: fs + 4,
                  fontWeight: FontWeight.bold,
                  color: item?.normalizedStatus == 'success'
                      ? Colors.green
                      : item?.normalizedStatus == 'pending'
                      ? Colors.orange
                      : item?.normalizedStatus == 'failed'
                      ? Colors.red
                      : cs.onSurface,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Method",
                style: GoogleFonts.inter(
                  fontSize: fs - 2,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                _safe(item?.method),
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Created",
                style: GoogleFonts.inter(
                  fontSize: fs - 2,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                _formatDate(item?.createdAt ?? ''),
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Amount & Credits",
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              _detailRow("Amount", _formatAmount(item), fs, cs),
              _detailRow("Credits", _formatCredits(item), fs, cs),
              SizedBox(height: 24),
              Text(
                "Gateway",
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Reference: $reference",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: fs - 2),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.content_copy, color: cs.primary),
                    onPressed: () {
                      if (reference == '—') return;
                      Clipboard.setData(ClipboardData(text: reference));
                    },
                  ),
                ],
              ),
              Text(
                "Invoice: $invoice",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: fs - 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, double fs, ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fs - 2,
              color: cs.onSurface.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fs - 2,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
