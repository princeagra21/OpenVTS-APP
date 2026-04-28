import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_subuser_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/user_subusers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddSubUserScreen extends StatefulWidget {
  final String? subUserId;
  final UserSubUserItem? initialSubUser;

  const AddSubUserScreen({
    super.key,
    this.subUserId,
    this.initialSubUser,
  });

  @override
  State<AddSubUserScreen> createState() => _AddSubUserScreenState();
}

class _AddSubUserScreenState extends State<AddSubUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _mobilePrefixController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  static const int _nameMaxLength = 100;
  static const int _usernameMaxLength = 30;
  static const int _emailMaxLength = 254;
  static const int _passwordMaxLength = 128;

  bool _isActive = true;
  bool _obscurePassword = true;
  bool _loadingRefs = false;
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _detailsLoading = false;
  bool _detailsErrorShown = false;

  List<MobilePrefixOption> _prefixes = const <MobilePrefixOption>[];
  List<CountryOption> _countries = const <CountryOption>[];
  List<ReferenceOption> _states = const <ReferenceOption>[];
  List<ReferenceOption> _cities = const <ReferenceOption>[];
  String? _selectedPrefix;
  CountryOption? _selectedCountry;
  ReferenceOption? _selectedState;
  ReferenceOption? _selectedCity;

  bool get _isEditMode => widget.subUserId != null;

  ApiClient? _api;
  CommonRepository? _commonRepo;
  UserSubUsersRepository? _subUsersRepo;
  CancelToken? _refsToken;
  CancelToken? _countriesToken;
  CancelToken? _statesToken;
  CancelToken? _citiesToken;
  CancelToken? _detailsToken;
  CancelToken? _saveToken;

  @override
  void initState() {
    super.initState();
    _applyInitialValues(widget.initialSubUser);
    if (_isEditMode && widget.initialSubUser == null) {
      _loadDetails();
    }
    _loadPrefixes();
    _loadCountries();
  }

  @override
  void dispose() {
    _refsToken?.cancel('Add sub-user disposed');
    _countriesToken?.cancel('Add sub-user disposed');
    _statesToken?.cancel('Add sub-user disposed');
    _citiesToken?.cancel('Add sub-user disposed');
    _detailsToken?.cancel('Add sub-user disposed');
    _saveToken?.cancel('Add sub-user disposed');
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  CommonRepository _commonOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);
    return _commonRepo!;
  }

  UserSubUsersRepository _subUsersOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _subUsersRepo ??= UserSubUsersRepository(api: _api!);
    return _subUsersRepo!;
  }

  void _applyInitialValues(UserSubUserItem? subUser) {
    if (subUser == null) return;
    _nameController.text = subUser.name;
    _usernameController.text = subUser.username;
    _emailController.text = subUser.email;
    _mobileController.text = subUser.mobileNumber;
    _mobilePrefixController.text = subUser.mobilePrefix;
    _selectedPrefix = subUser.mobilePrefix.trim().isEmpty
        ? null
        : subUser.mobilePrefix.trim();
    _isActive = subUser.isActive;
  }

  Future<void> _loadDetails() async {
    if (!_isEditMode) return;
    _detailsToken?.cancel('Reload sub-user details');
    final token = CancelToken();
    _detailsToken = token;

    if (!mounted) return;
    setState(() => _detailsLoading = true);

    final result = await _subUsersOrCreate().getSubUserDetails(
      widget.subUserId!,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (details) {
        setState(() {
          _detailsLoading = false;
          _detailsErrorShown = false;
        });
        _applyInitialValues(details);
      },
      failure: (error) {
        setState(() => _detailsLoading = false);
        if (_detailsErrorShown) return;
        _detailsErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load sub-user details.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  String? _validateRequiredAndLength(
    String? value,
    int maxLength,
    String field,
  ) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (text.length > maxLength) {
      return '$field must be at most $maxLength characters';
    }
    return null;
  }

  Future<void> _loadPrefixes() async {
    _refsToken?.cancel('Reload mobile prefixes');
    final token = CancelToken();
    _refsToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    try {
      final res = await _commonOrCreate().getMobilePrefixes(cancelToken: token);
      if (!mounted || token.isCancelled) return;
      res.when(
        success: (items) {
          String? selected;
          for (final item in items) {
            if (item.countryCode == 'IN') {
              selected = item.code.replaceFirst('++', '+');
              break;
            }
          }
          selected ??= items.isNotEmpty
              ? items.first.code.replaceFirst('++', '+')
              : null;
          final resolvedSelected = _selectedPrefix?.trim().isNotEmpty == true
              ? _selectedPrefix
              : selected;

          setState(() {
            _prefixes = items;
            _selectedPrefix = resolvedSelected;
            if (resolvedSelected != null && resolvedSelected.isNotEmpty) {
              _mobilePrefixController.text = resolvedSelected;
            }
            _loadingRefs = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          setState(() => _loadingRefs = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          var msg = "Couldn't load mobile prefixes.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRefs = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load mobile prefixes.")),
      );
    }
  }

  Future<void> _loadCountries() async {
    _countriesToken?.cancel('Reload countries');
    final token = CancelToken();
    _countriesToken = token;

    if (!mounted) return;
    setState(() => _loadingCountries = true);

    final res = await _commonOrCreate().getCountries(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    res.when(
      success: (items) {
        setState(() {
          _countries = items;
          _loadingCountries = false;
          _loadErrorShown = false;
        });
      },
      failure: (error) {
        setState(() => _loadingCountries = false);
        if (_loadErrorShown) return;
        _loadErrorShown = true;
        var msg = "Couldn't load countries.";
        if (error is ApiException && error.message.trim().isNotEmpty) {
          msg = error.message;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _loadStates(String countryCode) async {
    _statesToken?.cancel('Reload states');
    final token = CancelToken();
    _statesToken = token;

    if (!mounted) return;
    setState(() => _loadingStates = true);

    final res = await _commonOrCreate().getStates(countryCode, cancelToken: token);
    if (!mounted || token.isCancelled) return;

    res.when(
      success: (items) {
        setState(() {
          _states = items;
          _loadingStates = false;
        });
      },
      failure: (error) {
        setState(() => _loadingStates = false);
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load states.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    _citiesToken?.cancel('Reload cities');
    final token = CancelToken();
    _citiesToken = token;

    if (!mounted) return;
    setState(() => _loadingCities = true);

    final res = await _commonOrCreate().getCities(
      countryCode,
      stateCode,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    res.when(
      success: (items) {
        setState(() {
          _cities = items;
          _loadingCities = false;
        });
      },
      failure: (error) {
        setState(() => _loadingCities = false);
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load cities.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _pickPrefix() async {
    if (_loadingRefs) return;
    if (_prefixes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mobile prefixes loaded')),
      );
      return;
    }

    final picked = await _showOptionPicker<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: _prefixes,
      labelFor: (item) => item.code,
      trailingFor: (item) => item.countryCode,
    );
    if (!mounted || picked == null) return;

    setState(() {
      _selectedPrefix = picked.code.replaceFirst('++', '+');
      _mobilePrefixController.text = picked.code;
    });
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

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if ((_selectedPrefix ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile prefix is required.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    _saveToken?.cancel('Restart add sub-user');
    final token = CancelToken();
    _saveToken = token;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobilePrefix': (_selectedPrefix ?? '').replaceFirst('++', '+').trim(),
      'mobileNumber': _mobileController.text
          .replaceAll(RegExp(r'\D'), '')
          .trim(),
      'isActive': _isActive,
    };

    final password = _passwordController.text.trim();
    if (password.isNotEmpty || !_isEditMode) {
      payload['password'] = password;
    }

    try {
      final res = _isEditMode
          ? await _subUsersOrCreate().updateSubUser(
              widget.subUserId!,
              payload,
              cancelToken: token,
            )
          : await _subUsersOrCreate().createSubUser(
              payload,
              cancelToken: token,
            );
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (_) {
          Navigator.pop(context, true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          var msg = "Couldn't add sub-user.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't add sub-user.")));
    }
  }

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No countries loaded')),
      );
      return;
    }
    final picked = await _showOptionPicker<CountryOption>(
      title: 'Select Country',
      items: _countries,
      labelFor: (item) => item.name,
      trailingFor: (item) => item.isoCode,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedCountry = picked;
      _countryController.text = picked.name;
      _selectedState = null;
      _selectedCity = null;
      _stateController.text = '';
      _cityController.text = '';
      _states = const [];
      _cities = const [];
    });
    await _loadStates(picked.isoCode);
  }

  Future<void> _pickState() async {
    final country = _selectedCountry;
    if (country == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select country first')),
      );
      return;
    }
    if (_loadingStates) return;
    if (_states.isEmpty) {
      await _loadStates(country.isoCode);
    }
    if (!mounted || _states.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No states found')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select country first')),
      );
      return;
    }
    if (state == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select state first')),
      );
      return;
    }
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      await _loadCities(country.isoCode, state.value);
    }
    if (!mounted || _cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cities found')),
      );
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width) * 1.2;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width);
    final bool isEdit = _isEditMode;

    InputDecoration inputDecoration(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: cs.onSurface.withOpacity(0.5),
          fontSize: labelSize,
        ),
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      );
    }

    Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: labelSize,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
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
                    isEdit ? 'Edit Sub-user' : 'Add Sub-user',
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
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
              const SizedBox(height: 20),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_detailsLoading && isEdit)
                          const AppShimmer(
                            width: double.infinity,
                            height: 320,
                            radius: 16,
                          )
                        else ...[
                          fieldLabel('Name *'),
                          TextFormField(
                            controller: _nameController,
                            maxLength: _nameMaxLength,
                            validator: (value) => _validateRequiredAndLength(
                              value,
                              _nameMaxLength,
                              'Name',
                            ),
                            decoration: inputDecoration(
                              'Enter name',
                              Icons.person_outline,
                            ),
                          ),
                        const SizedBox(height: 16),
                        fieldLabel('Username *'),
                        TextFormField(
                          controller: _usernameController,
                          maxLength: _usernameMaxLength,
                          validator: (value) => _validateRequiredAndLength(
                            value,
                            _usernameMaxLength,
                            'Username',
                          ),
                          decoration: inputDecoration(
                            'Enter username',
                            Icons.alternate_email,
                          ),
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Email *'),
                        TextFormField(
                          controller: _emailController,
                          maxLength: _emailMaxLength,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => _validateRequiredAndLength(
                            value,
                            _emailMaxLength,
                            'Email',
                          ),
                          decoration: inputDecoration(
                            'Enter email',
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter mobile number *',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                width: width * 0.4,
                                child: _loadingRefs
                                      ? const AppShimmer(
                                          width: double.infinity,
                                          height: 56,
                                          radius: 16,
                                        )
                                      : TextFormField(
                                          controller: _mobilePrefixController,
                                          readOnly: true,
                                          onTap: _pickPrefix,
                                          validator: (_) =>
                                              _selectedPrefix == null
                                                  ? 'Required'
                                                  : null,
                                          decoration: inputDecoration(
                                            'Select prefix',
                                            Icons.flag_outlined,
                                          ).copyWith(
                                            suffixIcon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                    decoration: inputDecoration(
                                      'Enter mobile number',
                                      Icons.phone_outlined,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Password *'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          maxLength: _passwordMaxLength,
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (_isEditMode && text.isEmpty) return null;
                            return _validateRequiredAndLength(
                              value,
                              _passwordMaxLength,
                              'Password',
                            );
                          },
                          decoration:
                              inputDecoration(
                                _isEditMode
                                    ? 'Enter new password (optional)'
                                    : 'Enter password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                            ),
                        ),
                        SwitchListTile.adaptive(
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Allow this sub-user to sign in immediately',
                            style: GoogleFonts.inter(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ],
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
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
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
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const AppShimmer(width: 18, height: 18, radius: 9)
                        : Text(
                            isEdit ? 'Update Sub-user' : 'Add Sub-user',
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
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
