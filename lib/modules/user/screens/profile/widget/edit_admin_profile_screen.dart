import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_profile_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';

class EditAdminProfileScreen extends StatefulWidget {
  final AdminProfile? initialProfile;

  const EditAdminProfileScreen({super.key, this.initialProfile});

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
  String _selectedPhoneCode = '234';
  ApiClient? _api;
  UserProfileRepository? _repo;
  CancelToken? _saveToken;
  bool _saving = false;
  bool _saveErrorShown = false;

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
      _selectedPhoneCode = prefix.replaceAll('+', '');
    }
  }

  @override
  void dispose() {
    _saveToken?.cancel('Edit profile disposed');
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

  UserProfileRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserProfileRepository(api: _api!);
    return _repo!;
  }

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _save() async {
    if (_saving) return;

    _saveToken?.cancel('Restart edit profile save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() {
      _saving = true;
      _saveErrorShown = false;
    });

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty)
        'mobileNumber': _phoneController.text.trim(),
      if (_selectedPhoneCode.trim().isNotEmpty)
        'mobilePrefix': '+${_selectedPhoneCode.trim()}',
      if (_addressController.text.trim().isNotEmpty)
        'address': _addressController.text.trim(),
      if (_stateController.text.trim().isNotEmpty)
        'stateCode': _stateController.text.trim(),
      if (_countryController.text.trim().isNotEmpty)
        'countryCode': _countryController.text.trim(),
      if (_cityController.text.trim().isNotEmpty)
        'city': _cityController.text.trim(),
      if (_pincodeController.text.trim().isNotEmpty)
        'pincode': _pincodeController.text.trim(),
    };

    final result = await _repoOrCreate().updateMyProfile(
      payload,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.pop(context, true);
      },
      failure: (error) {
        setState(() => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't update profile.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
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
      backgroundColor: colorScheme.surface,
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
                    "Edit Profile",
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
                "Update your profile details",
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
                              hint: "Full Name",
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
                        decoration: _minimalDecoration(context, hint: "Email")
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
                                    _selectedPhoneCode = country.phoneCode;
                                    _countryController.text =
                                        country.countryCode;
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
                                  if (_selectedCountry != null)
                                    const SizedBox(width: 6),
                                  Text(
                                    _selectedPhoneCode,
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
                                    hint: "Phone Number",
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
                        decoration: _minimalDecoration(context, hint: "Address")
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
                                    hint: "Country Code",
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
                                    hint: "State",
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
                                    hint: "City",
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
                                    hint: "Pincode",
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
                        onTap: _saving ? null : _save,
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
                                    width: 84,
                                    height: 16,
                                    radius: 8,
                                  )
                                : Text(
                                    "Save Changes",
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
