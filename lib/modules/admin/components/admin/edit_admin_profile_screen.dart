// components/admin/edit_admin_profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_profile_repository.dart';
import 'package:fleet_stack/core/repositories/admin_repository.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key, this.initialProfile});

  final AdminProfile? initialProfile;

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

  CountryOption? _selectedCountryOption;
  ReferenceOption? _selectedStateOption;
  ReferenceOption? _selectedCityOption;
  List<CountryOption> _countries = const [];
  List<ReferenceOption> _states = const [];
  List<ReferenceOption> _cities = const [];
  List<MobilePrefixOption> _prefixes = const [];
  MobilePrefixOption? _selectedPrefix;
  String? _imageUrl;
  String _authToken = '';
  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _loadingPrefixes = false;
  bool _submitting = false;
  bool _uploadingImage = false;
  CancelToken? _submitToken;
  CancelToken? _countriesToken;
  CancelToken? _statesToken;
  CancelToken? _citiesToken;
  CancelToken? _prefixesToken;
  CancelToken? _imageToken;

  ApiClient? _api;
  CommonRepository? _commonRepo;
  AdminProfileRepository? _profileRepo;
  AdminRepository? _adminRepo;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile != null) {
      _applyProfile(profile);
    }
    _loadCountries();
    _loadPrefixes();
    _loadCurrentProfile();
  }

  void _applyProfile(AdminProfile profile) {
    _nameController.text = profile.fullName;
    _emailController.text = profile.email;
    _phoneController.text = profile.mobileNumber;
    _addressController.text = profile.addressLine;
    _stateController.text = profile.state;
    _countryController.text = profile.country;
    _cityController.text = profile.city;
    _pincodeController.text = profile.pincode;
    _imageUrl = _extractProfileImageUrl(profile);

    if (_countries.isNotEmpty && profile.country.isNotEmpty) {
      for (final c in _countries) {
        if (c.isoCode.toUpperCase() == profile.country.toUpperCase() ||
            c.name.toLowerCase() == profile.country.toLowerCase()) {
          _selectedCountryOption = c;
          break;
        }
      }
    }

    if (_prefixes.isNotEmpty && profile.mobilePrefix.isNotEmpty) {
      final pref = profile.mobilePrefix.startsWith('+')
          ? profile.mobilePrefix.substring(1)
          : profile.mobilePrefix;
      for (final p in _prefixes) {
        if (p.code == pref || p.code == profile.mobilePrefix) {
          _selectedPrefix = p;
          break;
        }
      }
    }
  }

  Future<void> _loadCurrentProfile() async {
    _ensureRepo();
    _authToken = await TokenStorage.defaultInstance().readAccessToken() ?? '';
    final res = await _profileRepo!.getMyProfile();
    if (!mounted) return;
    res.when(
      success: (profile) {
        setState(() {
          _applyProfile(profile);
        });

        _syncCountryStateCityFromLists();

        if (_selectedCountryOption != null) {
          _loadStates(_selectedCountryOption!.isoCode);
        }
      },
      failure: (_) {},
    );
  }

  String _buildAbsoluteUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    final base = AppConfig.fromDartDefine().baseUrl.trim();
    if (base.isEmpty) return text;
    if (text.startsWith('/')) return '$base$text';
    return '$base/$text';
  }

  String _extractProfileImageUrl(dynamic profile) {
    if (profile == null) return '';
    final raw = profile.raw as Map<String, dynamic>;
    final List<Map<String, dynamic>> sources = [];
    sources.add(raw);
    final level1 = raw['data'];
    if (level1 is Map) {
      final m1 = Map<String, dynamic>.from(level1.cast());
      sources.add(m1);
      final level2 = m1['data'];
      if (level2 is Map) {
        sources.add(Map<String, dynamic>.from(level2.cast()));
      }
    }
    const keys = [
      'profileUrl',
      'profileurl',
      'profile_url',
      'avatarUrl',
      'avatar_url',
      'avatar',
      'photoUrl',
      'photo_url',
      'imageUrl',
      'image_url',
      'profileImage',
      'profile_image',
    ];
    for (final map in sources) {
      for (final key in keys) {
        final v = map[key];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isEmpty) continue;
        return _buildAbsoluteUrl(s);
      }
    }
    return '';
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadingImage) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    _ensureRepo();
    _imageToken?.cancel();
    _imageToken = CancelToken();

    setState(() => _uploadingImage = true);

    try {
      final res = await _adminRepo!.uploadAdminFile(
        type: 'profile',
        bytes: bytes,
        filename: file.name,
        contentType: 'image/${file.extension ?? 'jpeg'}',
        cancelToken: _imageToken,
      );

      if (!mounted) return;

      res.when(
        success: (url) {
          setState(() {
            _imageUrl = url;
            _uploadingImage = false;
          });
          _snackOnce('Profile picture updated');
        },
        failure: (_) {
          setState(() => _uploadingImage = false);
          _snackOnce("Couldn't upload image");
        },
      );
    } catch (_) {
      if (mounted) setState(() => _uploadingImage = false);
      _snackOnce('Error uploading image');
    }
  }

  Future<void> _deleteImage() async {
    if (_imageUrl == null || _imageUrl!.isEmpty) return;
    setState(() => _imageUrl = null);
    _snackOnce('Profile picture removed (UI only for now)');
  }

  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
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

  @override
  void dispose() {
    _countriesToken?.cancel('dispose');
    _statesToken?.cancel('dispose');
    _citiesToken?.cancel('dispose');
    _prefixesToken?.cancel('dispose');
    _submitToken?.cancel('dispose');
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

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo = CommonRepository(api: _api!);
    _profileRepo = AdminProfileRepository(api: _api!);
    _adminRepo = AdminRepository(api: _api!);
  }

  void _snackOnce(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _mobilePrefix() {
    final selected = _selectedPrefix?.code.trim() ?? '';
    if (selected.isNotEmpty) {
      return selected.startsWith('+') ? selected : '+$selected';
    }
    return '+91';
  }

  String _countryCode() {
    final code = _selectedCountryOption?.isoCode;
    if (code != null && code.trim().isNotEmpty) return code.trim().toUpperCase();
    final cc = _countryController.text.trim();
    if (cc.isNotEmpty) return cc.toUpperCase();
    return '';
  }

  String _stateCode() {
    final value = _selectedStateOption?.value;
    if (value != null && value.trim().isNotEmpty) return value.trim();
    return _stateController.text.trim();
  }

  String _cityName() {
    final label = _selectedCityOption?.label;
    if (label != null && label.trim().isNotEmpty) return label.trim();
    return _cityController.text.trim();
  }

  Future<void> _loadCountries() async {
    _countriesToken?.cancel('Reload countries');
    final token = CancelToken();
    _countriesToken = token;
    setState(() => _loadingCountries = true);

    _ensureRepo();
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
        final shouldSelectDefault =
            _selectedCountryOption == null && india != null;

        setState(() {
          _countries = items;
          _loadingCountries = false;
          if (shouldSelectDefault) {
            _selectedCountryOption = india;
            _countryController.text = india.name;
          }
        });

        if (shouldSelectDefault) {
          _loadStates(india.isoCode);
        }

        _loadCurrentProfile();
      },
      failure: (_) {
        setState(() => _loadingCountries = false);
      },
    );
  }

  Future<void> _loadPrefixes() async {
    _prefixesToken?.cancel('Reload prefixes');
    final token = CancelToken();
    _prefixesToken = token;
    setState(() => _loadingPrefixes = true);

    _ensureRepo();
    final res = await _commonRepo!.getMobilePrefixes(cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _prefixes = items;
          _loadingPrefixes = false;
        });
        _loadCurrentProfile();
      },
      failure: (_) {
        setState(() => _loadingPrefixes = false);
      },
    );
  }

  void _setDefaultPrefixForCountry(String countryCode) {
    final code = countryCode.trim().isEmpty
        ? 'IN'
        : countryCode.trim().toUpperCase();
    if (_prefixes.isEmpty) return;
    final match = _prefixes.firstWhere(
      (p) => p.countryCode.toUpperCase() == code,
      orElse: () => _prefixes.first,
    );
    setState(() => _selectedPrefix = match);
  }

  Future<void> _loadStates(String countryCode) async {
    _statesToken?.cancel('Reload states');
    final token = CancelToken();
    _statesToken = token;
    setState(() => _loadingStates = true);

    _ensureRepo();
    final res = await _commonRepo!.getStates(countryCode, cancelToken: token);
    if (!mounted) return;
    res.when(
      success: (items) {
        setState(() {
          _states = items;
          _loadingStates = false;
        });
        _syncStateFromList();
        if (_selectedStateOption != null &&
            _cityController.text.trim().isNotEmpty) {
          _loadCities(_countryCode(), _selectedStateOption!.value);
        }
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

    _ensureRepo();
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
        _syncCityFromList();
      },
      failure: (_) {
        setState(() => _loadingCities = false);
      },
    );
  }

  void _syncCountryStateCityFromLists() {
    if (_selectedCountryOption != null) {
      _countryController.text = _selectedCountryOption!.name;
    }
    _syncStateFromList();
    _syncCityFromList();
  }

  void _syncStateFromList() {
    if (_states.isEmpty) return;
    final raw = _stateController.text.trim();
    if (raw.isEmpty) return;
    ReferenceOption? match;
    for (final s in _states) {
      if (s.value.toLowerCase() == raw.toLowerCase() ||
          s.label.toLowerCase() == raw.toLowerCase()) {
        match = s;
        break;
      }
    }
    if (match == null) return;
    _selectedStateOption = match;
    _stateController.text = match.label;
  }

  void _syncCityFromList() {
    if (_cities.isEmpty) return;
    final raw = _cityController.text.trim();
    if (raw.isEmpty) return;
    ReferenceOption? match;
    for (final c in _cities) {
      if (c.label.toLowerCase() == raw.toLowerCase() ||
          c.value.toLowerCase() == raw.toLowerCase()) {
        match = c;
        break;
      }
    }
    if (match == null) return;
    _selectedCityOption = match;
    _cityController.text = match.label;
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
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant
                              .withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            final trailing = trailingFor?.call(item);
                            return ListTile(
                              title: Text(
                                labelFor(item),
                                style: GoogleFonts.roboto(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: trailing == null
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

  Future<void> _pickCountry() async {
    if (_loadingCountries) return;
    if (_countries.isEmpty) {
      _snackOnce('No countries available.');
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
    if (_prefixes.isNotEmpty) {
      _setDefaultPrefixForCountry(picked.isoCode);
    }
  }

  Future<void> _pickPrefix() async {
    if (_loadingPrefixes) return;
    if (_prefixes.isEmpty) {
      _snackOnce('No mobile prefixes available.');
      return;
    }
    final picked = await _showSearchableSheet<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: _prefixes,
      labelFor: (item) {
        final code = item.code.startsWith('+') ? item.code : '+${item.code}';
        return '$code · ${item.countryCode}';
      },
    );
    if (picked == null) return;
    setState(() => _selectedPrefix = picked);
  }

  Future<void> _pickState() async {
    if (_selectedCountryOption == null) {
      _snackOnce('Select a country first.');
      return;
    }
    if (_loadingStates) return;
    if (_states.isEmpty) {
      _snackOnce('No states available.');
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
    await _loadCities(_countryCode(), picked.value);
  }

  Future<void> _pickCity() async {
    if (_selectedStateOption == null || _selectedCountryOption == null) {
      _snackOnce('Select a country and state first.');
      return;
    }
    if (_loadingCities) return;
    if (_cities.isEmpty) {
      _snackOnce('No cities available.');
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

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _snackOnce('Please fill in name, email, and phone.');
      return;
    }
    if (!email.contains('@')) {
      _snackOnce('Please enter a valid email.');
      return;
    }

    _ensureRepo();

    _submitToken?.cancel('resubmit');
    _submitToken = CancelToken();

    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'mobilePrefix': _mobilePrefix(),
        'mobileNumber': phone,
        'addressLine': _addressController.text.trim(),
        'countryCode': _countryCode(),
        'stateCode': _stateCode(),
        'cityName': _cityName(),
        'pincode': _pincodeController.text.trim(),
      };

      final res = await _profileRepo!.updateMyProfile(
        payload,
        cancelToken: _submitToken,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        _snackOnce('Profile updated');
        Navigator.pop(context, true);
        return;
      }

      final err = res.error;
      if (err is ApiException &&
          (err.statusCode == 401 || err.statusCode == 403)) {
        _snackOnce('Not authorized to update profile.');
      } else {
        _snackOnce("Couldn't update profile.");
      }
    } catch (_) {
      if (!mounted) return;
      _snackOnce("Couldn't update profile.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                    'Edit Admin Profile',
                    style: GoogleFonts.roboto(
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
                'Update admin details',
                style: GoogleFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _uploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : (_imageUrl != null && _imageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _imageUrl!,
                                    fit: BoxFit.cover,
                                    httpHeaders: _authToken.isNotEmpty
                                        ? {'Authorization': 'Bearer $_authToken'}
                                        : null,
                                    placeholder: (_, __) => const AppShimmer(
                                      width: 100,
                                      height: 100,
                                      radius: 50,
                                    ),
                                    errorWidget: (_, __, ___) => Center(
                                      child: Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0]
                                                .toUpperCase()
                                            : 'A',
                                        style: GoogleFonts.roboto(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text[0].toUpperCase()
                                          : 'A',
                                      style: GoogleFonts.roboto(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_imageUrl != null && _imageUrl!.isNotEmpty)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _deleteImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: 'Full Name',
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
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(context, hint: 'Email')
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
                            onTap: _pickPrefix,
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
                                  Text(
                                    (_selectedPrefix?.code ?? '+91')
                                            .startsWith('+')
                                        ? (_selectedPrefix?.code ?? '+91')
                                        : '+${_selectedPrefix?.code ?? '91'}',
                                    style: GoogleFonts.roboto(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
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
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration: _minimalDecoration(
                                context,
                                hint: 'Phone Number',
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
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration:
                            _minimalDecoration(
                              context,
                              hint: 'Address Line',
                            ).copyWith(
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
                              readOnly: true,
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'Country Code',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.public,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _pickCountry,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _stateController,
                              readOnly: true,
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'State',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.flag_outlined,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _pickState,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
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
                              readOnly: true,
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'City',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.location_city_outlined,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _pickCity,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                color: colorScheme.onSurface,
                              ),
                              decoration:
                                  _minimalDecoration(
                                    context,
                                    hint: 'Pincode',
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
                        onTap: _submitting ? null : _submit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _submitting
                                ? const AppShimmer(
                                    width: 18,
                                    height: 18,
                                    radius: 9,
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.roboto(
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
