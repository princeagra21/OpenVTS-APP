// components/admin/credit_history/add_deduct_credit_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDeductCreditScreen extends StatefulWidget {
  final String adminId;

  const AddDeductCreditScreen({super.key, required this.adminId});

  @override
  State<AddDeductCreditScreen> createState() => _AddDeductCreditScreenState();
}

class _AddDeductCreditScreenState extends State<AddDeductCreditScreen> {
  String? _selectedAction; // 'add' or 'deduct'
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;
  ApiClient? _api;
  CancelToken? _token;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _token?.cancel('AddDeductCreditScreen disposed');
    super.dispose();
  }

  // Reusable minimal InputDecoration — similar to EditAdminProfileScreen
  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
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

  // Dropdown decoration
  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  String get _noteHint {
    if (_selectedAction == 'add') {
      return 'Why we are adding credit';
    } else if (_selectedAction == 'deduct') {
      return 'Why we are deducting credit';
    } else {
      return 'Note (optional)';
    }
  }

  String get _confirmButtonText {
    if (_selectedAction == 'add') {
      return 'Add Credits';
    } else if (_selectedAction == 'deduct') {
      return 'Deduct Credits';
    } else {
      return 'Confirm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add/Deduct Credits",
                    style: GoogleFonts.roboto(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 28, color: colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                "Manage credits",
                style: GoogleFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Action Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true, // Added this to expand the dropdown to full width
                        decoration: _dropdownDecoration(context),
                        value: _selectedAction,
                        hint: Text(
                          'Select Action',
                          style: GoogleFonts.roboto(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: labelSize,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'add', child: Text('Add Credit')),
                          DropdownMenuItem(value: 'deduct', child: Text('Deduct Credit')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value;
                          });
                        },
                        style: GoogleFonts.roboto(fontSize: labelSize, color: colorScheme.onSurface),
                        icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                      ),

                      const SizedBox(height: 16),

                      // Credit Amount
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.roboto(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Credit Amount").copyWith(
                          prefixIcon: Icon(Icons.monetization_on_outlined, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Note
                      TextField(
                        controller: _noteController,
                        style: GoogleFonts.roboto(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: _noteHint).copyWith(
                          prefixIcon: Icon(Icons.note_outlined, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: GoogleFonts.roboto(
                                      fontSize: labelSize,
                                      color: colorScheme.onSurface,
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
                              onTap: () {
                                _submitCredits();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    _confirmButtonText,
                                    style: GoogleFonts.roboto(
                                      fontSize: labelSize,
                                      color: colorScheme.onPrimary,
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

  Future<void> _submitCredits() async {
    if (_submitting) return;
    final action = _selectedAction;
    if (action == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an action.')),
      );
      return;
    }
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid credit amount.')),
      );
      return;
    }

    setState(() => _submitting = true);
    _token?.cancel('New submit');
    final token = CancelToken();
    _token = token;

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      final res = await _api!.post(
        '/superadmin/assigncredits/${widget.adminId}',
        data: {
          'credits': amount.toString(),
          'activity': action == 'add' ? 'ASSIGN' : 'DEDUCT',
        },
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'add'
                    ? 'Credits assigned successfully.'
                    : 'Credits deducted successfully.',
              ),
            ),
          );
          Navigator.pop(context);
        },
        failure: (err) {
          final msg = err is ApiException
              ? (err.message.isNotEmpty
                  ? err.message
                  : "Couldn't update credits.")
              : "Couldn't update credits.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update credits.")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
