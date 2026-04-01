import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordManualPaymentScreen extends StatefulWidget {
  const RecordManualPaymentScreen({super.key});

  @override
  State<RecordManualPaymentScreen> createState() =>
      _RecordManualPaymentScreenState();
}

class _RecordManualPaymentScreenState extends State<RecordManualPaymentScreen> {
  final TextEditingController _adminController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _paymentModeController = TextEditingController();

  ApiClient? _api;
  SuperadminRepository? _repo;

  CancelToken? _loadToken;
  CancelToken? _submitToken;

  bool _loadingAdmins = false;
  bool _submitting = false;
  List<AdminListItem> _admins = const [];
  AdminListItem? _selectedAdmin;
  String _paymentMode = 'CASH';

  @override
  void initState() {
    super.initState();
    _amountController.text = '';
    _loadAdmins();
  }

  @override
  void dispose() {
    _loadToken?.cancel('dispose');
    _submitToken?.cancel('dispose');
    _adminController.dispose();
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

  void _snackOnce(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadAdmins() async {
    _ensureRepo();
    _loadToken?.cancel('reload');
    _loadToken = CancelToken();

    if (!mounted) return;
    setState(() => _loadingAdmins = true);

    try {
      final res = await _repo!.getAdmins(limit: 200, cancelToken: _loadToken);
      if (!mounted) return;
      res.when(
        success: (admins) {
          setState(() {
            _admins = admins;
            _loadingAdmins = false;
          });
        },
        failure: (_) {
          setState(() => _loadingAdmins = false);
          _snackOnce("Couldn't load admins.");
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
      _snackOnce("Couldn't load admins.");
    }
  }

  void _openAdminPicker() {
    if (_loadingAdmins) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
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
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Admin',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _admins.isEmpty
                      ? Center(
                          child: Text(
                            'No admins found',
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _admins.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final a = _admins[i];
                            final name = a.name.isNotEmpty
                                ? a.name
                                : (a.username.isNotEmpty ? a.username : '—');
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              title: Text(
                                name,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                a.email.isNotEmpty ? a.email : '—',
                                style: GoogleFonts.roboto(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedAdmin = a;
                                  _adminController.text = name;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPaymentModePicker() {
    final modes = const [
      {'value': 'CASH', 'label': 'Cash'},
      {'value': 'CREDIT_CARD', 'label': 'Credit Card'},
      {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer'},
      {'value': 'WALLET', 'label': 'Wallet'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
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
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Payment Mode',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...modes.map((m) {
                  final value = m['value'] as String;
                  final label = m['label'] as String;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    title: Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: _paymentMode == value
                        ? Icon(
                            Icons.check,
                            color: colorScheme.primary,
                          )
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
  }

  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        color: colorScheme.onSurface.withOpacity(0.7),
        fontSize: AdaptiveUtils.getTitleFontSize(
          MediaQuery.of(context).size.width,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedAdmin == null) {
      _snackOnce('Please select an admin.');
      return;
    }

    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _snackOnce('Please enter amount.');
      return;
    }

    _ensureRepo();
    _submitToken?.cancel('resubmit');
    _submitToken = CancelToken();

    setState(() => _submitting = true);

    try {
      final adminId = int.tryParse(_selectedAdmin!.id) ?? _selectedAdmin!.id;
      final payload = <String, dynamic>{
        'adminId': adminId,
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
        _snackOnce('Payment recorded');
        Navigator.pop(context, true);
        return;
      }

      final err = res.error;
      if (err is ApiException &&
          (err.statusCode == 401 || err.statusCode == 403)) {
        _snackOnce('Not authorized to record payment.');
      } else {
        _snackOnce("Couldn't record payment.");
      }
    } catch (_) {
      if (!mounted) return;
      _snackOnce("Couldn't record payment.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final topPadding = MediaQuery.of(context).padding.top;
    _paymentModeController.text = _paymentMode == 'CREDIT_CARD'
        ? 'Credit Card'
        : _paymentMode == 'BANK_TRANSFER'
            ? 'Bank Transfer'
            : _paymentMode == 'WALLET'
                ? 'Wallet'
                : 'Cash';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                topPadding + AppUtils.appBarHeightCustom + 28,
                padding,
                padding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                        ),
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
                          Text(
                            'Record Manual Payment',
                            style: GoogleFonts.roboto(
                              fontSize: titleSize + 1,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Admin',
                            style: GoogleFonts.roboto(
                              fontSize: 12 *
                                  (w / 420).clamp(0.9, 1.0),
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openAdminPicker,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _adminController.text.isNotEmpty
                                          ? _adminController.text
                                          : 'Select admin',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: labelSize,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  _loadingAdmins
                                      ? const AppShimmer(
                                          width: 16,
                                          height: 16,
                                          radius: 8,
                                        )
                                      : Icon(
                                          Icons.expand_more,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Amount',
                            style: GoogleFonts.roboto(
                              fontSize: 12 *
                                  (w / 420).clamp(0.9, 1.0),
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.roboto(
                              fontSize: labelSize,
                              color: colorScheme.onSurface,
                            ),
                            decoration: _minimalDecoration(
                              context,
                              hint: "Amount (₹)",
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.currency_rupee,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Payment Mode',
                            style: GoogleFonts.roboto(
                              fontSize: 12 *
                                  (w / 420).clamp(0.9, 1.0),
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _paymentModeController,
                            readOnly: true,
                            onTap: _openPaymentModePicker,
                            style: GoogleFonts.roboto(
                              fontSize: labelSize,
                              color: colorScheme.onSurface,
                            ),
                            decoration: _minimalDecoration(
                              context,
                              hint: "Payment mode",
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.account_balance,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              suffixIcon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color:
                                    colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Reference (optional)',
                            style: GoogleFonts.roboto(
                              fontSize: 12 *
                                  (w / 420).clamp(0.9, 1.0),
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _referenceController,
                            minLines: 2,
                            maxLines: 2,
                            style: GoogleFonts.roboto(
                              fontSize: labelSize,
                              color: colorScheme.onSurface,
                            ),
                            decoration: _minimalDecoration(
                              context,
                              hint: "Invoice number, notes, or any reference...",
                            ).copyWith(
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _submitting
                                      ? null
                                      : () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.roboto(
                                          fontSize: labelSize,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.8),
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
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: _submitting
                                          ? const AppShimmer(
                                              width: 18,
                                              height: 18,
                                              radius: 9,
                                            )
                                          : Text(
                                              'Record',
                                              style: GoogleFonts.roboto(
                                                fontSize: labelSize,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onPrimary,
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
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFF5F5F7),
              child: const SuperAdminHomeAppBar(
                title: 'Record Manual Payment',
                leadingIcon: Icons.credit_card,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
