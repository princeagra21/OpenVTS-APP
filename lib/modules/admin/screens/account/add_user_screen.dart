// screens/account/add_user_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mobilePrefixController = TextEditingController();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  bool _submitting = false;
  bool _passwordObscured = true;

  ApiClient? _apiClient;
  AdminUsersRepository? _repo;
  CommonRepository? _commonRepo;

  // API-driven reference data (same pattern as profile edit screens)
  List<CountryOption> _countries = const [];
  List<ReferenceOption> _states = const [];
  List<ReferenceOption> _cities = const [];
  List<MobilePrefixOption> _prefixes = const [];

  CountryOption? _selectedCountry;
  ReferenceOption? _selectedStateOption;
  ReferenceOption? _selectedCityOption;
  MobilePrefixOption? _selectedPrefix;

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _loadingPrefixes = false;

  CancelToken? _countriesToken;
  CancelToken? _statesToken;
  CancelToken? _citiesToken;
  CancelToken? _prefixesToken;

  ApiClient _apiOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  AdminUsersRepository _repoOrCreate() {
    _repo ??= AdminUsersRepository(api: _apiOrCreate());
    return _repo!;
  }

  CommonRepository _commonRepoOrCreate() {
    _commonRepo ??= CommonRepository(api: _apiOrCreate());
    return _commonRepo!;
  }

  @override
  void initState() {
    super.initState();
    // Defaults for better UX: India prefix if present once loaded.
    _mobilePrefixController.text = '+91';
    _loadPrefixes();
    _loadCountries();
  }

  @override
  void dispose() {
    _countriesToken?.cancel('Add user disposed');
    _statesToken?.cancel('Add user disposed');
    _citiesToken?.cancel('Add user disposed');
    _prefixesToken?.cancel('Add user disposed');
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobilePrefixController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _countryCodeController.dispose();
    _stateCodeController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadCountries() async {
    _countriesToken?.cancel('Reload countries');
    final token = CancelToken();
    _countriesToken = token;
    setState(() => _loadingCountries = true);

    final res = await _commonRepoOrCreate().getCountries(cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _countries = items;
          _loadingCountries = false;
        });
      },
      failure: (err) {
        setState(() => _loadingCountries = false);
        final msg = (err is ApiException) ? err.message : err.toString();
        _showSnack(msg);
      },
    );
  }

  Future<void> _loadPrefixes() async {
    _prefixesToken?.cancel('Reload prefixes');
    final token = CancelToken();
    _prefixesToken = token;
    setState(() => _loadingPrefixes = true);

    final res = await _commonRepoOrCreate().getMobilePrefixes(cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _prefixes = items;
          _loadingPrefixes = false;
        });
        // Select first matching default.
        final match = items.firstWhere(
          (p) => p.countryCode.toUpperCase() == 'IN',
          orElse: () => items.isNotEmpty ? items.first : const MobilePrefixOption(countryCode: 'IN', code: '+91'),
        );
        _selectedPrefix = items.isNotEmpty ? match : null;
        _mobilePrefixController.text = _selectedPrefix?.code ?? _mobilePrefixController.text;
      },
      failure: (err) {
        setState(() => _loadingPrefixes = false);
        final msg = (err is ApiException) ? err.message : err.toString();
        _showSnack(msg);
      },
    );
  }

  Future<void> _loadStates(String countryCode) async {
    _statesToken?.cancel('Reload states');
    final token = CancelToken();
    _statesToken = token;
    setState(() => _loadingStates = true);

    final res = await _commonRepoOrCreate().getStates(countryCode, cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _states = items;
          _loadingStates = false;
        });
      },
      failure: (err) {
        setState(() => _loadingStates = false);
        final msg = (err is ApiException) ? err.message : err.toString();
        _showSnack(msg);
      },
    );
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    _citiesToken?.cancel('Reload cities');
    final token = CancelToken();
    _citiesToken = token;
    setState(() => _loadingCities = true);

    final res = await _commonRepoOrCreate().getCities(
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
      failure: (err) {
        setState(() => _loadingCities = false);
        final msg = (err is ApiException) ? err.message : err.toString();
        _showSnack(msg);
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

    return showModalBottomSheet<T>(
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
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            final trailing = trailingFor?.call(item);
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
  }

  Future<void> _pickMobilePrefix() async {
    if (_loadingPrefixes) return;
    if (_prefixes.isEmpty) {
      _showSnack('No mobile prefixes loaded');
      return;
    }
    final picked = await _showSearchableSheet<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: _prefixes,
      labelFor: (p) => p.code,
      trailingFor: (p) => p.countryCode,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedPrefix = picked;
      _mobilePrefixController.text = picked.code;
    });
  }

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) {
      _showSnack('No countries loaded');
      return;
    }
    final picked = await _showSearchableSheet<CountryOption>(
      title: 'Select Country',
      items: _countries,
      labelFor: (c) => c.name,
      trailingFor: (c) => c.isoCode,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedCountry = picked;
      _countryCodeController.text = picked.name;
      _selectedStateOption = null;
      _selectedCityOption = null;
      _stateCodeController.text = '';
      _cityController.text = '';
      _states = const [];
      _cities = const [];
    });
    _loadStates(picked.isoCode);
  }

  Future<void> _pickState() async {
    final country = _selectedCountry;
    if (country == null) {
      _showSnack('Select country first');
      return;
    }
    if (_loadingStates) return;
    if (_states.isEmpty) {
      await _loadStates(country.isoCode);
    }
    if (!mounted) return;
    if (_states.isEmpty) {
      _showSnack('No states found');
      return;
    }
    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select State',
      items: _states,
      labelFor: (s) => s.label,
      trailingFor: (s) => s.value,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedStateOption = picked;
      _stateCodeController.text = picked.label;
      _selectedCityOption = null;
      _cityController.text = '';
      _cities = const [];
    });
    _loadCities(country.isoCode, picked.value);
  }

  Future<void> _pickCity() async {
    final country = _selectedCountry;
    final state = _selectedStateOption;
    if (country == null) {
      _showSnack('Select country first');
      return;
    }
    if (state == null) {
      _showSnack('Select state first');
      return;
    }
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      await _loadCities(country.isoCode, state.value);
    }
    if (!mounted) return;
    if (_cities.isEmpty) {
      _showSnack('No cities found');
      return;
    }
    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select City',
      items: _cities,
      labelFor: (c) => c.label,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedCityOption = picked;
      _cityController.text = picked.label;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mobilePrefix = _selectedPrefix?.code ?? _mobilePrefixController.text;
    final countryCode = _selectedCountry?.isoCode ?? '';
    final stateCode = _selectedStateOption?.value ?? '';
    final cityName = _selectedCityOption?.label ?? _cityController.text;

    setState(() => _submitting = true);
    try {
      final res = await _repoOrCreate().createUser(
        name: _nameController.text,
        email: _emailController.text,
        mobilePrefix: mobilePrefix,
        mobileNumber: _phoneController.text,
        username: _usernameController.text,
        password: _passwordController.text.trim(),
        companyName: _companyNameController.text,
        address: _addressController.text,
        countryCode: countryCode,
        stateCode: stateCode,
        city: cityName,
        pincode: _pincodeController.text,
      );

      if (!mounted) return;
      res.when(
        success: (_) {
          _showSnack("User created");
          Navigator.pop(context, true);
        },
        failure: (err) {
          final msg = (err is ApiException) ? err.message : err.toString();
          _showSnack(msg);
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double bottomBarScrollPad = AdaptiveUtils.getBottomBarHeight(w) + 32;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding + 6, vertical: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add User",
                    style: GoogleFonts.inter(
                      fontSize: 16 * ((w / 420).clamp(0.9, 1.0)),
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Fill the details and click add.",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: bottomBarScrollPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Basic Information",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Full Name",
                          hint: "Enter full name",
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Username",
                          hint: "Enter username",
                          controller: _usernameController,
                          prefixIcon: Icons.account_circle_outlined,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
                              return "Only lowercase letters, numbers, and underscores";
                            }
                            return null;
                          },
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Password",
                          hint: "Enter password",
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _passwordObscured,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _passwordObscured = !_passwordObscured,
                            ),
                            icon: Icon(
                              _passwordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: cs.primary,
                            ),
                            visualDensity: VisualDensity.compact,
                            tooltip: _passwordObscured
                                ? "Show password"
                                : "Hide password",
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Company Name",
                          hint: "Enter company name",
                          controller: _companyNameController,
                          prefixIcon: Icons.business_outlined,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Address",
                          hint: "Enter address",
                          controller: _addressController,
                          prefixIcon: Icons.location_on_outlined,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Contact Information",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Email",
                          hint: "Enter email address",
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                              return "Invalid email";
                            }
                            return null;
                          },
                          width: w,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            SizedBox(
                              width: w * 0.4,
                              child: StylishTextField(
                                label: "Mobile Prefix",
                                hint: _loadingPrefixes ? "Loading..." : "Select",
                                controller: _mobilePrefixController,
                                prefixIcon: Icons.flag_outlined,
                                readOnly: true,
                                onTap: _pickMobilePrefix,
                                validator: (_) =>
                                    _selectedPrefix == null ? "Required" : null,
                                suffixIcon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                width: w,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StylishTextField(
                                label: "Phone Number",
                                hint: "Enter phone number",
                                controller: _phoneController,
                                prefixIcon: Icons.phone_outlined,
                                validator: (v) =>
                                    v == null || v.isEmpty ? "Required" : null,
                                width: w,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Location",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: StylishTextField(
                                label: "Country",
                                hint: _loadingCountries
                                    ? "Loading..."
                                    : "Select country",
                                controller: _countryCodeController,
                                prefixIcon: Icons.public_outlined,
                                readOnly: true,
                                onTap: _pickCountry,
                                suffixIcon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                validator: (_) =>
                                    _selectedCountry == null ? "Required" : null,
                                width: w,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StylishTextField(
                                label: "State",
                                hint: _selectedCountry == null
                                    ? "Select country first"
                                    : (_loadingStates ? "Loading..." : "Select state"),
                                controller: _stateCodeController,
                                prefixIcon: Icons.map_outlined,
                                readOnly: true,
                                onTap: _pickState,
                                suffixIcon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                validator: (_) => _selectedStateOption == null
                                    ? "Required"
                                    : null,
                                width: w,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "City",
                          hint: _selectedStateOption == null
                              ? "Select state first"
                              : (_loadingCities ? "Loading..." : "Select city"),
                          controller: _cityController,
                          prefixIcon: Icons.location_city_outlined,
                          readOnly: true,
                          onTap: _pickCity,
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          ),
                          validator: (_) =>
                              _selectedCityOption == null ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Pincode",
                          hint: "Enter pincode",
                          controller: _pincodeController,
                          prefixIcon: Icons.pin_outlined,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
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
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(w),
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
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
                      backgroundColor: cs.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.onPrimary),
                            ),
                          )
                        : Text(
                            "Add User",
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(w),
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimary,
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
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD
/// ───────────────────────────────────────────────
class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);
    final fieldHeight = maxLines <= 1 ? 55.0 : (55.0 + (maxLines - 1) * 22.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: fieldHeight,
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: cs.outline.withOpacity(0.3)),
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

/// ───────────────────────────────────────────────
/// STYLISH DROPDOWN
/// ───────────────────────────────────────────────
class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double width;
  final bool enabled;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
    this.enabled = true,
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
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
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
            ),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
