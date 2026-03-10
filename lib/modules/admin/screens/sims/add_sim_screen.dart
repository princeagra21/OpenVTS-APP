import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/sim_provider_option.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_simcards_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddSimScreen extends StatefulWidget {
  const AddSimScreen({super.key});

  @override
  State<AddSimScreen> createState() => _AddSimScreenState();
}

class _AddSimScreenState extends State<AddSimScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /simproviders
  // - POST /admin/simcards
  //   Confirmed keys: simNumber, providerId, iccid
  //   Optional key used by UI when available: imei

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _iccidController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();

  String? _selectedProviderLabel;
  List<SimProviderOption> _providers = const <SimProviderOption>[];

  bool _loadingProviders = false;
  bool _submitting = false;
  bool _loadErrorShown = false;

  CancelToken? _loadToken;
  CancelToken? _submitToken;

  ApiClient? _apiClient;
  AdminSimCardsRepository? _repo;

  AdminSimCardsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminSimCardsRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _loadToken?.cancel('AddSimScreen disposed');
    _submitToken?.cancel('AddSimScreen disposed');
    _phoneController.dispose();
    _providerController.dispose();
    _iccidController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadProviders() async {
    _loadToken?.cancel('Reload sim providers');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingProviders = true);

    try {
      final result = await _repoOrCreate().getSimProviders(cancelToken: token);
      if (!mounted) return;

      result.when(
        success: (items) {
          if (!mounted) return;
          setState(() {
            _providers = items;
            _loadingProviders = false;
            _loadErrorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _providers = const <SimProviderOption>[];
            _loadingProviders = false;
          });

          if (_isCancelled(err)) return;
          _showLoadErrorOnce("Couldn't load SIM providers.");
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _providers = const <SimProviderOption>[];
        _loadingProviders = false;
      });
      _showLoadErrorOnce("Couldn't load SIM providers.");
    }
  }

  List<String> get _providerLabels {
    final labels = _providers
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels;
  }

  String _providerIdFromLabel(String label) {
    final match = _providers.where((e) => e.name.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final simNumber = _phoneController.text.trim();
    final iccid = _iccidController.text.trim();
    final imei = _imeiController.text.trim();

    final labels = _providerLabels;
    final providerLabel = labels.isNotEmpty
        ? (_selectedProviderLabel ?? '').trim()
        : _providerController.text.trim();

    if (providerLabel.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Provider is required.')));
      return;
    }

    final providerId = labels.isNotEmpty
        ? _providerIdFromLabel(providerLabel)
        : '';

    final payload = <String, dynamic>{'simNumber': simNumber, 'iccid': iccid};

    if (providerId.isNotEmpty) {
      final asInt = int.tryParse(providerId);
      payload['providerId'] = asInt ?? providerId;
    } else {
      payload['provider'] = providerLabel;
    }

    if (imei.isNotEmpty) {
      payload['imei'] = imei;
    }

    _submitToken?.cancel('Replace add sim request');
    final token = CancelToken();
    _submitToken = token;

    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      final result = await _repoOrCreate().addSimCard(
        payload,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _submitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('SIM card added.')));
          Navigator.pop(context, true);
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _submitting = false);

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to add SIM card.'
              : "Couldn't add SIM card.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't add SIM card.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

    final providerLabels = _providerLabels;

    if (_selectedProviderLabel != null &&
        !providerLabels.contains(_selectedProviderLabel)) {
      _selectedProviderLabel = null;
    }

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
                    'Add New SIM Card',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
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
                          label: 'Phone Number',
                          hint: 'Enter phone number',
                          controller: _phoneController,
                          prefixIcon: Icons.phone_rounded,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Required';
                            return null;
                          },
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        if (_loadingProviders)
                          _dropdownShimmer(label: 'Select provider', width: w)
                        else if (providerLabels.isNotEmpty)
                          StylishDropdown(
                            label: 'Select provider',
                            hint: 'Select provider',
                            value: _selectedProviderLabel,
                            items: providerLabels,
                            onChanged: (v) =>
                                setState(() => _selectedProviderLabel = v),
                            width: w,
                          )
                        else
                          StylishTextField(
                            label: 'Provider',
                            hint: 'Enter provider name',
                            controller: _providerController,
                            prefixIcon: Icons.apartment_rounded,
                            validator: (v) {
                              final value = (v ?? '').trim();
                              if (value.isEmpty) return 'Required';
                              return null;
                            },
                            width: w,
                          ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: 'ICCID',
                          hint: 'Enter ICCID',
                          controller: _iccidController,
                          prefixIcon: Icons.sim_card_rounded,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Required';
                            return null;
                          },
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: 'Device IMEI (optional)',
                          hint: 'Enter associated device IMEI',
                          controller: _imeiController,
                          prefixIcon: Icons.device_hub_rounded,
                          width: w,
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
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_submitting || _loadingProviders)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 16,
                                        child: Center(
                                          child: AppShimmer(
                                            width: 100,
                                            height: 14,
                                            radius: 7,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Add SIM Card',
                                        style: GoogleFonts.inter(
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

  Widget _dropdownShimmer({required String label, required double width}) {
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        const AppShimmer(width: double.infinity, height: 55, radius: 16),
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

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
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
        ),
      ],
    );
  }
}

class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final double width;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.primary,
            focusColor: cs.surface,
            value: value,
            hint: Text(
              hint,
              style: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
            ),
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
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
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
