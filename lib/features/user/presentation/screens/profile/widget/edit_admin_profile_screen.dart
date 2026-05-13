import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/core/error/legacy_error_presenter.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_feedback.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_modal.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
import 'package:country_picker/country_picker.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class EditAdminProfileScreen extends ConsumerStatefulWidget {
  final AdminProfile? initialProfile;

  const EditAdminProfileScreen({super.key, this.initialProfile});

  @override
  ConsumerState<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends ConsumerState<EditAdminProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  CountryOption? _selectedCountryOption;
  ReferenceOption? _selectedStateOption;
  ReferenceOption? _selectedCityOption;
  List<CountryOption> _countries = const [];
  List<ReferenceOption> _states = const [];
  List<ReferenceOption> _cities = const [];
  Country? _selectedCountry;
  String _selectedPhoneCode = '234';
  late final _repo = ref.read(userProfileRepositoryAdapterProvider);
  ReferenceDataRepository? _commonRepo;
  AppCancellationHandle? _saveToken;
  AppCancellationHandle? _countriesToken;
  AppCancellationHandle? _statesToken;
  AppCancellationHandle? _citiesToken;
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
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

    _loadCountries();
  }

  @override
  void dispose() {
    _saveToken?.cancel('Edit profile disposed');
    _countriesToken?.cancel('Edit profile disposed');
    _statesToken?.cancel('Edit profile disposed');
    _citiesToken?.cancel('Edit profile disposed');
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


  ReferenceDataRepository _commonRepoOrCreate() {
    _commonRepo ??= ref.read(referenceDataRepositoryProvider);
    return _commonRepo!;
  }

  bool _isCancelled(Object error) {
    return LegacyErrorPresenter.isApiFailure(error) &&
        LegacyErrorPresenter.message(error).toLowerCase() == 'request cancelled';
  }

  String _countryCodeValue() => _selectedCountryOption?.isoCode ?? '';

  Future<void> _loadCountries() async {
    _countriesToken?.cancel('Reload countries');
    final token = AppCancellationHandle();
    _countriesToken = token;

    if (!mounted) return;
    updateLocalUiState(this, () => _loadingCountries = true);

    final res = await _commonRepoOrCreate().getCountries(cancelToken: token);
    if (!mounted) return;

    res.when(
      success: (items) {
        final profile = widget.initialProfile;
        CountryOption? selected;
        if (profile != null && profile.country.trim().isNotEmpty) {
          for (final c in items) {
            final raw = profile.country.trim().toLowerCase();
            if (c.isoCode.toLowerCase() == raw || c.name.toLowerCase() == raw) {
              selected = c;
              break;
            }
          }
        }

        updateLocalUiState(this, () {
          _countries = items;
          _selectedCountryOption = selected ?? _selectedCountryOption;
          _loadingCountries = false;
          if (_selectedCountryOption != null) {
            _countryController.text = _selectedCountryOption!.name;
          }
        });

        if (_selectedCountryOption != null) {
          _loadStates(_selectedCountryOption!.isoCode);
        }
      },
      failure: (_) {
        if (!mounted) return;
        updateLocalUiState(this, () => _loadingCountries = false);
      },
    );
  }

  Future<void> _loadStates(String countryCode) async {
    _statesToken?.cancel('Reload states');
    final token = AppCancellationHandle();
    _statesToken = token;

    if (!mounted) return;
    updateLocalUiState(this, () => _loadingStates = true);

    final res = await _commonRepoOrCreate().getStates(
      countryCode,
      cancelToken: token,
    );
    if (!mounted) return;

    res.when(
      success: (items) {
        final previousState = _stateController.text.trim();
        updateLocalUiState(this, () {
          _states = items;
          _loadingStates = false;
          _selectedStateOption = null;
          _selectedCityOption = null;
          _cities = const [];
        });
        if (previousState.isNotEmpty) {
          for (final state in _states) {
            if (state.label.toLowerCase() == previousState.toLowerCase() ||
                state.value.toLowerCase() == previousState.toLowerCase()) {
              _selectedStateOption = state;
              _stateController.text = state.label;
              _loadCities(_countryCodeValue(), state.value);
              break;
            }
          }
        }
      },
      failure: (_) {
        if (!mounted) return;
        updateLocalUiState(this, () => _loadingStates = false);
      },
    );
  }

  Future<void> _loadCities(String countryCode, String stateCode) async {
    _citiesToken?.cancel('Reload cities');
    final token = AppCancellationHandle();
    _citiesToken = token;

    if (!mounted) return;
    updateLocalUiState(this, () => _loadingCities = true);

    final res = await _commonRepoOrCreate().getCities(
      countryCode,
      stateCode,
      cancelToken: token,
    );
    if (!mounted) return;

    res.when(
      success: (items) {
        final previousCity = _cityController.text.trim();
        updateLocalUiState(this, () {
          _cities = items;
          _loadingCities = false;
          _selectedCityOption = null;
        });
        if (previousCity.isNotEmpty) {
          for (final city in _cities) {
            if (city.label.toLowerCase() == previousCity.toLowerCase() ||
                city.value.toLowerCase() == previousCity.toLowerCase()) {
              _selectedCityOption = city;
              _cityController.text = city.label;
              break;
            }
          }
        }
      },
      failure: (_) {
        if (!mounted) return;
        updateLocalUiState(this, () => _loadingCities = false);
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

    return OpenVtsModal.showBottomSheet<T>(
      context: context,
      child: Builder(
        builder: (ctx) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
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
                              style: AppFonts.inter(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
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
                      OpenVtsTextField(
                        controller: searchController,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                        hintText: 'Search',
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurface.withOpacity(0.5),
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
                                style: AppFonts.inter(
                                  fontSize: fontSize - 1,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              trailing: trailing == null || trailing.isEmpty
                                  ? null
                                  : Text(
                                      trailing,
                                      style: AppFonts.inter(
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
          );
        },
      ),
    );
  }

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) return;
    final picked = await _showSearchableSheet<CountryOption>(
      title: 'Select Country',
      items: _countries,
      labelFor: (item) => item.name,
      trailingFor: (item) => item.isoCode,
    );
    if (picked == null) return;
    updateLocalUiState(this, () {
      _selectedCountryOption = picked;
      _countryController.text = picked.name;
      _selectedStateOption = null;
      _selectedCityOption = null;
      _stateController.clear();
      _cityController.clear();
      _states = const [];
      _cities = const [];
    });
    await _loadStates(picked.isoCode);
  }

  Future<void> _pickState() async {
    if (_selectedCountryOption == null || _loadingStates || _states.isEmpty) {
      return;
    }
    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select State',
      items: _states,
      labelFor: (item) => item.label,
      trailingFor: (item) => item.value,
    );
    if (picked == null) return;
    updateLocalUiState(this, () {
      _selectedStateOption = picked;
      _stateController.text = picked.label;
      _selectedCityOption = null;
      _cityController.clear();
      _cities = const [];
    });
    await _loadCities(_countryCodeValue(), picked.value);
  }

  Future<void> _pickCity() async {
    if (_selectedCountryOption == null ||
        _selectedStateOption == null ||
        _loadingCities ||
        _cities.isEmpty) {
      return;
    }
    final picked = await _showSearchableSheet<ReferenceOption>(
      title: 'Select City',
      items: _cities,
      labelFor: (item) => item.label,
    );
    if (picked == null) return;
    updateLocalUiState(this, () {
      _selectedCityOption = picked;
      _cityController.text = picked.label;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    _saveToken?.cancel('Restart edit profile save');
    final token = AppCancellationHandle();
    _saveToken = token;

    if (!mounted) return;
    updateLocalUiState(this, () {
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
        'addressLine': _addressController.text.trim(),
      if ((_selectedStateOption?.value ?? _stateController.text.trim())
          .isNotEmpty)
        'stateCode':
            _selectedStateOption?.value ?? _stateController.text.trim(),
      if ((_selectedCountryOption?.isoCode ?? _countryController.text.trim())
          .isNotEmpty)
        'countryCode':
            _selectedCountryOption?.isoCode ?? _countryController.text.trim(),
      if ((_selectedCityOption?.label ?? _cityController.text.trim())
          .isNotEmpty)
        'cityName': _selectedCityOption?.label ?? _cityController.text.trim(),
      if (_pincodeController.text.trim().isNotEmpty)
        'pincode': _pincodeController.text.trim(),
    };

    final result = await _repo.updateMyProfile(
      payload,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        updateLocalUiState(this, () => _saving = false);
        OpenVtsFeedback.success(context, 'Profile updated');
        Navigator.pop(context, true);
      },
      failure: (error) {
        updateLocalUiState(this, () => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final msg = LegacyErrorPresenter.isApiFailure(error) && LegacyErrorPresenter.message(error).trim().isNotEmpty
            ? LegacyErrorPresenter.message(error)
            : "Couldn't update profile.";
        OpenVtsFeedback.error(context, msg);
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
                    style: AppFonts.inter(
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
                style: AppFonts.inter(
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
                      OpenVtsTextField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OpenVtsTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: colorScheme.primary,
                          size: 22,
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
                                  updateLocalUiState(this, () {
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
                                    fillColor: colorScheme
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
                                    style: AppFonts.inter(fontSize: 16),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OpenVtsTextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              hintText: 'Phone Number',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OpenVtsTextField(
                        controller: _addressController,
                        hintText: 'Address',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OpenVtsTextField(
                        controller: _countryController,
                        readOnly: true,
                        onTap: _pickCountry,
                        hintText: _loadingCountries
                            ? 'Loading countries...'
                            : 'Select country',
                        prefixIcon: Icon(
                          Icons.public,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        suffixIcon: Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OpenVtsTextField(
                              controller: _stateController,
                              readOnly: true,
                              onTap: _pickState,
                              hintText: _loadingStates
                                  ? 'Loading states...'
                                  : 'Select state',
                              prefixIcon: Icon(
                                Icons.flag_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              suffixIcon: Icon(
                                Icons.keyboard_arrow_down,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OpenVtsTextField(
                              controller: _cityController,
                              readOnly: true,
                              onTap: _pickCity,
                              hintText: _loadingCities
                                  ? 'Loading cities...'
                                  : 'Select city',
                              prefixIcon: Icon(
                                Icons.location_city_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              suffixIcon: Icon(
                                Icons.keyboard_arrow_down,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OpenVtsTextField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        hintText: 'Pincode',
                        prefixIcon: Icon(
                          Icons.pin_drop_outlined,
                          color: colorScheme.primary,
                          size: 22,
                        ),
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
                                    style: AppFonts.inter(
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
