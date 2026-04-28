import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/user_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  // FleetStack-API-Reference.md + Postman confirmed:
  // - GET /mobileprefix
  // - GET /countries
  // - POST /user/drivers
  //
  // Confirmed payload keys:
  // - name
  // - mobilePrefix
  // - mobile
  // - email
  // - username
  // - password
  // - countryCode
  // - stateCode
  // - city
  // - address
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobilePrefixController =
      TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  ApiClient? _apiClient;
  CommonRepository? _commonRepo;
  UserDriversRepository? _repo;
  CancelToken? _refsToken;
  CancelToken? _saveToken;

  bool _obscurePassword = true;
  bool _loadingRefs = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _saving = false;
  bool _refsErrorShown = false;
  bool _saveErrorShown = false;
  List<CountryOption> _countries = const <CountryOption>[];
  List<MobilePrefixOption> _prefixes = const <MobilePrefixOption>[];
  List<ReferenceOption> _states = const <ReferenceOption>[];
  List<ReferenceOption> _cities = const <ReferenceOption>[];
  CountryOption? _selectedCountry;
  MobilePrefixOption? _selectedPrefix;
  ReferenceOption? _selectedState;
  ReferenceOption? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _refsToken?.cancel('Add driver disposed');
    _saveToken?.cancel('Add driver disposed');
    _nameController.dispose();
    _mobilePrefixController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
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

  CommonRepository _commonRepoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _apiClient!);
    return _commonRepo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  String _normalizePrefix(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('++')) {
      return '+${trimmed.substring(2)}';
    }
    return trimmed;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadReferences() async {
    _refsToken?.cancel('Reload add driver references');
    final token = CancelToken();
    _refsToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    final common = _commonRepoOrCreate();
    final countriesRes = await common.getCountries(cancelToken: token);
    if (!mounted || token.isCancelled) return;
    final prefixesRes = await common.getMobilePrefixes(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    if (countriesRes.isSuccess && prefixesRes.isSuccess) {
      final countries = countriesRes.data ?? const <CountryOption>[];
      final prefixes = prefixesRes.data ?? const <MobilePrefixOption>[];

      CountryOption? selectedCountry;
      for (final item in countries) {
        if (item.isoCode == 'IN') {
          selectedCountry = item;
          break;
        }
      }
      selectedCountry ??= countries.isNotEmpty ? countries.first : null;

      MobilePrefixOption? selectedPrefix;
      if (selectedCountry != null) {
        for (final item in prefixes) {
          if (item.countryCode == selectedCountry.isoCode) {
            selectedPrefix = item;
            break;
          }
        }
      }
      selectedPrefix ??= prefixes.isNotEmpty ? prefixes.first : null;

      if (!mounted) return;
      setState(() {
        _countries = countries;
        _prefixes = prefixes;
        _selectedCountry = selectedCountry;
        _selectedPrefix = selectedPrefix;
        _mobilePrefixController.text = _selectedPrefix?.code ?? '+91';
        _countryController.text = _selectedCountry == null
            ? ''
            : '${_selectedCountry!.name} (${_selectedCountry!.isoCode})';
        _loadingRefs = false;
        _refsErrorShown = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _loadingRefs = false);
    if (_refsErrorShown) return;
    _refsErrorShown = true;
    final error = countriesRes.error ?? prefixesRes.error;
    final msg = error is ApiException && error.message.trim().isNotEmpty
        ? error.message
        : "Couldn't load country references.";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadStates(String countryCode) async {
    _loadingStates = true;
    if (mounted) setState(() {});
    final res = await _commonRepoOrCreate().getStates(countryCode);
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
        final msg = err is ApiException ? err.message : err.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    _loadingCities = true;
    if (mounted) setState(() {});
    final res = await _commonRepoOrCreate().getCities(countryCode, stateCode);
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
        final msg = err is ApiException ? err.message : err.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<T?> _showOptionPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelFor,
    String Function(T item)? trailingFor,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final searchController = TextEditingController();
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = items.where((item) {
              return labelFor(item).toLowerCase().contains(query.toLowerCase());
            }).toList();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final trailing = trailingFor?.call(item);
                          return ListTile(
                            title: Text(labelFor(item)),
                            trailing: trailing == null ? null : Text(trailing),
                            onTap: () => Navigator.pop(ctx, item),
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
      },
    );
  }

  Future<void> _pickPrefix() async {
    if (_loadingRefs || _prefixes.isEmpty) return;
    final picked = await _showOptionPicker<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: _prefixes,
      labelFor: (item) =>
          '${_normalizePrefix(item.code)} (${item.countryCode})',
      trailingFor: (item) => item.countryCode,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedPrefix = picked;
      _mobilePrefixController.text = picked.code;
      for (final country in _countries) {
        if (country.isoCode == picked.countryCode) {
          _selectedCountry = country;
          _countryController.text = '${country.name} (${country.isoCode})';
          break;
        }
      }
    });
  }

  Future<void> _pickCountry() async {
    if (_loadingRefs || _countries.isEmpty) return;
    final picked = await _showOptionPicker<CountryOption>(
      title: 'Select Country',
      items: _countries,
      labelFor: (item) => item.name,
      trailingFor: (item) => item.isoCode,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedCountry = picked;
      _countryController.text = '${picked.name} (${picked.isoCode})';
      _selectedState = null;
      _selectedCity = null;
      _stateController.text = '';
      _cityController.text = '';
      _states = const [];
      _cities = const [];
      for (final prefix in _prefixes) {
        if (prefix.countryCode == picked.isoCode) {
          _selectedPrefix = prefix;
          break;
        }
      }
    });
    await _loadStates(picked.isoCode);
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
    if (!mounted || _states.isEmpty) {
      _showSnack('No states found');
      return;
    }
    final picked = await _showOptionPicker<ReferenceOption>(
      title: 'Select State',
      items: _states,
      labelFor: (item) => item.label,
      trailingFor: (item) => item.value,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedState = picked;
      _stateController.text = picked.label;
      _selectedCity = null;
      _cityController.text = '';
      _cities = const [];
    });
    await _loadCities(country.isoCode, picked.value);
  }

  Future<void> _pickCity() async {
    final country = _selectedCountry;
    final state = _selectedState;
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
    if (!mounted || _cities.isEmpty) {
      _showSnack('No cities found');
      return;
    }
    final picked = await _showOptionPicker<ReferenceOption>(
      title: 'Select City',
      items: _cities,
      labelFor: (item) => item.label,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedCity = picked;
      _cityController.text = picked.label;
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'mobilePrefix': _normalizePrefix(
        _selectedPrefix?.code ?? _mobilePrefixController.text,
      ),
      'mobile': _mobileController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'countryCode': (_selectedCountry?.isoCode ?? '').trim(),
      'stateCode': (_selectedState?.value ?? '').trim(),
      'city': (_selectedCity?.label ?? _cityController.text.trim()),
      'address': _addressController.text.trim(),
    };

    _saveToken?.cancel('Restart add driver');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() {
      _saving = true;
      _saveErrorShown = false;
    });

    final result = await _repoOrCreate().createDriver(
      payload,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Driver added')));
        Navigator.pop(context, true);
      },
      failure: (error) {
        setState(() => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't add driver.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

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
                    'Add New Driver',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
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
                          label: 'Enter full name *',
                          hint: 'Full name',
                          controller: _nameController,
                          prefixIcon: Icons.person,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter mobile number *',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: AdaptiveUtils.getTitleFontSize(w),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  width: w * 0.4,
                                  child: _loadingRefs
                                    ? const AppShimmer(
                                        width: double.infinity,
                                        height: 55,
                                        radius: 16,
                                      )
                                      : StylishTextField(
                                          label: '',
                                          hint: 'Select',
                                          controller: _mobilePrefixController,
                                          prefixIcon: Icons.flag_outlined,
                                          readOnly: true,
                                          onTap: _pickPrefix,
                                          validator: (_) =>
                                              _selectedPrefix == null
                                                  ? 'Required'
                                                  : null,
                                          suffixIcon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                          ),
                                          width: w,
                                          hideLabel: true,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StylishTextField(
                                    label: '',
                                    hint: 'Mobile number',
                                    controller: _mobileController,
                                    prefixIcon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                    width: w,
                                    hideLabel: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: 'Enter email address *',
                          hint: 'Email address',
                          controller: _emailController,
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!RegExp(
                              r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                            ).hasMatch(v)) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: 'Enter username *',
                          hint: 'Username',
                          controller: _usernameController,
                          prefixIcon: Icons.account_circle,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter password *',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: AdaptiveUtils.getTitleFontSize(w),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 55,
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                                decoration: InputDecoration(
                                  fillColor: cs.surface,
                                  filled: true,
                                  hintText: 'Password',
                                  hintStyle: GoogleFonts.inter(
                                    color: cs.onSurface.withOpacity(0.6),
                                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: cs.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: cs.primary,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: cs.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: cs.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _loadingRefs
                            ? const AppShimmer(
                                width: double.infinity,
                                height: 55,
                                radius: 16,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Country',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: AdaptiveUtils.getTitleFontSize(
                                        w,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _SelectionField(
                                    value: _countryController.text.isEmpty
                                        ? 'Select country'
                                        : _countryController.text,
                                    icon: Icons.flag,
                                    width: double.infinity,
                                    onTap: _pickCountry,
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),
                        _loadingStates
                            ? const AppShimmer(
                                width: double.infinity,
                                height: 55,
                                radius: 16,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'State',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: AdaptiveUtils.getTitleFontSize(
                                        w,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _SelectionField(
                                    value: _stateController.text.isEmpty
                                        ? (_selectedCountry == null
                                            ? 'Select country first'
                                            : 'Select state')
                                        : _stateController.text,
                                    icon: Icons.location_on,
                                    width: double.infinity,
                                    onTap: _pickState,
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),
                        _loadingCities
                            ? const AppShimmer(
                                width: double.infinity,
                                height: 55,
                                radius: 16,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'City',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: AdaptiveUtils.getTitleFontSize(
                                        w,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _SelectionField(
                                    value: _cityController.text.isEmpty
                                        ? (_selectedState == null
                                            ? 'Select state first'
                                            : 'Select city')
                                        : _cityController.text,
                                    icon: Icons.location_city,
                                    width: double.infinity,
                                    onTap: _pickCity,
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: 'Enter full address',
                          hint: 'Full address',
                          controller: _addressController,
                          prefixIcon: Icons.home,
                          maxLines: 1,
                          width: w,
                        ),
                        const SizedBox(height: 72),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: AdaptiveUtils.getTitleFontSize(w),
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: cs.primary,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const AppShimmer(
                          width: 62,
                          height: 18,
                          radius: 7,
                        )
                      : Text(
                          'Add Driver',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: AdaptiveUtils.getTitleFontSize(w),
                            height: 20 / 14,
                            color: cs.onPrimary,
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

class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool hideLabel;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
    this.keyboardType,
    this.maxLines = 1,
    this.hideLabel = false,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideLabel) ...[
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: maxLines > 1 ? null : 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
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

class _SelectionField extends StatelessWidget {
  final String value;
  final IconData icon;
  final double width;
  final VoidCallback onTap;

  const _SelectionField({
    required this.value,
    required this.icon,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
          color: cs.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
