import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_profile_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminEditCompanyScreen extends StatefulWidget {
  final AdminProfile profile;

  const AdminEditCompanyScreen({super.key, required this.profile});

  @override
  State<AdminEditCompanyScreen> createState() => _AdminEditCompanyScreenState();
}

class _AdminEditCompanyScreenState extends State<AdminEditCompanyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _customDomainController = TextEditingController();
  final TextEditingController _primaryColorController = TextEditingController();
  final Map<String, TextEditingController> _socialControllers =
      <String, TextEditingController>{};
  final List<String> _socialOptions = const <String>[
    'facebook',
    'instagram',
    'linkedin',
    'twitter',
    'youtube',
    'website',
  ];
  String _selectedSocial = 'facebook';

  bool _saving = false;
  bool _errorShown = false;
  CancelToken? _saveToken;
  CancelToken? _loadToken;

  ApiClient? _api;
  AdminProfileRepository? _repo;

  @override
  void initState() {
    super.initState();
    _hydrateFromProfile();
    _loadCompanyDetails();
  }

  @override
  void dispose() {
    _saveToken?.cancel('EditCompanyScreen disposed');
    _loadToken?.cancel('EditCompanyScreen disposed');
    _nameController.dispose();
    _websiteController.dispose();
    _customDomainController.dispose();
    _primaryColorController.dispose();
    for (final c in _socialControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrateFromProfile() {
    final p = widget.profile.data;
    _hydrateFromMap(p);
  }

  void _hydrateFromMap(Map<String, dynamic> p) {
    Map<String, dynamic>? companyFromList;
    final companies = p['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      companyFromList = Map<String, dynamic>.from(
        (companies.first as Map).cast(),
      );
    }

    final merged = <String, dynamic>{
      ...p,
      if (companyFromList != null) ...companyFromList,
      if (p['company'] is Map)
        ...Map<String, dynamic>.from((p['company'] as Map).cast()),
    };

    _nameController.text = _valueFromKeys(
      merged,
      const ['companyName', 'name', 'company'],
    );
    _websiteController.text = _valueFromKeys(
      merged,
      const ['websiteUrl', 'website', 'customDomain', 'custom_domain'],
    );
    _customDomainController.text = _valueFromKeys(
      merged,
      const ['customDomain', 'custom_domain', 'domain'],
    );
    _primaryColorController.text = _valueFromKeys(
      merged,
      const ['primaryColor', 'primary_color', 'brandColor', 'brand_color'],
    );
    final social = _socialMap(merged);
    for (final entry in social.entries) {
      final key = entry.key.trim().toLowerCase();
      final value = entry.value.trim();
      if (key.isEmpty || value.isEmpty) continue;
      final existing = _socialControllers[key];
      if (existing != null) {
        existing.text = value;
      } else {
        _socialControllers[key] = TextEditingController(text: value);
      }
    }
    if (_socialControllers.isNotEmpty) {
      _selectedSocial = _socialControllers.keys.first;
    }
  }

  void _ensureRepo() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminProfileRepository(api: _api!);
  }

  String _valueFromKeys(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final raw = map[key];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isNotEmpty) return text;
    }
    final company = map['company'];
    if (company is Map) {
      final nested = Map<String, dynamic>.from(company.cast());
      for (final key in keys) {
        final raw = nested[key];
        if (raw == null) continue;
        final text = raw.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    final companies = map['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      final first = Map<String, dynamic>.from((companies.first as Map).cast());
      for (final key in keys) {
        final raw = first[key];
        if (raw == null) continue;
        final text = raw.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  Map<String, String> _socialMap(Map<String, dynamic> map) {
    final out = <String, String>{};

    void absorb(Object? source) {
      if (source is! Map) return;
      final m = Map<String, dynamic>.from(source.cast());
      m.forEach((k, v) {
        final key = k.toString().trim().toLowerCase();
        final value = v?.toString().trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          out[key] = value;
        }
      });
    }

    absorb(map['socialLinks']);
    final company = map['company'];
    if (company is Map) {
      absorb(company['socialLinks']);
    }
    final companies = map['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      absorb((companies.first as Map)['socialLinks']);
    }
    if ((map['facebook']?.toString().trim().isNotEmpty ?? false)) {
      out['facebook'] = map['facebook'].toString().trim();
    }
    return out;
  }

  String _normalizeUrl(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    final withoutTrailing = text.replaceFirst(RegExp(r'/+$'), '');
    if (withoutTrailing.startsWith('http://') ||
        withoutTrailing.startsWith('https://')) {
      return withoutTrailing;
    }
    return 'https://$withoutTrailing';
  }

  Future<void> _openSocialPicker() async {
    final colorScheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              ..._socialOptions.map(
                (e) => ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    e[0].toUpperCase() + e.substring(1),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: _selectedSocial == e
                      ? Icon(Icons.check_rounded, color: colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(e),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedSocial = picked);
  }

  Future<void> _loadCompanyDetails() async {
    final adminId = widget.profile.id.trim();
    if (adminId.isEmpty) return;
    _ensureRepo();
    _loadToken?.cancel('Reload company details');
    final token = CancelToken();
    _loadToken = token;
    try {
      final res = await _repo!.getMyProfile(cancelToken: token);
      if (!mounted) return;
      res.when(
        success: (profile) => _hydrateFromMap(profile.data),
        failure: (_) {},
      );
    } catch (_) {
      // Keep existing pre-filled data; silent failure.
    }
  }

  String _companyId() {
    final p = widget.profile.data;
    final companies = p['companies'];
    final Map<String, dynamic>? firstCompany =
        companies is List && companies.isNotEmpty && companies.first is Map
        ? Map<String, dynamic>.from((companies.first as Map).cast())
        : null;
    final candidates = [
      firstCompany?['id'],
      firstCompany?['companyId'],
      firstCompany?['company_id'],
      firstCompany?['companyConfigId'],
      firstCompany?['company_config_id'],
      p['companyId'],
      p['company_id'],
      p['companyID'],
      p['companyConfigId'],
      p['company_config_id'],
      p['company'] is Map ? (p['company'] as Map)['id'] : null,
      p['company'] is Map ? (p['company'] as Map)['companyId'] : null,
      p['company'] is Map ? (p['company'] as Map)['company_id'] : null,
      p['company'] is Map ? (p['company'] as Map)['companyConfigId'] : null,
      p['company'] is Map ? (p['company'] as Map)['company_config_id'] : null,
      p['id'],
      p['uid'],
      widget.profile.id,
    ];
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final text = candidate.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  void _snackOnce(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_saving) return;

    final companyId = _companyId();
    final name = _nameController.text.trim();
    final websiteUrl = _normalizeUrl(_websiteController.text);
    final customDomain = _normalizeUrl(_customDomainController.text);
    final primaryColor = _primaryColorController.text.trim().isEmpty
        ? 'Black'
        : _primaryColorController.text.trim();

    if (companyId.isEmpty) {
      _snackOnce('Company id not available.');
      return;
    }
    if (name.isEmpty) {
      _snackOnce('Company name is required.');
      return;
    }

    final socialLinks = <String, dynamic>{};
    for (final entry in _socialControllers.entries) {
      final value = _normalizeUrl(entry.value.text);
      if (value.isNotEmpty) {
        socialLinks[entry.key] = value;
      }
    }

    _ensureRepo();
    _saveToken?.cancel('Edit company resubmit');
    _saveToken = CancelToken();

    if (!mounted) return;
    setState(() {
      _saving = true;
      _errorShown = false;
    });

    try {
      final payload = <String, dynamic>{
        'name': name,
        if (websiteUrl.isNotEmpty) 'websiteUrl': websiteUrl,
        if (customDomain.isNotEmpty) 'customDomain': customDomain,
        'primaryColor': primaryColor,
        if (socialLinks.isNotEmpty) 'socialLinks': socialLinks,
      };

      final res = await _repo!.updateCompanyDetails(
        companyId,
        payload,
        cancelToken: _saveToken,
      );

      if (!mounted) return;

      res.when(
        success: (_) {
          setState(() => _saving = false);
          _snackOnce('Company updated');
          Navigator.pop(context, true);
        },
        failure: (err) {
          setState(() => _saving = false);
          if (_errorShown) return;
          _errorShown = true;
          final message =
              err is ApiException && err.message.trim().isNotEmpty
              ? err.message
              : "Couldn't update company.";
          _snackOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (_errorShown) return;
      _errorShown = true;
      _snackOnce("Couldn't update company.");
    }
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
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
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
                    'Edit Company',
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
                'Update company details',
                style: GoogleFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: 'Company Name',
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.apartment_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: 'Website URL',
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.language_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customDomainController,
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        decoration: _minimalDecoration(
                          context,
                          hint: 'Custom Domain',
                        ).copyWith(
                          prefixIcon: Icon(
                            Icons.dns_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _openSocialPicker,
                              child: InputDecorator(
                                decoration: _minimalDecoration(
                                  context,
                                  hint: 'Select Social Platform',
                                ).copyWith(
                                  prefixIcon: Icon(
                                    Icons.public_outlined,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.expand_more_rounded,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.65,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _selectedSocial[0].toUpperCase() +
                                      _selectedSocial.substring(1),
                                  style: GoogleFonts.roboto(
                                    fontSize: labelSize,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              if (_socialControllers.containsKey(_selectedSocial)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${_selectedSocial[0].toUpperCase()}${_selectedSocial.substring(1)} already added.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _socialControllers[_selectedSocial] =
                                    TextEditingController();
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add,
                                color: colorScheme.onPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._socialControllers.entries.map((entry) {
                        final key = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.url,
                                  style: GoogleFonts.roboto(
                                    fontSize: labelSize,
                                    color: colorScheme.onSurface,
                                  ),
                                  decoration: _minimalDecoration(
                                    context,
                                    hint:
                                        '${key[0].toUpperCase()}${key.substring(1)} URL',
                                  ).copyWith(
                                    prefixIcon: Icon(
                                      Icons.link_rounded,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _socialControllers.remove(key);
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _saving ? null : _submit,
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
