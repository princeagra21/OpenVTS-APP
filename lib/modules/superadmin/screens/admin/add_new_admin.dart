// components/admin/add_new_admin_screen.dart
import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import '../../utils/adaptive_utils.dart';

class AddNewAdminScreen extends StatefulWidget {
  const AddNewAdminScreen({super.key});

  @override
  State<AddNewAdminScreen> createState() => _AddNewAdminScreenState();
}

class _AddNewAdminScreenState extends State<AddNewAdminScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();

  Country? _selectedCountry;
  CountryOption? _selectedCountryOption;
  ReferenceOption? _selectedStateOption;
  ReferenceOption? _selectedCityOption;
  List<CountryOption> _countries = const [];
  List<ReferenceOption> _states = const [];
  List<ReferenceOption> _cities = const [];
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _showPassword = false;
  CancelToken? _countriesToken;
  CancelToken? _statesToken;
  CancelToken? _citiesToken;
  ApiClient? _api;
  CommonRepository? _commonRepo;
  SuperadminRepository? _superadminRepo;
  CancelToken? _submitToken;
  bool _submitting = false;
  bool _submitErrorShown = false;

  double _scaleForWidth(double width) =>
      (width / 420).clamp(0.9, 1.0); // keep spec size on larger screens

  // Reusable minimal InputDecoration — matching the style
  InputDecoration _minimalDecoration(
    BuildContext context, {
    String? hint,
    required double fontSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surface.withOpacity(0.05), // Subtle fill for depth
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: fontSize,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }

  // Reusable label style
  TextStyle _labelStyle(BuildContext context, {required double fontSize}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GoogleFonts.roboto(
      fontSize: fontSize,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface.withOpacity(0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(w);
    final scale = _scaleForWidth(w);
    final double titleSize = 16 * scale; // screen title
    final double labelSize = 12 * scale; // field labels
    final double inputSize = 14 * scale; // input text/placeholder
    final double helperSize = 12 * scale; // helper/secondary

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hp + 6, vertical: hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Create Admin",
                    style: GoogleFonts.roboto(
                      fontSize: titleSize,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Fill the details and click create.",
                style: GoogleFonts.roboto(
                  fontSize: helperSize,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      Text(
                        "Full Name",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter full name",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email
                      Text(
                        "Email",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter email",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Phone
                      Text(
                        "Phone Number",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Country Code Picker Button (styled to match fields)
                          GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                onSelect: (Country country) {
                                  setState(() => _selectedCountry = country);
                                },
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Search',
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 54, // Match field height approx
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedCountry != null) Text(_selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "+${_selectedCountry?.phoneCode ?? '91'}",
                                    style: GoogleFonts.roboto(
                                      fontSize: inputSize,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Phone Field
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.roboto(
                                fontSize: inputSize,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: _minimalDecoration(
                                context,
                                hint: "Enter phone number",
                                fontSize: inputSize,
                              ).copyWith(
                                prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Username
                      Text(
                        "Username",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter username",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.account_circle_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Password
                      Text(
                        "Password",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter password",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Company Name
                      Text(
                        "Company Name",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _companyController,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter company name",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.business_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Address
                      Text(
                        "Address",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter address",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Country & State - Now on separate rows
                      // Country
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Country",
                            style: _labelStyle(context, fontSize: labelSize),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _countryController,
                            readOnly: true,
                            style: GoogleFonts.roboto(
                              fontSize: inputSize,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: _minimalDecoration(
                              context,
                              hint: "Enter country code",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(Icons.public, color: Theme.of(context).colorScheme.primary, size: 22),
                              suffixIcon: IconButton(
                                onPressed: _pickCountry,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // State
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "State",
                            style: _labelStyle(context, fontSize: labelSize),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _stateController,
                            readOnly: true,
                            style: GoogleFonts.roboto(
                              fontSize: inputSize,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: _minimalDecoration(
                              context,
                              hint: "Enter state",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                              suffixIcon: IconButton(
                                onPressed: _pickState,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // City & Pincode
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "City",
                                  style: _labelStyle(context, fontSize: labelSize),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _cityController,
                                  readOnly: true,
                                  style: GoogleFonts.roboto(
                                    fontSize: inputSize,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  decoration: _minimalDecoration(
                                    context,
                                    hint: "Enter city",
                                    fontSize: inputSize,
                                  ).copyWith(
                                    prefixIcon: Icon(Icons.location_city_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                                    suffixIcon: IconButton(
                                      onPressed: _pickCity,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pincode",
                                  style: _labelStyle(context, fontSize: labelSize),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.roboto(
                                    fontSize: inputSize,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  decoration: _minimalDecoration(
                                    context,
                                    hint: "Enter pincode",
                                    fontSize: inputSize,
                                  ).copyWith(
                                    prefixIcon: Icon(Icons.pin_drop_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Credits
                      Text(
                        "Credits",
                        style: _labelStyle(context, fontSize: labelSize),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _creditsController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: "Enter credits",
                          fontSize: inputSize,
                        ).copyWith(
                          prefixIcon: Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.roboto(
                        fontSize: inputSize,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _submitting ? "Creating..." : "Create Admin",
                      style: GoogleFonts.roboto(
                        fontSize: inputSize,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
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

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _countriesToken?.cancel('AddNewAdminScreen disposed');
    _statesToken?.cancel('AddNewAdminScreen disposed');
    _citiesToken?.cancel('AddNewAdminScreen disposed');
    _submitToken?.cancel('AddNewAdminScreen disposed');
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _ensureRepo() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);
    _superadminRepo ??= SuperadminRepository(api: _api!);
  }

  void _snackOnce(String msg) {
    if (!mounted || _submitErrorShown) return;
    _submitErrorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _countryValue() {
    final code = _selectedCountryOption?.isoCode;
    if (code != null && code.isNotEmpty) return code;
    return _countryController.text.trim();
  }

  String _stateValue() {
    final value = _selectedStateOption?.value;
    if (value != null && value.isNotEmpty) return value;
    return _stateController.text.trim();
  }

  String _cityValue() {
    final text = _cityController.text.trim();
    if (text.isNotEmpty) return text;
    return _selectedCityOption?.label ?? '';
  }

  String _mobilePrefix() {
    if (_selectedCountry != null) return '+${_selectedCountry!.phoneCode}';
    return '+91';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _submitErrorShown = false;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final company = _companyController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        company.isEmpty) {
      _snackOnce('Please fill all required fields.');
      return;
    }

    _ensureRepo();
    _submitToken?.cancel('resubmit');
    _submitToken = CancelToken();
    setState(() => _submitting = true);

    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'mobilePrefix': _mobilePrefix(),
      'mobileNumber': phone,
      'username': username,
      'password': password,
      'companyName': company,
      'address': _addressController.text.trim(),
      'country': _countryValue(),
      'state': _stateValue(),
      'city': _cityValue(),
      'pincode': _pincodeController.text.trim(),
      'credits': _creditsController.text.trim(),
    };

    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await _superadminRepo!.createAdmin(
      payload,
      cancelToken: _submitToken,
    );
    if (!mounted) return;

    res.when(
      success: (_) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin created')),
        );
        Navigator.pop(context, true);
      },
      failure: (err) {
        setState(() => _submitting = false);
        if (err is ApiException && err.message.trim().isNotEmpty) {
          _snackOnce(err.message);
        } else {
          _snackOnce("Couldn't create admin.");
        }
      },
    );
  }

  Future<void> _loadCountries() async {
    _countriesToken?.cancel('Reload countries');
    final token = CancelToken();
    _countriesToken = token;
    setState(() => _loadingCountries = true);

    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);

    final res = await _commonRepo!.getCountries(cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        final CountryOption? india = items.isNotEmpty
            ? items.firstWhere(
                (c) => c.isoCode.toUpperCase() == 'IN',
                orElse: () => items.first,
              )
            : null;
        final shouldSelectDefault = _selectedCountryOption == null && india != null;

        setState(() {
          _countries = items;
          _loadingCountries = false;
          if (shouldSelectDefault) {
            _selectedCountryOption = india;
            _countryController.text = india.name;
            _selectedCountry = Country.tryParse(india.isoCode);
          }
        });

        if (shouldSelectDefault) {
          _loadStates(india.isoCode);
        }
      },
      failure: (_) {
        setState(() => _loadingCountries = false);
      },
    );
  }

  Future<void> _loadStates(String countryCode) async {
    _statesToken?.cancel('Reload states');
    final token = CancelToken();
    _statesToken = token;
    setState(() => _loadingStates = true);

    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);

    final res = await _commonRepo!.getStates(countryCode, cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _states = items;
          _loadingStates = false;
        });
      },
      failure: (_) {
        setState(() => _loadingStates = false);
      },
    );
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    _citiesToken?.cancel('Reload cities');
    final token = CancelToken();
    _citiesToken = token;
    setState(() => _loadingCities = true);

    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);

    final res = await _commonRepo!.getCities(
      countryCode,
      stateCode,
      cancelToken: token,
    );
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _cities = items;
          _loadingCities = false;
        });
      },
      failure: (_) {
        setState(() => _loadingCities = false);
      },
    );
  }

  Future<T?> _showSearchableSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelFor,
    String Function(T)? trailingFor,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    String query = '';
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );

    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = items.where((item) {
                  final text = labelFor(item).toLowerCase();
                  return text.contains(query.toLowerCase());
                }).toList();
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.roboto(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          filled: true,
                          fillColor:
                              colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            final trailing =
                                trailingFor != null ? trailingFor(item) : null;
                            return ListTile(
                              title: Text(
                                labelFor(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: fontSize - 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: trailing == null || trailing.isEmpty
                                  ? null
                                  : Text(
                                      trailing,
                                      style: GoogleFonts.roboto(
                                        fontSize: fontSize - 2,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                              onTap: () => Navigator.pop(ctx, item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    return picked;
  }

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No countries available.')),
      );
      return;
    }

    final picked = await _showSearchableSheet<CountryOption>(
      title: 'Select Country',
      items: _countries,
      labelFor: (item) => item.name,
      trailingFor: (item) => item.isoCode,
    );

    if (picked == null) return;
    setState(() {
      _selectedCountryOption = picked;
      _countryController.text = picked.name;
      _stateController.clear();
      _cityController.clear();
      _states = const [];
      _cities = const [];
      _selectedStateOption = null;
      _selectedCityOption = null;
    });
    await _loadStates(picked.isoCode);
  }

  Future<void> _pickState() async {
    if (_selectedCountryOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a country first.')),
      );
      return;
    }
    if (_loadingStates) return;
    if (_states.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No states available.')),
      );
      return;
    }

    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select State',
      items: _states,
      labelFor: (item) => item.label,
      trailingFor: (item) => item.value,
    );

    if (picked == null) return;
    setState(() {
      _selectedStateOption = picked;
      _stateController.text = picked.label;
      _cityController.clear();
      _cities = const [];
      _selectedCityOption = null;
    });
    await _loadCities(_countryValue(), picked.value);
  }

  Future<void> _pickCity() async {
    if (_selectedStateOption == null || _selectedCountryOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a country and state first.')),
      );
      return;
    }
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cities available.')),
      );
      return;
    }

    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select City',
      items: _cities,
      labelFor: (item) => item.label,
    );

    if (picked == null) return;
    setState(() {
      _selectedCityOption = picked;
      _cityController.text = picked.label;
    });
  }
}
