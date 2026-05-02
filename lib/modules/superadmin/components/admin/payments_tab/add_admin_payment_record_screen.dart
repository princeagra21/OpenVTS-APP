import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAdminPaymentRecordScreen extends StatefulWidget {
  final String adminId;
  final String? adminName;

  const AddAdminPaymentRecordScreen({
    super.key,
    required this.adminId,
    this.adminName,
  });

  @override
  State<AddAdminPaymentRecordScreen> createState() =>
      _AddAdminPaymentRecordScreenState();
}

class _AddAdminPaymentRecordScreenState
    extends State<AddAdminPaymentRecordScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _paymentModeController = TextEditingController();

  ApiClient? _api;
  SuperadminRepository? _repo;
  CancelToken? _submitToken;
  bool _submitting = false;
  String _paymentMode = 'CASH';
  bool _modeSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _paymentModeController.text = 'Cash';
  }

  @override
  void dispose() {
    _submitToken?.cancel('AddAdminPaymentRecordScreen disposed');
    _amountController.dispose();
    _referenceController.dispose();
    _paymentModeController.dispose();
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = SuperadminRepository(api: _api!);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPaymentModePicker() async {
    if (_modeSheetOpen) return;
    _modeSheetOpen = true;

    final modes = const [
      {'value': 'CASH', 'label': 'Cash'},
      {'value': 'CREDIT_CARD', 'label': 'Credit Card'},
      {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer'},
      {'value': 'WALLET', 'label': 'Wallet'},
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Payment Mode',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...modes.map((m) {
                  final value = m['value'] as String;
                  final label = m['label'] as String;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    title: Text(
                      label,
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                    trailing: _paymentMode == value
                        ? Icon(Icons.check, color: cs.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _paymentMode = value;
                        _paymentModeController.text = label;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    _modeSheetOpen = false;
  }

  InputDecoration _decoration(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        color: cs.onSurface.withOpacity(0.7),
        fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _snack('Please enter amount.');
      return;
    }

    _ensureRepo();
    _submitToken?.cancel('resubmit');
    _submitToken = CancelToken();
    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'adminId': int.tryParse(widget.adminId) ?? widget.adminId,
        'amount': amount,
        'reference': _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        'paymentMode': _paymentMode,
      };

      final res = await _repo!.recordManualTransaction(
        payload,
        cancelToken: _submitToken,
      );

      if (!mounted) return;
      if (res.isSuccess) {
        _snack('Payment recorded');
        Navigator.pop(context, true);
        return;
      }

      final err = res.error;
      if (err is ApiException &&
          (err.statusCode == 401 || err.statusCode == 403)) {
        _snack('Not authorized to record payment.');
      } else {
        _snack("Couldn't record payment.");
      }
    } catch (_) {
      if (!mounted) return;
      _snack("Couldn't record payment.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final adminLabel = widget.adminName?.trim().isNotEmpty == true
        ? widget.adminName!.trim()
        : 'Admin #${widget.adminId}';

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Payment',
                    style: GoogleFonts.roboto(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Record manual payment',
                style: GoogleFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          adminLabel,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.roboto(
                            fontSize: labelSize,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _decoration(
                          context,
                          hint: 'Amount (₹)',
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.currency_rupee,
                            color: cs.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _paymentModeController,
                        readOnly: true,
                        onTap: _openPaymentModePicker,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _decoration(
                          context,
                          hint: 'Payment mode',
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.account_balance,
                            color: cs.primary,
                            size: 22,
                          ),
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _referenceController,
                        minLines: 2,
                        maxLines: 2,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: cs.onSurface,
                        ),
                        decoration: _decoration(
                          context,
                          hint: 'Reference (optional)',
                        ).copyWith(
                          filled: true,
                          fillColor: cs.surface,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _submitting
                                  ? null
                                  : () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.roboto(
                                      fontSize: labelSize,
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _submitting ? null : _submit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: _submitting
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              cs.onPrimary,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Add Record',
                                          style: GoogleFonts.roboto(
                                            fontSize: labelSize,
                                            color: cs.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
