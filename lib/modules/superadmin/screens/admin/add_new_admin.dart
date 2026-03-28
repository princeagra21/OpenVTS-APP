// components/admin/add_new_admin_screen.dart
import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
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
  CancelToken? _countriesToken;
  CancelToken? _statesToken;
  CancelToken? _citiesToken;
  ApiClient? _api;
  CommonRepository? _commonRepo;

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
      hintStyle: GoogleFonts.inter(
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
    return GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
                  fontSize: helperSize,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                        obscureText: true,
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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

                      // Country & State
                      Row(
                        children: [
                          Expanded(
                            child: Column(
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
                                  style: GoogleFonts.inter(
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
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
                                  style: GoogleFonts.inter(
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
                                  style: GoogleFonts.inter(
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
                                  style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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

                      const SizedBox(height: 32),

                      // ── Actions ─────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: colorScheme.onSurface
                                        .withOpacity(0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
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
                                onPressed: () {
                                  // TODO: Validate inputs and add new admin (e.g., API call)
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Create Admin",
                                  style: GoogleFonts.inter(
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
        setState(() {
          _countries = items;
          _loadingCountries = false;
        });
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

  Future<void> _loadCities(String stateCode) async {
    _citiesToken?.cancel('Reload cities');
    final token = CancelToken();
    _citiesToken = token;
    setState(() => _loadingCities = true);

    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);

    final res = await _commonRepo!.getCities(stateCode, cancelToken: token);
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

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No countries available.')),
      );
      return;
    }

    final searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final height = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: height,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _countries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _countries[index];
                      final q = searchController.text.trim().toLowerCase();
                      if (q.isNotEmpty &&
                          !item.name.toLowerCase().contains(q) &&
                          !item.isoCode.toLowerCase().contains(q)) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(item.name),
                        trailing: Text(item.isoCode),
                        onTap: () async {
                          Navigator.pop(context);
                          setState(() {
                            _selectedCountryOption = item;
                            _countryController.text = item.name;
                            _stateController.clear();
                            _cityController.clear();
                            _states = const [];
                            _cities = const [];
                            _selectedStateOption = null;
                            _selectedCityOption = null;
                          });
                          await _loadStates(item.isoCode);
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
    searchController.dispose();
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

    final searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final height = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: height,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _states.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _states[index];
                      final q = searchController.text.trim().toLowerCase();
                      if (q.isNotEmpty &&
                          !item.label.toLowerCase().contains(q) &&
                          !item.value.toLowerCase().contains(q)) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(item.label),
                        trailing: Text(item.value),
                        onTap: () async {
                          Navigator.pop(context);
                          setState(() {
                            _selectedStateOption = item;
                            _stateController.text = item.label;
                            _cityController.clear();
                            _cities = const [];
                            _selectedCityOption = null;
                          });
                          await _loadCities(item.value);
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
    searchController.dispose();
  }
}
