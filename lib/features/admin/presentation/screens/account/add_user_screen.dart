import 'package:open_vts/core/theme/app_fonts.dart';
// screens/account/add_user_screen.dart
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/presentation/controllers/add_user_controller.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
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

  bool _passwordObscured = true;
  MobilePrefixOption? _selectedPrefix;
  CountryOption? _selectedCountry;
  ReferenceOption? _selectedStateOption;
  ReferenceOption? _selectedCityOption;
  @override
  void initState() {
    super.initState();
    // Defaults for better UX: India prefix if present once loaded.
    _mobilePrefixController.text = '+91';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addUserControllerProvider.notifier).loadReferenceData();
    });
  }

  @override
  void dispose() {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                              style: AppFonts.roboto(
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
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
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
                            final trailing = trailingFor?.call(item);
                            return ListTile(
                              title: Text(
                                labelFor(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.roboto(
                                  fontSize: fontSize - 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: trailing == null || trailing.isEmpty
                                  ? null
                                  : Text(
                                      trailing,
                                      style: AppFonts.roboto(
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
    final formState = ref.read(addUserControllerProvider);
    if (formState.isLoadingPrefixes) return;
    if (formState.prefixes.isEmpty) {
      _showSnack('No mobile prefixes loaded');
      return;
    }
    final picked = await _showSearchableSheet<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: formState.prefixes,
      labelFor: (p) => p.code,
      trailingFor: (p) => p.countryCode,
    );
    if (picked == null || !mounted) return;
    updateLocalUiState(this, () {
      _selectedPrefix = picked;
      _mobilePrefixController.text = picked.code;
    });
  }

  Future<void> _pickCountry() async {
    final formState = ref.read(addUserControllerProvider);
    if (formState.isLoadingCountries) return;
    if (formState.countries.isEmpty) {
      _showSnack('No countries loaded');
      return;
    }
    final picked = await _showSearchableSheet<CountryOption>(
      title: 'Select Country',
      items: formState.countries,
      labelFor: (c) => c.name,
      trailingFor: (c) => c.isoCode,
    );
    if (picked == null || !mounted) return;
    updateLocalUiState(this, () {
      _selectedCountry = picked;
      _countryCodeController.text = picked.name;
      _selectedStateOption = null;
      _selectedCityOption = null;
      _stateCodeController.text = '';
      _cityController.text = '';
    });
    await ref.read(addUserControllerProvider.notifier).loadStates(picked.isoCode);
  }

  Future<void> _pickState() async {
    final country = _selectedCountry;
    if (country == null) {
      _showSnack('Select country first');
      return;
    }
    var formState = ref.read(addUserControllerProvider);
    if (formState.isLoadingStates) return;
    if (formState.states.isEmpty) {
      await ref.read(addUserControllerProvider.notifier).loadStates(country.isoCode);
    }
    if (!mounted) return;
    formState = ref.read(addUserControllerProvider);
    if (formState.states.isEmpty) {
      _showSnack('No states found');
      return;
    }
    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select State',
      items: formState.states,
      labelFor: (s) => s.label,
      trailingFor: (s) => s.value,
    );
    if (picked == null || !mounted) return;
    updateLocalUiState(this, () {
      _selectedStateOption = picked;
      _stateCodeController.text = picked.label;
      _selectedCityOption = null;
      _cityController.text = '';
    });
    await ref.read(addUserControllerProvider.notifier).loadCities(country.isoCode, picked.value);
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
    var formState = ref.read(addUserControllerProvider);
    if (formState.isLoadingCities) return;
    if (formState.cities.isEmpty) {
      await ref.read(addUserControllerProvider.notifier).loadCities(country.isoCode, state.value);
    }
    if (!mounted) return;
    formState = ref.read(addUserControllerProvider);
    if (formState.cities.isEmpty) {
      _showSnack('No cities found');
      return;
    }
    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select City',
      items: formState.cities,
      labelFor: (c) => c.label,
    );
    if (picked == null || !mounted) return;
    updateLocalUiState(this, () {
      _selectedCityOption = picked;
      _cityController.text = picked.label;
    });
  }

  Future<void> _submit() async {
    final submitting = ref.read(addUserControllerProvider).isSubmitting;
    if (submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mobilePrefix = _selectedPrefix?.code ?? _mobilePrefixController.text;
    final countryCode = _selectedCountry?.isoCode ?? '';
    final stateCode = _selectedStateOption?.value ?? '';
    final cityName = _selectedCityOption?.label ?? _cityController.text;

    final ok = await ref.read(addUserControllerProvider.notifier).submit(
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
    if (ok) {
      _showSnack("User created");
      Navigator.pop(context, true);
      return;
    }

    final error = ref.read(addUserControllerProvider).errorMessage;
    if (error != null && error.isNotEmpty) {
      _showSnack(error);
      ref.read(addUserControllerProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final submitState = ref.watch(addUserControllerProvider);
    ref.listen(addUserControllerProvider.select((s) => s.errorMessage), (previous, next) {
      if (next != null && next.isNotEmpty && previous != next) {
        _showSnack(next);
        ref.read(addUserControllerProvider.notifier).clearError();
      }
    });
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double bottomBarScrollPad = AdaptiveUtils.getBottomBarHeight(w) + 32;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding + 6,
            vertical: padding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add User",
                    style: AppFonts.inter(
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
                style: AppFonts.inter(
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
                          style: AppFonts.inter(
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
                          validator: (v) => v == null || v.isEmpty
                              ? "Required"
                              : v.length < 6
                              ? "Full name is required"
                              : null,
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
                            onPressed: () => updateLocalUiState(this, 
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
                          style: AppFonts.inter(
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
                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v)) {
                              return "Please enter a valid email address";
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
                                hint: submitState.isLoadingPrefixes
                                    ? "Loading..."
                                    : "Select",
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
                          style: AppFonts.inter(
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
                                hint: submitState.isLoadingCountries
                                    ? "Loading..."
                                    : "Select country",
                                controller: _countryCodeController,
                                prefixIcon: Icons.public_outlined,
                                readOnly: true,
                                onTap: _pickCountry,
                                suffixIcon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                validator: (_) => _selectedCountry == null
                                    ? "Required"
                                    : null,
                                width: w,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StylishTextField(
                                label: "State",
                                hint: _selectedCountry == null
                                    ? "Select country first"
                                    : (submitState.isLoadingStates
                                          ? "Loading..."
                                          : "Select state"),
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
                              : (submitState.isLoadingCities ? "Loading..." : "Select city"),
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
                    onPressed: submitState.isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: AppFonts.roboto(
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
                    onPressed: submitState.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: submitState.isSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            "Add User",
                            style: AppFonts.roboto(
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
          style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
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
              hintStyle: AppFonts.inter(
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
          style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.primary,
            focusColor: cs.surface,
            initialValue: value,
            hint: Text(
              hint,
              style: AppFonts.inter(
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
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

