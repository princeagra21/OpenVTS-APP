import 'package:open_vts/core/theme/app_fonts.dart';
// components/admin/add_new_admin_screen.dart
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/superadmin/presentation/controllers/superadmin_admin_form_controller.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddNewAdminScreen extends ConsumerStatefulWidget {
  const AddNewAdminScreen({super.key});

  @override
  ConsumerState<AddNewAdminScreen> createState() => _AddNewAdminScreenState();
}

class _AddNewAdminScreenState extends ConsumerState<AddNewAdminScreen> {
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

  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;

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
      hintStyle: AppFonts.roboto(
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
    return AppFonts.roboto(
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
    final formState = ref.watch(superadminAdminFormControllerProvider);
    final formController = ref.read(superadminAdminFormControllerProvider.notifier);
    final selectedPhoneCountry = Country.tryParse(formState.phoneCountryIsoCode);

    ref.listen<SuperadminAdminFormState>(superadminAdminFormControllerProvider, (previous, next) {
      if (previous?.selectedCountry != next.selectedCountry) {
        _countryController.text = next.selectedCountry?.name ?? '';
      }
      if (previous?.selectedState != next.selectedState) {
        _stateController.text = next.selectedState?.label ?? '';
      }
      if (previous?.selectedCity != next.selectedCity) {
        _cityController.text = next.selectedCity?.label ?? '';
      }
      final effect = next.effect;
      if (effect == null || previous?.effect == effect) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(effect.message)));
      formController.clearEffect();
      if (effect.isSuccess && effect.message == 'Admin created') {
        Navigator.pop(context, true);
      }
    });

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
                    style: AppFonts.roboto(
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
                style: AppFonts.roboto(
                  fontSize: helperSize,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
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
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter full name",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
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
                        onChanged: (_) {
                          if (_emailError != null) {
                            updateLocalUiState(this, () => _emailError = null);
                          }
                        },
                        keyboardType: TextInputType.emailAddress,
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter email",
                              fontSize: inputSize,
                            ).copyWith(
                              errorText: _emailError,
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
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
                                  formController.selectPhoneCountry(isoCode: country.countryCode, phoneCode: country.phoneCode);
                                },
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Search',
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
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
                              height: 54, // Match field height approx
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.05),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedPhoneCountry != null)
                                    Text(
                                      selectedPhoneCountry.flagEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "+${formState.phoneCode}",
                                    style: AppFonts.roboto(
                                      fontSize: inputSize,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
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
                              style: AppFonts.roboto(
                                fontSize: inputSize,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: "Enter phone number",
                                    fontSize: inputSize,
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 22,
                                    ),
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
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter username",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.account_circle_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
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
                        onChanged: (_) {
                          if (_passwordError != null) {
                            updateLocalUiState(this, () => _passwordError = null);
                          }
                        },
                        obscureText: !_showPassword,
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter password",
                              fontSize: inputSize,
                            ).copyWith(
                              errorText: _passwordError,
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => updateLocalUiState(this, 
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
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
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter company name",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.business_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
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
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter address",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
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
                            style: AppFonts.roboto(
                              fontSize: inputSize,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration:
                                _minimalDecoration(
                                  context,
                                  hint: "Enter country code",
                                  fontSize: inputSize,
                                ).copyWith(
                                  prefixIcon: Icon(
                                    Icons.public,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _pickCountry,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
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
                            style: AppFonts.roboto(
                              fontSize: inputSize,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration:
                                _minimalDecoration(
                                  context,
                                  hint: "Enter state",
                                  fontSize: inputSize,
                                ).copyWith(
                                  prefixIcon: Icon(
                                    Icons.flag_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _pickState,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
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
                                  style: _labelStyle(
                                    context,
                                    fontSize: labelSize,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _cityController,
                                  readOnly: true,
                                  style: AppFonts.roboto(
                                    fontSize: inputSize,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration:
                                      _minimalDecoration(
                                        context,
                                        hint: "Enter city",
                                        fontSize: inputSize,
                                      ).copyWith(
                                        prefixIcon: Icon(
                                          Icons.location_city_outlined,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 22,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: _pickCity,
                                          icon: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
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
                                  style: _labelStyle(
                                    context,
                                    fontSize: labelSize,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  style: AppFonts.roboto(
                                    fontSize: inputSize,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration:
                                      _minimalDecoration(
                                        context,
                                        hint: "Enter pincode",
                                        fontSize: inputSize,
                                      ).copyWith(
                                        prefixIcon: Icon(
                                          Icons.pin_drop_outlined,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 22,
                                        ),
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
                        style: AppFonts.roboto(
                          fontSize: inputSize,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: "Enter credits",
                              fontSize: inputSize,
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.star_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
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
                      style: AppFonts.roboto(
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
                    onPressed: formState.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      formState.isSubmitting ? "Creating..." : "Create Admin",
                      style: AppFonts.roboto(
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
    Future.microtask(() {
      if (!mounted) return;
      ref.read(superadminAdminFormControllerProvider.notifier).loadReferenceData();
    });
  }

  @override
  void dispose() {
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

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _countryValue() {
    final selected = ref.read(superadminAdminFormControllerProvider).selectedCountry;
    if (selected != null && selected.isoCode.isNotEmpty) return selected.isoCode;
    return _countryController.text.trim();
  }

  String _stateValue() {
    final selected = ref.read(superadminAdminFormControllerProvider).selectedState;
    if (selected != null && selected.value.isNotEmpty) return selected.value;
    return _stateController.text.trim();
  }

  String _cityValue() {
    final selected = ref.read(superadminAdminFormControllerProvider).selectedCity;
    if (selected != null && selected.label.isNotEmpty) return selected.label;
    return _cityController.text.trim();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  Future<void> _submit() async {
    final formState = ref.read(superadminAdminFormControllerProvider);
    if (formState.isSubmitting) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final company = _companyController.text.trim();

    updateLocalUiState(this, () {
      _emailError = null;
      _passwordError = null;
    });

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        company.isEmpty) {
      _showMessage('Please fill all required fields.');
      return;
    }

    var hasFieldError = false;
    if (!_isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
      hasFieldError = true;
    }
    if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      hasFieldError = true;
    }
    if (hasFieldError) {
      updateLocalUiState(this, () {});
      return;
    }

    await ref.read(superadminAdminFormControllerProvider.notifier).submitCreateAdmin(
          name: name,
          email: email,
          phone: phone,
          username: username,
          password: password,
          company: company,
          address: _addressController.text.trim(),
          country: _countryValue(),
          stateName: _stateValue(),
          city: _cityValue(),
          pincode: _pincodeController.text.trim(),
          credits: _creditsController.text.trim(),
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
                            final trailing = trailingFor != null
                                ? trailingFor(item)
                                : null;
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

    return picked;
  }

  Future<void> _pickCountry() async {
    final formState = ref.read(superadminAdminFormControllerProvider);
    if (formState.isLoadingReferenceData) return;
    if (formState.countries.isEmpty) {
      _showMessage('No countries available.');
      return;
    }

    final picked = await _showSearchableSheet<CountryOption>(
      title: 'Select Country',
      items: formState.countries,
      labelFor: (item) => item.name,
      trailingFor: (item) => item.isoCode,
    );

    if (picked == null) return;
    _stateController.clear();
    _cityController.clear();
    await ref.read(superadminAdminFormControllerProvider.notifier).selectCountry(picked);
  }

  Future<void> _pickState() async {
    final formState = ref.read(superadminAdminFormControllerProvider);
    if (formState.selectedCountry == null) {
      _showMessage('Select a country first.');
      return;
    }
    if (formState.isLoadingStates) return;
    if (formState.states.isEmpty) {
      _showMessage('No states available.');
      return;
    }

    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select State',
      items: formState.states,
      labelFor: (item) => item.label,
      trailingFor: (item) => item.value,
    );

    if (picked == null) return;
    _cityController.clear();
    await ref.read(superadminAdminFormControllerProvider.notifier).selectState(picked);
  }

  Future<void> _pickCity() async {
    final formState = ref.read(superadminAdminFormControllerProvider);
    if (formState.selectedState == null || formState.selectedCountry == null) {
      _showMessage('Select a country and state first.');
      return;
    }
    if (formState.isLoadingCities) return;
    if (formState.cities.isEmpty) {
      _showMessage('No cities available.');
      return;
    }

    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select City',
      items: formState.cities,
      labelFor: (item) => item.label,
    );

    if (picked == null) return;
    ref.read(superadminAdminFormControllerProvider.notifier).selectCity(picked);
  }

}

