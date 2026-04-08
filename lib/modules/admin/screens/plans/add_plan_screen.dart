import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_pricing_plans_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart' show AdaptiveUtils;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPlanScreen extends StatefulWidget {
  const AddPlanScreen({super.key});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();

  final CancelToken _token = CancelToken();
  ApiClient? _apiClient;
  AdminPricingPlansRepository? _repo;

  bool _submitting = false;

  AdminPricingPlansRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminPricingPlansRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));
    _durationController.addListener(() => setState(() {}));
    _currencyController.text = 'INR';
  }

  @override
  void dispose() {
    _token.cancel('AddPlanScreen disposed');
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final currency = _currencyController.text.trim();
    final price = num.tryParse(_priceController.text.trim());
    final durationDays = int.tryParse(_durationController.text.trim());

    if (price == null || durationDays == null || currency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid price, duration, currency.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = await _repoOrCreate().createPlan(
      name: name,
      durationDays: durationDays,
      price: price,
      currency: currency,
      cancelToken: _token,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _submitting = false);
        Navigator.pop(context, true);
      },
      failure: (err) {
        setState(() => _submitting = false);
        final message = err is ApiException
            ? err.message
            : 'Failed to create plan.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

    final currency = _currencyController.text.trim();
    final priceText = _priceController.text.trim().isEmpty
        ? '0'
        : _priceController.text.trim();
    final durationText = _durationController.text.trim().isEmpty
        ? '0'
        : _durationController.text.trim();

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
                    'Add Plan',
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StylishTextField(
                          label: 'Plan Name',
                          hint: 'e.g. Annual Basic',
                          controller: _nameController,
                          prefixIcon: Icons.label_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: 'Currency',
                          hint: 'e.g. INR',
                          controller: _currencyController,
                          prefixIcon: Icons.currency_exchange,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: 'Price',
                          hint: 'e.g. 1499',
                          controller: _priceController,
                          prefixIcon: Icons.attach_money,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: 'Duration (days)',
                          hint: 'e.g. 365',
                          controller: _durationController,
                          prefixIcon: Icons.calendar_today_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Preview',
                                style: GoogleFonts.roboto(
                                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Quick check before saving.',
                                style: GoogleFonts.roboto(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(w) - 2,
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _previewRow(
                                      'Price',
                                      '${currency.isNotEmpty ? '$currency ' : ''}$priceText',
                                      cs,
                                    ),
                                    const SizedBox(height: 8),
                                    _previewRow(
                                      'Duration',
                                      '$durationText days',
                                      cs,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: cs.primary.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _submitting ? 'Saving...' : 'Save Plan',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;
  final TextInputType? keyboardType;
  final int? maxLines;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: fs,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            fillColor: cs.surface,
            filled: true,
            hintText: hint,
            hintStyle: GoogleFonts.roboto(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: fs,
            ),
            prefixIcon: Icon(prefixIcon, color: cs.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
