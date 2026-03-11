import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/api_config_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiConfigSettingsScreen extends StatelessWidget {
  const ApiConfigSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "API Configuration",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApiConfigHeader(),

            const SizedBox(height: 24),

            // You can add more boxes here like profile screen
          ],
        ),
      ),
    );
  }
}

class ApiConfigHeader extends StatefulWidget {
  const ApiConfigHeader({super.key});

  @override
  State<ApiConfigHeader> createState() => _ApiConfigHeaderState();
}

class _ApiConfigHeaderState extends State<ApiConfigHeader> {
  // Postman-confirmed endpoints:
  // - GET /superadmin/softwareconfig
  // - PATCH /superadmin/softwareconfig
  // No dedicated test endpoints found for Firebase/Geocoding/SSO/OpenAI tests.
  bool firebaseEnabled = false;
  bool geoEnabled = false;
  String selectedProvider = "OSM Nominatim(FREE - No key)";
  bool providerActive = false;
  bool ssoEnabled = false;
  bool openAiEnabled = false;
  String selectedModel = "GPT-4 TURBO (Recommended)";
  int maxTokens = 2048;
  final TextEditingController firebaseApiKeyController =
      TextEditingController();
  final TextEditingController firebaseAuthDomainController =
      TextEditingController();
  final TextEditingController firebaseProjectIdController =
      TextEditingController();
  final TextEditingController firebaseStorageBucketController =
      TextEditingController();
  final TextEditingController firebaseMessagingSenderIdController =
      TextEditingController();
  final TextEditingController firebaseAppIdController = TextEditingController();
  final TextEditingController firebaseMeasurementIdController =
      TextEditingController();
  final TextEditingController reverseGeoApiKeyController =
      TextEditingController();
  final TextEditingController userAgentController = TextEditingController();
  final TextEditingController googleClientIdController =
      TextEditingController();
  final TextEditingController googleClientSecretController =
      TextEditingController();
  final TextEditingController googleRedirectUrlController =
      TextEditingController();
  final TextEditingController openAiApiKeyController = TextEditingController();
  final TextEditingController openAiOrgIdController = TextEditingController();
  bool _loadingConfig = false;
  bool _saving = false;
  bool _testFirebaseLoading = false;
  bool _testGeoLoading = false;
  bool _testSsoLoading = false;
  bool _testOpenAiLoading = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  bool _testUnavailableShown = false;
  DateTime? _lastSaveAt;
  CancelToken? _loadToken;
  CancelToken? _saveToken;
  CancelToken? _testToken;
  ApiClient? _api;
  ApiConfigRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadApiConfig();
  }

  @override
  void dispose() {
    _loadToken?.cancel('ApiConfig disposed');
    _saveToken?.cancel('ApiConfig disposed');
    _testToken?.cancel('ApiConfig disposed');
    firebaseApiKeyController.dispose();
    firebaseAuthDomainController.dispose();
    firebaseProjectIdController.dispose();
    firebaseStorageBucketController.dispose();
    firebaseMessagingSenderIdController.dispose();
    firebaseAppIdController.dispose();
    firebaseMeasurementIdController.dispose();
    reverseGeoApiKeyController.dispose();
    userAgentController.dispose();
    googleClientIdController.dispose();
    googleClientSecretController.dispose();
    googleRedirectUrlController.dispose();
    openAiApiKeyController.dispose();
    openAiOrgIdController.dispose();
    super.dispose();
  }

  ApiConfigRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= ApiConfigRepository(api: _api!);
    return _repo!;
  }

  String _providerApiValue(String label) {
    if (label.startsWith('Google')) return 'Google';
    if (label.startsWith('HERE')) return 'HERE';
    if (label.startsWith('TomTom')) return 'TomTom';
    if (label.startsWith('MapBox')) return 'Mapbox';
    if (label.startsWith('Location IQ')) return 'LocationIQ';
    return 'OSM';
  }

  String _providerUiValue(String apiValue) {
    final p = apiValue.trim().toLowerCase();
    if (p == 'google') return "Google map (Paid - 5\$/100req)";
    if (p == 'here') return "HERE Map(FREE - 250K/Month)";
    if (p == 'tomtom') return "TomTom(FREE - 250o/day)";
    if (p == 'mapbox') return "MapBox(FREE - 100/Month)";
    if (p == 'locationiq') return "Location IQ(FREE - 1000/day)";
    return "OSM Nominatim(FREE - No key)";
  }

  String _openAiUiModel(String apiModel) {
    final m = apiModel.trim().toLowerCase();
    if (m == 'gpt-4') return 'GPT-4';
    return 'GPT-4 TURBO (Recommended)';
  }

  String _openAiApiModel(String uiModel) {
    if (uiModel.trim() == 'GPT-4') return 'gpt-4';
    return 'gpt-4o';
  }

  Object? _pickRaw(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  String _pickString(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    return value == null ? '' : value.toString().trim();
  }

  bool? _pickBool(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    if (value == null) return null;
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  Future<void> _loadApiConfig() async {
    _loadToken?.cancel('Reload software config');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingConfig = true);

    try {
      final res = await _repoOrCreate().getSoftwareConfig(cancelToken: token);
      if (!mounted) return;
      res.when(
        success: (cfg) {
          setState(() {
            _loadingConfig = false;
            _loadErrorShown = false;
            firebaseEnabled =
                _pickBool(cfg, [
                  'firebaseEnabled',
                  'firebaseConfigEnabled',
                  'isFirebaseEnabled',
                ]) ??
                false;

            geoEnabled =
                _pickBool(cfg, ['geocodingEnabled', 'isReverseGeoEnabled']) ??
                false;

            providerActive =
                _pickBool(cfg, [
                  'geocodingProviderActive',
                  'reverseGeoProviderActive',
                  'providerActive',
                ]) ??
                false;

            ssoEnabled =
                _pickBool(cfg, ['googleSsoEnabled', 'isGoogleSsoEnabled']) ??
                false;

            openAiEnabled =
                _pickBool(cfg, ['openaiEnabled', 'isOpenAiEnabled']) ?? false;

            firebaseApiKeyController.text = _pickString(cfg, [
              'firebaseApiKey',
              'apiKey',
            ]);

            firebaseAuthDomainController.text = _pickString(cfg, [
              'firebaseAuthDomain',
              'authDomain',
            ]);

            firebaseProjectIdController.text = _pickString(cfg, [
              'firebaseProjectId',
              'projectId',
            ]);

            firebaseStorageBucketController.text = _pickString(cfg, [
              'firebaseStorageBucket',
              'storageBucket',
            ]);

            firebaseMessagingSenderIdController.text = _pickString(cfg, [
              'firebaseMessagingSenderId',
              'messagingSenderId',
            ]);

            firebaseAppIdController.text = _pickString(cfg, [
              'firebaseAppId',
              'appId',
            ]);

            firebaseMeasurementIdController.text = _pickString(cfg, [
              'firebaseMeasurementId',
              'measurementId',
            ]);

            final provider = _pickString(cfg, [
              'geocodingProvider',
              'reverseGeoProvider',
            ]);
            selectedProvider = provider.isEmpty
                ? "OSM Nominatim(FREE - No key)"
                : _providerUiValue(provider);

            userAgentController.text = _pickString(cfg, [
              'geocodingUserAgent',
              'userAgent',
            ]);

            reverseGeoApiKeyController.text = _pickString(cfg, [
              'reverseGeoApiKey',
              'geocodingApiKey',
            ]);

            googleClientIdController.text = _pickString(cfg, [
              'googleClientId',
            ]);
            googleClientSecretController.text = _pickString(cfg, [
              'googleClientSecret',
            ]);
            googleRedirectUrlController.text = _pickString(cfg, [
              'googleRedirectUrl',
              'googleRedirectUri',
            ]);

            openAiApiKeyController.text = _pickString(cfg, [
              'openaiApiKey',
              'openAiApiKey',
            ]);

            openAiOrgIdController.text = _pickString(cfg, [
              'openaiOrgId',
              'openAiOrgId',
            ]);

            final openAiModel = _pickString(cfg, [
              'openaiModel',
              'openAiModel',
            ]);
            selectedModel = openAiModel.isEmpty
                ? 'GPT-4 TURBO (Recommended)'
                : _openAiUiModel(openAiModel);

            final tokenLimit = _pickInt(cfg, [
              'openaiMaxTokens',
              'openAiMaxTokens',
              'maxTokens',
            ]);
            maxTokens =
                (tokenLimit != null && tokenLimit >= 1 && tokenLimit <= 4096)
                ? tokenLimit
                : 2048;
          });
        },
        failure: (err) {
          setState(() => _loadingConfig = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view API config.'
              : "Couldn't load API config.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingConfig = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load API config.")),
      );
    }
  }

  Future<bool> _saveApiConfig({bool showSuccess = true}) async {
    if (_saving) return false;
    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) {
      return false;
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry save api config');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return false;
    setState(() {
      _saving = true;
    });

    final payload = <String, dynamic>{
      'firebaseEnabled': firebaseEnabled,
      'firebaseApiKey': firebaseApiKeyController.text.trim(),
      'firebaseAuthDomain': firebaseAuthDomainController.text.trim(),
      'firebaseProjectId': firebaseProjectIdController.text.trim(),
      'firebaseStorageBucket': firebaseStorageBucketController.text.trim(),
      'firebaseMessagingSenderId': firebaseMessagingSenderIdController.text
          .trim(),
      'firebaseAppId': firebaseAppIdController.text.trim(),
      'firebaseMeasurementId': firebaseMeasurementIdController.text.trim(),
      'geocodingEnabled': geoEnabled,
      'geocodingProvider': _providerApiValue(selectedProvider),
      'geocodingUserAgent': userAgentController.text.trim(),
      'geocodingProviderActive': providerActive,
      'googleSsoEnabled': ssoEnabled,
      'googleClientId': googleClientIdController.text.trim(),
      'googleClientSecret': googleClientSecretController.text.trim(),
      'googleRedirectUrl': googleRedirectUrlController.text.trim(),
      'openaiEnabled': openAiEnabled,
      'openaiApiKey': openAiApiKeyController.text.trim(),
      'openaiOrgId': openAiOrgIdController.text.trim(),
      'openaiModel': _openAiApiModel(selectedModel),
      'openaiMaxTokens': maxTokens,
      'isOpenAiEnabled': openAiEnabled,
      'openAiApiKey': openAiApiKeyController.text.trim(),
      'openAiModel': _openAiApiModel(selectedModel),
      'isGoogleSsoEnabled': ssoEnabled,
      'googleRedirectUri': googleRedirectUrlController.text.trim(),
      'isReverseGeoEnabled': geoEnabled && providerActive,
      'reverseGeoApiKey': reverseGeoApiKeyController.text.trim(),
      'reverseGeoProvider': _providerApiValue(selectedProvider),
    };

    try {
      final res = await _repoOrCreate().updateSoftwareConfig(
        payload,
        cancelToken: token,
      );
      if (!mounted) return false;
      return res.when(
        success: (_) {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
          });
          if (showSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Saved')));
          }
          return true;
        },
        failure: (err) {
          setState(() => _saving = false);
          if (!_saveErrorShown) {
            _saveErrorShown = true;
            final msg =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to save API config.'
                : "Couldn't save changes.";
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
          return false;
        },
      );
    } catch (_) {
      if (!mounted) return false;
      setState(() => _saving = false);
      if (!_saveErrorShown) {
        _saveErrorShown = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Couldn't save changes.")));
      }
      return false;
    }
  }

  Future<void> _toggleAndPersist({
    required bool currentValue,
    required ValueChanged<bool> setLocalValue,
    required bool nextValue,
  }) async {
    if (_saving) return;
    setState(() => setLocalValue(nextValue));
    final ok = await _saveApiConfig(showSuccess: false);
    if (!ok && mounted) {
      setState(() => setLocalValue(currentValue));
    }
  }

  Future<void> _showUnavailableTest({
    required void Function(bool) setLoading,
  }) async {
    if (!mounted) return;
    setState(() => setLoading(true));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => setLoading(false));
    if (kDebugMode && !_testUnavailableShown) {
      _testUnavailableShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test API not available yet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // -----------------------------------------
              // LEFT TEXTS (MATCH ApiConfig HEADER)
              // -----------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "API Configuration",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Third-Party Integrations",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  if (_loadingConfig)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: AppShimmer(width: 12, height: 12, radius: 6),
                    ),
                ],
              ),

              // -----------------------------------------
              // SAVE BUTTON (MATCHES 'SAVE CHANGES')
              // -----------------------------------------
              ElevatedButton.icon(
                onPressed: (_saving || _loadingConfig)
                    ? null
                    : () => _saveApiConfig(showSuccess: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: hp + 2,
                    vertical: hp - 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: SizedBox(
                  width: AdaptiveUtils.getIconSize(width),
                  height: AdaptiveUtils.getIconSize(width),
                  child: _saving
                      ? AppShimmer(
                          width: AdaptiveUtils.getIconSize(width),
                          height: AdaptiveUtils.getIconSize(width),
                          radius: AdaptiveUtils.getIconSize(width) / 2,
                        )
                      : Icon(
                          Icons.save_outlined,
                          color: colorScheme.onPrimary,
                          size: AdaptiveUtils.getIconSize(width),
                        ),
                ),
                label: Text(
                  "Save All Changes",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (_loadingConfig) ...[
            const SizedBox(height: 24),
            _buildLoadingShimmer(width),
          ] else ...[
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // a bit more breathing room
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== Firebase Configuration Header ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fireplace_rounded,
                            size: AdaptiveUtils.getTitleFontSize(width) + 5,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Firebase Configuration",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: firebaseEnabled,
                          activeColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(
                            0.3,
                          ),
                          onChanged: _saving
                              ? null
                              : (v) => _toggleAndPersist(
                                  currentValue: firebaseEnabled,
                                  nextValue: v,
                                  setLocalValue: (value) =>
                                      firebaseEnabled = value,
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24), // space between the two sections
                  // ==================== Setup Instructions ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ), // a bit more breathing room
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.integration_instructions,
                              size: 22,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Setup Instructions",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    3,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Go to",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(
                              "https://console.firebase.google.com/",
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Text(
                            "Firebase Console",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight
                                  .w600, // a bit bolder so it feels clickable
                              color: colorScheme.primary,
                              //decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "→ Project Settings → General → Your apps → SDK setup and configuration",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // API KEY
                      Text(
                        "API KEY",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseApiKeyController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // AUTH DOMAIN
                      Text(
                        "AUTH DOMAIN",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseAuthDomainController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // PROJECT ID
                      Text(
                        "PROJECT ID",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseProjectIdController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // STORAGE BUCKET
                      Text(
                        "STORAGE BUCKET",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseStorageBucketController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // MESSAGING SENDER ID
                      Text(
                        "MESSAGING SENDER ID",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseMessagingSenderIdController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // APP ID
                      Text(
                        "APP ID",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseAppIdController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // MEASUREMENT ID (Optional)
                      Text(
                        "MEASUREMENT ID (Optional)",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: firebaseMeasurementIdController,
                        decoration: _inputDecoration(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showUnavailableTest(
                      setLoading: (v) => _testFirebaseLoading = v,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Check icon chip
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: _testFirebaseLoading
                                    ? const AppShimmer(
                                        width: 16,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Button Text
                            Text(
                              "Test Connection",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // a bit more breathing room
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== Reverse Geocoding Service Header ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: AdaptiveUtils.getTitleFontSize(width) + 5,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Reverse Geocoding Service",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: geoEnabled,
                          activeColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(
                            0.3,
                          ),
                          onChanged: _saving
                              ? null
                              : (v) => _toggleAndPersist(
                                  currentValue: geoEnabled,
                                  nextValue: v,
                                  setLocalValue: (value) => geoEnabled = value,
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24), // space between the two sections
                  // ==================== Configure Instructions ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ), // a bit more breathing room
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.integration_instructions,
                              size: 22,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Configure Your Geocoding Provider",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getTitleFontSize(width) + 1,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Select a provider, enter credentials, and activate it to start using reverse geocoding services.",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SELECT PROVIDER
                      Text(
                        "SELECT PROVIDER",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: selectedProvider,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          underline: const SizedBox(),
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface,
                            fontSize: AdaptiveUtils.getTitleFontSize(width),
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => selectedProvider = newValue);
                            }
                          },
                          items:
                              <String>[
                                "Google map (Paid - 5\$/100req)",
                                "HERE Map(FREE - 250K/Month)",
                                "TomTom(FREE - 250o/day)",
                                "MapBox(FREE - 100/Month)",
                                "Location IQ(FREE - 1000/day)",
                                "OSM Nominatim(FREE - No key)",
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Selected: $selectedProvider",
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 5,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ==================== Activate Provider ====================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          16,
                        ), // a bit more breathing room
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Activate Provider",
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(
                                          width,
                                        ) -
                                        3,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.87,
                                    ),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.7,
                                  child: Switch(
                                    value: providerActive,
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onPrimary,
                                    inactiveTrackColor: colorScheme.primary
                                        .withOpacity(0.3),
                                    onChanged: _saving
                                        ? null
                                        : (v) => _toggleAndPersist(
                                            currentValue: providerActive,
                                            nextValue: v,
                                            setLocalValue: (value) =>
                                                providerActive = value,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              providerActive
                                  ? "This provider is now active and handling all reverse geocoding requests."
                                  : "Activate this provider to begin using it for reverse geocoding.",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    5,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ==================== Provider Documentation & Setup ====================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          16,
                        ), // a bit more breathing room
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.integration_instructions,
                                  size: 22,
                                  color: colorScheme.onSurface.withOpacity(
                                    0.87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Provider Documentation & Setup",
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(
                                          width,
                                        ) -
                                        3,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8, // space between items
                              runSpacing: 6, // space between lines
                              children: [
                                _buildLink(
                                  context,
                                  "→ Google Cloud Console",
                                  "https://console.cloud.google.com/",
                                ),
                                _buildLink(
                                  context,
                                  "→ HERE Developer",
                                  "https://developer.here.com/",
                                ),
                                _buildLink(
                                  context,
                                  "→ TomTom Developer",
                                  "https://developer.tomtom.com/",
                                ),
                                _buildLink(
                                  context,
                                  "→ Mapbox Account",
                                  "https://account.mapbox.com/",
                                ),
                                _buildLink(
                                  context,
                                  "→ LocationIQ",
                                  "https://locationiq.com/",
                                ),
                                _buildLink(
                                  context,
                                  "→ OSM Nominatim",
                                  "https://nominatim.org/",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ==================== API Key or User Agent ====================
                      if (selectedProvider != "OSM Nominatim(FREE - No key)")
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${selectedProvider.split('(')[0].trim()} API KEY",
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurface,
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                              ),
                              controller: reverseGeoApiKeyController,
                              decoration: _inputDecoration(context),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(
                                    0.05,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "OpenStreetMap Nominatim - Free Service",
                                    style: GoogleFonts.inter(
                                      fontSize:
                                          AdaptiveUtils.getSubtitleFontSize(
                                            width,
                                          ) -
                                          3,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No API key required. Only User-Agent string needed.",
                                    style: GoogleFonts.inter(
                                      fontSize:
                                          AdaptiveUtils.getSubtitleFontSize(
                                            width,
                                          ) -
                                          5,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "USER AGENT STRING",
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurface,
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                              ),
                              controller: userAgentController,
                              decoration: _inputDecoration(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Required by OSM usage policy",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    5,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showUnavailableTest(
                      setLoading: (v) => _testGeoLoading = v,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Check icon chip
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: _testGeoLoading
                                    ? const AppShimmer(
                                        width: 16,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Button Text
                            Text(
                              "Test Geocoding",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // a bit more breathing room
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== SSO - Google OAuth 2.0 Header ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: AdaptiveUtils.getTitleFontSize(width) + 5,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SSO - Google OAuth 2.0",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: ssoEnabled,
                          activeColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(
                            0.3,
                          ),
                          onChanged: _saving
                              ? null
                              : (v) => _toggleAndPersist(
                                  currentValue: ssoEnabled,
                                  nextValue: v,
                                  setLocalValue: (value) => ssoEnabled = value,
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24), // space between the two sections
                  // ==================== Setup Instructions ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ), // a bit more breathing room
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.integration_instructions,
                              size: 22,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Setup Instructions",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    3,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "1. Go to ",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    5,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                  "https://console.cloud.google.com/",
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Text(
                                "Google Cloud Console",
                                style: GoogleFonts.inter(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(width) -
                                      5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "2. Create OAuth 2.0 Client ID (Application type: Web application)",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "3. Add authorized redirect URI: https://app.fleetstack.com/auth/google/callback",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "4. Copy Client ID and Client Secret",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GOOGLE CLIENT ID
                      Text(
                        "GOOGLE CLIENT ID",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: googleClientIdController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // GOOGLE CLIENT SECRET
                      Text(
                        "GOOGLE CLIENT SECRET",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: googleClientSecretController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // REDIRECT URL
                      Text(
                        "REDIRECT URL",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: googleRedirectUrlController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add this URL to authorized redirect URIs in Google Console",
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 5,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showUnavailableTest(
                      setLoading: (v) => _testSsoLoading = v,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Check icon chip
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: _testSsoLoading
                                    ? const AppShimmer(
                                        width: 16,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Button Text
                            Text(
                              "Test SSO Connection",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // a bit more breathing room
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== OpenAI Integration Header ====================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: AdaptiveUtils.getTitleFontSize(width) + 5,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "OpenAI Integration",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: openAiEnabled,
                          activeColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(
                            0.3,
                          ),
                          onChanged: _saving
                              ? null
                              : (v) => _toggleAndPersist(
                                  currentValue: openAiEnabled,
                                  nextValue: v,
                                  setLocalValue: (value) =>
                                      openAiEnabled = value,
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24), // space between the two sections
                  // ==================== Setup Instructions ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      16,
                    ), // a bit more breathing room
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.integration_instructions,
                              size: 22,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Setup Instructions",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    3,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "1. Go to ",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    5,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                  "https://platform.openai.com/api-keys",
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Text(
                                "OpenAI API Keys",
                                style: GoogleFonts.inter(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(width) -
                                      5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "2. Create new secret key (starts with sk-proj-...)",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "3. Optional: Get Organization ID from Settings",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "4. Set usage limits in Billing",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // API KEY
                      Text(
                        "API KEY",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: openAiApiKeyController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // ORGANIZATION ID (Optional)
                      Text(
                        "ORGANIZATION ID (Optional)",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                        ),
                        controller: openAiOrgIdController,
                        decoration: _inputDecoration(context),
                      ),
                      const SizedBox(height: 12),

                      // MODEL
                      Text(
                        "MODEL",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: selectedModel,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          underline: const SizedBox(),
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface,
                            fontSize: AdaptiveUtils.getTitleFontSize(width),
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => selectedModel = newValue);
                            }
                          },
                          items: <String>["GPT-4", "GPT-4 TURBO (Recommended)"]
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // MAX-TOKEN
                      Text(
                        "MAX-TOKEN",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: maxTokens.toDouble(),
                        min: 1,
                        max: 4096,
                        divisions: 4095,
                        label: maxTokens.toString(),
                        activeColor: colorScheme.primary,
                        onChanged: (double value) {
                          setState(() {
                            maxTokens = value.toInt();
                          });
                        },
                      ),
                      Text(
                        "Range: 1–4096 tokens",
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 5,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showUnavailableTest(
                      setLoading: (v) => _testOpenAiLoading = v,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Check icon chip
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: _testOpenAiLoading
                                    ? const AppShimmer(
                                        width: 16,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Button Text
                            Text(
                              "Test Openai Connection",
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12), // a bit more breathing room
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== Useful Documentation Header ====================
                  Text(
                    "Useful Documentation",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),

                  const SizedBox(height: 16), // space between the two sections

                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "https://firebase.google.com/docs/web/setup",
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Firebase setup",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Web SDK Documentation",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "https://developers.google.com/maps/documentation/geocoding/overview",
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Google geocoding",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "API Documentation",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "https://developers.google.com/identity/protocols/oauth2",
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Google OAuth 2.0",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "SSO implementation",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "https://www.twilio.com/docs/whatsapp/api",
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Twilio Whatsapp",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "API Documentation",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "https://developers.facebook.com/docs/whatsapp",
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Whatsapp Business",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Meta Documentation",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "https://platform.openai.com/docs/api-reference",
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "OpenAI API",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Platform documentation",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 5,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(double width) {
    return Column(
      children: [
        _buildShimmerSection(width: width, titleWidth: 210, fields: 7),
        const SizedBox(height: 24),
        _buildShimmerSection(width: width, titleWidth: 240, fields: 4),
        const SizedBox(height: 24),
        _buildShimmerSection(width: width, titleWidth: 190, fields: 3),
        const SizedBox(height: 24),
        _buildShimmerSection(width: width, titleWidth: 180, fields: 3),
      ],
    );
  }

  Widget _buildShimmerSection({
    required double width,
    required double titleWidth,
    required int fields,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double labelWidth = (width * 0.22).clamp(90, 180).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppShimmer(width: titleWidth, height: 24, radius: 8),
              const AppShimmer(width: 46, height: 26, radius: 14),
            ],
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < fields; i++) ...[
            AppShimmer(width: labelWidth, height: 12, radius: 8),
            const SizedBox(height: 8),
            const AppShimmer(width: double.infinity, height: 44, radius: 12),
            if (i != fields - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildLink(BuildContext context, String label, String url) {
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
          fontWeight: FontWeight.w400,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
