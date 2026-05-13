import 'package:open_vts/core/theme/app_fonts.dart';

import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/presentation/controllers/add_driver_controller.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddDriverScreen extends ConsumerStatefulWidget {
  const AddDriverScreen({super.key});

  @override
  ConsumerState<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends ConsumerState<AddDriverScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController(
    text: '+91',
  );

  CountryOption? _selectedCountry;
  MobilePrefixOption? _selectedPrefix;
  ReferenceOption? _selectedState;
  ReferenceOption? _selectedCity;
  AdminUserListItem? _selectedPrimaryUser;

  List<CountryOption> _countries = const [];
  List<MobilePrefixOption> _prefixes = const [];
  List<ReferenceOption> _states = const [];
  List<ReferenceOption> _cities = const [];
  List<AdminUserListItem> _users = const [];

  bool _loadingCountries = false;
  bool _loadingPrefixes = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _loadingUsers = false;
  bool _saving = false;
  bool _showPassword = false;
  bool _errorShown = false;


  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  void _showOnce(String message) {
    if (!mounted || _errorShown) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _countryCodeValue() {
    return _selectedCountry?.isoCode.trim() ?? _countryController.text.trim();
  }

  String _stateCodeValue() {
    return _selectedState?.value.trim() ?? _stateController.text.trim();
  }

  String _cityValue() {
    final value = _selectedCity?.label.trim() ?? _cityController.text.trim();
    return value;
  }

  String _mobilePrefixValue() {
    final value = _selectedPrefix?.code.trim() ?? _prefixController.text.trim();
    return value.isEmpty ? '+91' : value;
  }

  Future<T?> _showSearchableSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelFor,
    String Function(T)? trailingFor,
    String searchHint = 'Search',
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
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close, color: colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) => setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.5)),
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
                              ),
                              trailing: trailing == null || trailing.isEmpty ? null : Text(trailing),
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

  Future<void> _loadReferenceData() async {
    await ref.read(addDriverControllerProvider.notifier).loadInitialData();
  }

  Future<void> _loadUsers() async {
    await ref.read(addDriverControllerProvider.notifier).loadUsers();
  }

  Future<void> _loadCountries() async {
    await ref.read(addDriverControllerProvider.notifier).loadCountries();
  }

  Future<void> _loadPrefixes() async {
    await ref.read(addDriverControllerProvider.notifier).loadPrefixes();
  }

  Future<void> _loadStates(String countryCode) async {
    await ref.read(addDriverControllerProvider.notifier).loadStates(countryCode);
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    await ref.read(addDriverControllerProvider.notifier).loadCities(countryCode, stateCode);
  }

  Future<void> _pickPrefix() async {
    if (_loadingPrefixes) return;
    if (_prefixes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile prefixes available.')),
      );
      return;
    }

    final picked = await _showSearchableSheet<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: _prefixes,
      labelFor: (item) => '${item.code} (${item.countryCode})',
      trailingFor: (item) => item.countryCode,
    );

    if (!mounted || picked == null) return;
    updateLocalUiState(this, () {
      _selectedPrefix = picked;
      _prefixController.text = picked.code;
    });
  }

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No countries available.')));
      return;
    }

    final picked = await _showSearchableSheet<CountryOption>(
      title: 'Select Country',
      items: _countries,
      labelFor: (item) => item.name,
      trailingFor: (item) => item.isoCode,
    );

    if (!mounted || picked == null) return;
    updateLocalUiState(this, () {
      _selectedCountry = picked;
      _countryController.text = picked.name;
      _selectedState = null;
      _selectedCity = null;
      _stateController.clear();
      _cityController.clear();
      _states = const [];
      _cities = const [];
      final prefix = _prefixes.isNotEmpty
          ? _prefixes.firstWhere(
              (item) => item.countryCode.toUpperCase() == picked.isoCode,
              orElse: () => _prefixes.first,
            )
          : null;
      if (prefix != null) {
        _selectedPrefix = prefix;
        _prefixController.text = prefix.code;
      }
    });
    await _loadStates(picked.isoCode);
  }

  Future<void> _pickState() async {
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a country first.')));
      return;
    }
    if (_loadingStates) return;
    if (_states.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No states available.')));
      return;
    }

    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select State',
      items: _states,
      labelFor: (item) => item.label,
      trailingFor: (item) => item.value,
    );

    if (!mounted || picked == null) return;
    updateLocalUiState(this, () {
      _selectedState = picked;
      _stateController.text = picked.label;
      _selectedCity = null;
      _cityController.clear();
      _cities = const [];
    });
    await _loadCities(_countryCodeValue(), picked.value);
  }

  Future<void> _pickCity() async {
    if (_selectedCountry == null || _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a country and state first.')),
      );
      return;
    }
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No cities available.')));
      return;
    }

    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select City',
      items: _cities,
      labelFor: (item) => item.label,
      trailingFor: (item) => item.value,
    );

    if (!mounted || picked == null) return;
    updateLocalUiState(this, () {
      _selectedCity = picked;
      _cityController.text = picked.label;
    });
  }

  Future<void> _submit() async {
    final formState = ref.read(addDriverControllerProvider);
    if (formState.isSubmitting) return;
    _errorShown = false;

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCountry == null) {
      _showOnce('Select a country.');
      return;
    }
    if (_selectedPrimaryUser == null) {
      _showOnce('Select a primary user.');
      return;
    }

    final ok = await ref.read(addDriverControllerProvider.notifier).submit(
          CreateAdminDriverInput(
            primaryUserId: _selectedPrimaryUser!.id,
            name: _nameController.text.trim(),
            mobilePrefix: _mobilePrefixValue(),
            mobile: _mobileController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            countryCode: _countryCodeValue(),
            stateCode: _stateCodeValue(),
            city: _cityValue(),
            address: _addressController.text.trim(),
            pincode: _pincodeController.text.trim(),
          ),
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver created')),
      );
      Navigator.pop(context, true);
      return;
    }

    _showOnce(ref.read(addDriverControllerProvider).errorMessage ?? 'Couldn\'t create driver.');
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required double fontSize,
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: cs.surface.withOpacity(0.05),
      hintText: hint,
      hintStyle: AppFonts.roboto(
        color: cs.onSurface.withOpacity(0.5),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context, {required double fontSize}) {
    final cs = Theme.of(context).colorScheme;
    return AppFonts.roboto(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: cs.onSurface.withOpacity(0.8),
    );
  }

  Widget _selectorField({
    required String value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.roboto(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: value.isEmpty
                      ? cs.onSurface.withOpacity(0.5)
                      : cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingField() {
    return const AppShimmer(width: double.infinity, height: 56, radius: 16);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double fontSize,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: AppFonts.roboto(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _fieldDecoration(
        context,
        fontSize: fontSize,
        hint: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formState = ref.watch(addDriverControllerProvider);
    _countries = formState.countries;
    _prefixes = formState.prefixes;
    _states = formState.states;
    _cities = formState.cities;
    _users = formState.users;
    _loadingCountries = formState.isLoadingCountries;
    _loadingPrefixes = formState.isLoadingPrefixes;
    _loadingStates = formState.isLoadingStates;
    _loadingCities = formState.isLoadingCities;
    _loadingUsers = formState.isLoadingUsers;
    _saving = formState.isSubmitting;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final titleSize = 16 * scale;
    final labelSize = 12 * scale;
    final inputSize = 14 * scale;
    final helperSize = 12 * scale;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hp + 6, vertical: hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Driver',
                    style: AppFonts.roboto(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saving ? null : () => Navigator.pop(context),
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
                'Fill driver details and click save.',
                style: AppFonts.roboto(
                  fontSize: helperSize,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Details',
                          style: _labelStyle(context, fontSize: labelSize + 1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Primary User *',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _loadingUsers
                            ? _loadingField()
                            : _selectorField(
                                value: _selectedPrimaryUser?.fullName ?? '',
                                hint: 'Search user...',
                                icon: Icons.group_outlined,
                                onTap: _pickPrimaryUser,
                                fontSize: inputSize,
                              ),
                        const SizedBox(height: 16),
                        Text(
                          'Driver Name *',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'John Doe',
                          icon: Icons.person_outline,
                          fontSize: inputSize,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Email (optional)',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'driver@example.com',
                          icon: Icons.email_outlined,
                          fontSize: inputSize,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return null;
                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Code',
                                    style: _labelStyle(
                                      context,
                                      fontSize: labelSize,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _loadingPrefixes
                                      ? _loadingField()
                                      : _selectorField(
                                          value: _prefixController.text.trim(),
                                          hint: '+91',
                                          icon: Icons.add_call,
                                          onTap: _pickPrefix,
                                          fontSize: inputSize,
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mobile',
                                    style: _labelStyle(
                                      context,
                                      fontSize: labelSize,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _mobileController,
                                    hint: '9876543210',
                                    icon: Icons.phone_outlined,
                                    fontSize: inputSize,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Username *',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _usernameController,
                          hint: 'superadmin',
                          icon: Icons.alternate_email_rounded,
                          fontSize: inputSize,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Password *',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Required'
                              : v.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                          style: AppFonts.roboto(
                            fontSize: inputSize,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          decoration: _fieldDecoration(
                            context,
                            fontSize: inputSize,
                            hint: '••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: cs.primary,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => updateLocalUiState(this, 
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Country *',
                          style: _labelStyle(context, fontSize: labelSize + 1),
                        ),
                        const SizedBox(height: 8),
                        _loadingCountries
                            ? _loadingField()
                            : _selectorField(
                                value: _countryController.text.trim(),
                                hint: 'Select country',
                                icon: Icons.public_outlined,
                                onTap: _pickCountry,
                                fontSize: inputSize,
                              ),
                        const SizedBox(height: 16),
                        Text(
                          'State (optional)',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _loadingStates
                            ? _loadingField()
                            : _selectorField(
                                value: _stateController.text.trim(),
                                hint: 'Select state',
                                icon: Icons.flag_outlined,
                                onTap: _pickState,
                                fontSize: inputSize,
                              ),
                        const SizedBox(height: 16),
                        Text(
                          'City (optional)',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _loadingCities
                            ? _loadingField()
                            : _selectorField(
                                value: _cityController.text.trim(),
                                hint: 'Select city',
                                icon: Icons.location_city_outlined,
                                onTap: _pickCity,
                                fontSize: inputSize,
                              ),
                        const SizedBox(height: 16),
                        Text(
                          'Address (optional)',
                          style: _labelStyle(context, fontSize: labelSize + 1),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _addressController,
                          hint: '123 Main Street',
                          icon: Icons.location_on_outlined,
                          fontSize: inputSize,
                          maxLines: 3,
                          validator: (v) => null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pincode (optional)',
                          style: _labelStyle(context, fontSize: labelSize),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _pincodeController,
                          hint: '123456',
                          icon: Icons.pin_outlined,
                          fontSize: inputSize,
                          keyboardType: TextInputType.number,
                          validator: (v) => null,
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 96),
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
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppFonts.roboto(
                        fontSize: inputSize,
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
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const AppShimmer(width: 72, height: 14, radius: 7)
                        : Text(
                            'Save',
                            style: AppFonts.roboto(
                              fontSize: inputSize,
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

  Future<void> _pickPrimaryUser() async {
    if (_loadingUsers) return;
    if (_users.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No users available.')));
      return;
    }

    final picked = await _showSearchableSheet<AdminUserListItem>(
      title: 'Select Primary User',
      items: _users,
      labelFor: (item) => item.fullName,
      trailingFor: (item) => item.email,
      searchHint: 'Search user...',
    );

    if (!mounted || picked == null) return;
    updateLocalUiState(this, () {
      _selectedPrimaryUser = picked;
    });
  }
}

