// components/admin/edit_admin_profile_screen.dart
import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_profile_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key, this.initialProfile});

  final AdminProfile? initialProfile;

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  Country? _selectedCountry;
  String _mobilePrefix = '+234';
  bool _saving = false;
  bool _saveErrorShown = false;
  DateTime? _lastSaveAt;
  CancelToken? _saveToken;
  ApiClient? _api;
  AdminProfileRepository? _repo;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController.text = profile?.fullName ?? '';
    _emailController.text = profile?.email ?? '';
    _phoneController.text = profile?.mobileNumber ?? '';
    _addressController.text = profile?.addressLine ?? '';
    _stateController.text = profile?.state ?? '';
    _countryController.text = profile?.country ?? '';
    _cityController.text = profile?.city ?? '';
    _pincodeController.text = profile?.pincode ?? '';

    final prefix = profile?.mobilePrefix.trim() ?? '';
    if (prefix.isNotEmpty) {
      _mobilePrefix = prefix.startsWith('+') ? prefix : '+$prefix';
    }
  }

  @override
  void dispose() {
    _saveToken?.cancel('Edit admin profile disposed');
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    final now = DateTime.now();
    if (_lastSaveAt != null &&
        now.difference(_lastSaveAt!).inMilliseconds < 800) {
      return;
    }
    _lastSaveAt = now;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _phoneController.text.trim();
    if (name.isEmpty || email.isEmpty || mobile.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill name, email and phone.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _saving = true;
      _saveErrorShown = false;
    });

    _saveToken?.cancel('New profile save started');
    final token = CancelToken();
    _saveToken = token;

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminProfileRepository(api: _api!);

      final payload = <String, dynamic>{
        // Postman/FleetStack-API-Reference confirmed keys.
        'name': name,
        'email': email,
        'mobilePrefix': _mobilePrefix.trim(),
        'mobileNumber': mobile,
      };

      final result = await _repo!.updateMyProfile(payload, cancelToken: token);
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _saving = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile updated')));
          Navigator.pop(context, true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          if (_saveErrorShown) return;
          _saveErrorShown = true;
          String msg = 'Could not update profile.';
          if (error is ApiException) {
            if (error.statusCode == 401 || error.statusCode == 403) {
              msg = 'Not authorized to update profile.';
            } else if (error.message.trim().isNotEmpty) {
              msg = error.message;
            }
            if (kDebugMode) {
              debugPrint(
                '[Admin Profile] PATCH /admin/profile status=${error.statusCode}',
              );
            }
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (_saveErrorShown) return;
      _saveErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update profile.')),
      );
    }
  }

  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Admin Profile',
                    style: GoogleFonts.inter(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Update admin details',
                style: GoogleFonts.inter(
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
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: 'Full Name',
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        style: GoogleFonts.inter(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(context, hint: 'Email')
                            .copyWith(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                onSelect: (Country country) {
                                  setState(() {
                                    _selectedCountry = country;
                                    _mobilePrefix = '+${country.phoneCode}';
                                  });
                                },
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Search',
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant
                                        .withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedCountry != null)
                                    Text(_selectedCountry!.flagEmoji),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCountry?.phoneCode ??
                                        _mobilePrefix.replaceFirst('+', ''),
                                    style: GoogleFonts.inter(fontSize: 16),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'Phone Number',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        style: GoogleFonts.inter(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(context, hint: 'Address')
                            .copyWith(
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _countryController,
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'Country Code',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.public,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _stateController,
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'State',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.flag_outlined,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
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
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'City',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.location_city_outlined,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'Pincode',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.pin_drop_outlined,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _saveProfile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _saving
                                ? const AppShimmer(
                                    width: 110,
                                    height: 18,
                                    radius: 8,
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.inter(
                                      fontSize: labelSize,
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
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
