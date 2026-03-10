import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionDetailsScreen extends StatelessWidget {
  // Endpoint truth (FleetStack-API-Reference.md + Postman):
  // - Details endpoint: NOT FOUND for Admin transactions
  // - Receipt endpoint: NOT FOUND for Admin transactions
  //
  // Key mapping used here is local-only from list payload (when available):
  // status: status | paymentStatus | state
  // method: method | paymentMethod | mode | provider
  // amount: amount | totalAmount | value | paidAmount
  // gatewayFee: gatewayFee | fee | processingFee
  // tax: tax | gst | vat
  // credits: credits | credit | creditYears
  // reference: fsId | reference | paymentRef | gatewayRef
  // invoice: invoiceNumber | invoice | txnNo
  final String transactionId;
  final Map<String, dynamic>? initialRaw;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    this.initialRaw,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);
    final raw = initialRaw ?? const <String, dynamic>{};

    final status = _safe(
      _firstString(raw, const ['status', 'paymentStatus', 'state']),
    );
    final method = _safe(
      _firstString(raw, const ['method', 'paymentMethod', 'mode', 'provider']),
    );
    final amount = _formatAmount(
      _firstDouble(raw, const ['amount', 'totalAmount', 'value', 'paidAmount']),
      _safe(_firstString(raw, const ['currency', 'currencyCode'])),
    );
    final gatewayFee = _formatAmount(
      _firstDouble(raw, const ['gatewayFee', 'fee', 'processingFee']),
      _safe(_firstString(raw, const ['currency', 'currencyCode'])),
    );
    final tax = _formatAmount(
      _firstDouble(raw, const ['tax', 'gst', 'vat']),
      _safe(_firstString(raw, const ['currency', 'currencyCode'])),
    );
    final credits = _formatCredits(
      _firstInt(raw, const ['credits', 'credit', 'creditYears']),
    );
    final reference = _safe(
      _firstString(raw, const [
        'fsId',
        'reference',
        'paymentRef',
        'gatewayRef',
      ]),
    );
    final invoice = _safe(
      _firstString(raw, const ['invoiceNumber', 'invoice', 'txnNo']),
    );

    final statusColor = _statusColor(status, cs);

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
                    'Transaction Details',
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
              const SizedBox(height: 24),
              Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: fs - 2,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: fs + 4,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Method',
                style: GoogleFonts.inter(
                  fontSize: fs - 2,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Amount & Credits',
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _detailRow('Amount', amount, fs, cs),
              _detailRow('Gateway fee', gatewayFee, fs, cs),
              _detailRow('Tax', tax, fs, cs),
              _detailRow('Credits', credits, fs, cs),
              const SizedBox(height: 24),
              Text(
                'Gateway',
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reference: $reference',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: fs - 2),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.content_copy, color: cs.primary),
                    onPressed: reference == '—'
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: reference));
                          },
                  ),
                ],
              ),
              Text(
                'Invoice: $invoice',
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  String _safe(String value) {
    final v = value.trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return '—';
    return v;
  }

  String _firstString(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final out = value.toString().trim();
      if (out.isNotEmpty && out.toLowerCase() != 'null') return out;
    }
    return '';
  }

  int? _firstInt(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  double? _firstDouble(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _formatCredits(int? value) {
    if (value == null) return '—';
    if (value > 0) return '+$value';
    return value.toString();
  }

  String _formatAmount(double? value, String currency) {
    if (value == null) return '—';

    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    final fixed = value.toStringAsFixed(2);
    return '$symbol$fixed';
  }

  Color _statusColor(String statusLabel, ColorScheme cs) {
    final s = statusLabel.toLowerCase();
    if (s.contains('success') || s == 'paid') return Colors.green;
    if (s.contains('pending') || s.contains('process')) return Colors.orange;
    if (s.contains('failed') || s.contains('declined')) return Colors.red;
    if (s.contains('refund')) return Colors.red;
    return cs.onSurface;
  }
}
