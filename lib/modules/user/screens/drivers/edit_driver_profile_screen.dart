import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_driver_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditDriverProfileScreen extends StatefulWidget {
  final String driverId;
  final UserDriverDetails? initialDetails;

  const EditDriverProfileScreen({
    super.key,
    required this.driverId,
    this.initialDetails,
  });

  @override
  State<EditDriverProfileScreen> createState() =>
      _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  ApiClient? _apiClient;
  UserDriversRepository? _repo;
  CancelToken? _token;

  UserDriverDetails? _details;
  bool _loading = false;
  bool _saving = false;
  bool _errorShown = false;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  final List<_AttributeField> _attributes = [];

  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        color: colorScheme.onSurface.withOpacity(0.5),
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

  @override
  void initState() {
    super.initState();
    _applyDetails(widget.initialDetails);
    _loadDetails();
  }

  @override
  void dispose() {
    _token?.cancel('Edit driver profile disposed');
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    for (final field in _attributes) {
      field.keyController.dispose();
      field.valueController.dispose();
    }
    super.dispose();
  }

  UserDriversRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserDriversRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadDetails() async {
    if (_details != null) return;
    _token?.cancel('Reload driver details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getDriverDetails(
      widget.driverId,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (details) {
        setState(() {
          _details = details;
          _loading = false;
          _errorShown = false;
        });
        _applyDetails(details);
      },
      failure: (error) {
        setState(() => _loading = false);
        if (_isCancelled(error) || _errorShown) return;
        _errorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load driver details.";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  void _applyDetails(UserDriverDetails? details) {
    if (details == null) return;
    _nameController.text = details.fullName;
    _usernameController.text = details.username;
    _emailController.text = details.email;
    _codeController.text = details.mobileCode;
    _mobileController.text = details.mobileNumber;
    _addressController.text = details.addressLine;
    _countryController.text = details.countryCode;
    _stateController.text = details.stateCode;
    _cityController.text = details.cityId;
    _pincodeController.text = details.pincode;

    _attributes.clear();
    final attrs = details.raw['attributes'];
    if (attrs is Map) {
      for (final entry in attrs.entries) {
        _attributes.add(
          _AttributeField(
            keyController: TextEditingController(text: entry.key.toString()),
            valueController:
                TextEditingController(text: entry.value?.toString() ?? ''),
          ),
        );
      }
    }
    if (_attributes.isEmpty) {
      _attributes.add(
        _AttributeField(
          keyController: TextEditingController(),
          valueController: TextEditingController(),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    final base = _details ?? widget.initialDetails;

    final attributes = <String, dynamic>{};
    for (final field in _attributes) {
      final key = field.keyController.text.trim();
      final value = field.valueController.text.trim();
      if (key.isEmpty) continue;
      attributes[key] = value;
    }

    String clean(String v) => v.trim();

    final payload = <String, dynamic>{};
    if (clean(_nameController.text) != clean(base?.fullName ?? '')) {
      payload['name'] = clean(_nameController.text);
    }
    if (clean(_usernameController.text) != clean(base?.username ?? '')) {
      payload['username'] = clean(_usernameController.text);
    }
    if (clean(_emailController.text) != clean(base?.email ?? '')) {
      payload['email'] = clean(_emailController.text);
    }
    if (clean(_codeController.text) != clean(base?.mobileCode ?? '')) {
      payload['mobilePrefix'] = clean(_codeController.text);
    }
    if (clean(_mobileController.text) != clean(base?.mobileNumber ?? '')) {
      payload['mobile'] = clean(_mobileController.text);
    }
    if (clean(_addressController.text) != clean(base?.addressLine ?? '')) {
      payload['address'] = clean(_addressController.text);
    }
    if (clean(_countryController.text) != clean(base?.countryCode ?? '')) {
      payload['countryCode'] = clean(_countryController.text);
    }
    if (clean(_stateController.text) != clean(base?.stateCode ?? '')) {
      payload['stateCode'] = clean(_stateController.text);
    }
    if (clean(_cityController.text) != clean(base?.cityId ?? '')) {
      payload['city'] = clean(_cityController.text);
    }
    if (clean(_pincodeController.text) != clean(base?.pincode ?? '')) {
      payload['pincode'] = clean(_pincodeController.text);
    }

    if (attributes.isNotEmpty) {
      payload['attributes'] = attributes;
    }

    // Drop empty fields to avoid server-side validation errors.
    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      if (value is Map && value.isEmpty) return true;
      return false;
    });

    if (payload.isEmpty) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to update')),
      );
      return;
    }

    final result = await _repoOrCreate().updateDriver(
      widget.driverId,
      payload,
    );

    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop(true);
      },
      failure: (error) {
        setState(() => _saving = false);
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : 'Failed to update driver.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final labelSize = AdaptiveUtils.getTitleFontSize(w);

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
                    'Edit Driver Profile',
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
                'Update driver details',
                style: GoogleFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_loading)
                          const AppShimmer(
                            width: double.infinity,
                            height: 240,
                            radius: 16,
                          )
                        else
                          _buildForm(context, w),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, double w) {
    final cs = Theme.of(context).colorScheme;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(w),
            color: cs.onSurface,
          ),
          decoration: _minimalDecoration(context, hint: 'Full name*').copyWith(
            prefixIcon: Icon(Icons.person_outline, color: cs.primary, size: 22),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(w),
            color: cs.onSurface,
          ),
          decoration: _minimalDecoration(context, hint: 'Username*').copyWith(
            prefixIcon: Icon(Icons.badge_outlined, color: cs.primary, size: 22),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(w),
            color: cs.onSurface,
          ),
          decoration: _minimalDecoration(context, hint: 'Email').copyWith(
            prefixIcon: Icon(Icons.email_outlined, color: cs.primary, size: 22),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                  color: cs.onSurface,
                ),
                decoration: _minimalDecoration(context, hint: 'Code').copyWith(
                  prefixIcon:
                      Icon(Icons.flag_outlined, color: cs.primary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                  color: cs.onSurface,
                ),
                decoration:
                    _minimalDecoration(context, hint: 'Mobile').copyWith(
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: cs.primary, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(w),
            color: cs.onSurface,
          ),
          decoration: _minimalDecoration(context, hint: 'Address*').copyWith(
            prefixIcon:
                Icon(Icons.location_on_outlined, color: cs.primary, size: 22),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _countryController,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                  color: cs.onSurface,
                ),
                decoration:
                    _minimalDecoration(context, hint: 'Country*').copyWith(
                  prefixIcon:
                      Icon(Icons.public, color: cs.primary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stateController,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                  color: cs.onSurface,
                ),
                decoration:
                    _minimalDecoration(context, hint: 'State*').copyWith(
                  prefixIcon:
                      Icon(Icons.flag_outlined, color: cs.primary, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                  color: cs.onSurface,
                ),
                decoration:
                    _minimalDecoration(context, hint: 'City*').copyWith(
                  prefixIcon:
                      Icon(Icons.location_city_outlined, color: cs.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                  color: cs.onSurface,
                ),
                decoration:
                    _minimalDecoration(context, hint: 'Pincode').copyWith(
                  prefixIcon:
                      Icon(Icons.pin_drop_outlined, color: cs.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Driver attributes',
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(w),
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add additional driver details (license, blood group, etc.)',
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        ..._attributes.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: field.keyController,
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(w),
                      color: cs.onSurface,
                    ),
                    decoration: _minimalDecoration(
                      context,
                      hint: 'Attribute key',
                    ).copyWith(
                      prefixIcon: Icon(
                        Icons.label_outline,
                        color: cs.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: field.valueController,
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(w),
                      color: cs.onSurface,
                    ),
                    decoration: _minimalDecoration(
                      context,
                      hint: 'Value',
                    ).copyWith(
                      prefixIcon: Icon(
                        Icons.text_fields_outlined,
                        color: cs.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    setState(() => _attributes.removeAt(index));
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _attributes.add(
                  _AttributeField(
                    keyController: TextEditingController(),
                    valueController: TextEditingController(),
                  ),
                );
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add field'),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _saving
                  ? const AppShimmer(width: 18, height: 18, radius: 9)
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(w),
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttributeField {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _AttributeField({
    required this.keyController,
    required this.valueController,
  });
}
