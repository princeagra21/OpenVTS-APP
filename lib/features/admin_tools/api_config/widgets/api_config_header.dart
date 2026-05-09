import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin_tools/api_config/api_config_controller.dart';
import 'package:open_vts/features/admin_tools/api_config/api_config_models.dart';

class ApiConfigHeader extends StatefulWidget {
  const ApiConfigHeader({super.key, required this.controller});

  final ApiConfigController controller;

  @override
  State<ApiConfigHeader> createState() => _ApiConfigHeaderState();
}

class _ApiConfigHeaderState extends State<ApiConfigHeader> {
  late final TextEditingController firebaseApiKeyController;
  late final TextEditingController firebaseAuthDomainController;
  late final TextEditingController firebaseProjectIdController;
  late final TextEditingController firebaseStorageBucketController;
  late final TextEditingController firebaseMessagingSenderIdController;
  late final TextEditingController firebaseAppIdController;
  late final TextEditingController firebaseMeasurementIdController;
  late final TextEditingController reverseGeoApiKeyController;
  late final TextEditingController userAgentController;
  late final TextEditingController googleClientIdController;
  late final TextEditingController googleClientSecretController;
  late final TextEditingController googleRedirectUrlController;
  late final TextEditingController openAiApiKeyController;
  late final TextEditingController openAiOrgIdController;

  String selectedProvider = "OSM Nominatim(FREE - No key)";
  String selectedModel = "GPT-4 TURBO (Recommended)";
  int maxTokens = 2048;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    final config = widget.controller.state.config;
    firebaseApiKeyController = TextEditingController(text: config.firebaseApiKey);
    firebaseAuthDomainController = TextEditingController(text: config.firebaseAuthDomain);
    firebaseProjectIdController = TextEditingController(text: config.firebaseProjectId);
    firebaseStorageBucketController = TextEditingController(text: config.firebaseStorageBucket);
    firebaseMessagingSenderIdController = TextEditingController(text: config.firebaseMessagingSenderId);
    firebaseAppIdController = TextEditingController(text: config.firebaseAppId);
    firebaseMeasurementIdController = TextEditingController(text: config.firebaseMeasurementId);
    reverseGeoApiKeyController = TextEditingController(text: config.geocodingApiKey);
    userAgentController = TextEditingController(text: config.geocodingUserAgent);
    googleClientIdController = TextEditingController(text: config.googleClientId);
    googleClientSecretController = TextEditingController(text: config.googleClientSecret);
    googleRedirectUrlController = TextEditingController(text: config.googleRedirectUrl);
    openAiApiKeyController = TextEditingController(text: config.openaiApiKey);
    openAiOrgIdController = TextEditingController(text: config.openaiOrgId);
    selectedProvider = _providerUiValue(config.geocodingProvider);
    selectedModel = _openAiUiModel(config.openaiModel);
    maxTokens = config.openaiMaxTokens;
  }

  void _disposeControllers() {
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
  }

  void _onControllerChange() {
    // Update controllers if config changes
    final config = widget.controller.state.config;
    if (firebaseApiKeyController.text != config.firebaseApiKey) {
      firebaseApiKeyController.text = config.firebaseApiKey;
    }
    // Update other controllers similarly...
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

  void _updateConfig() {
    final newConfig = ApiConfigModel(
      firebaseEnabled: widget.controller.state.config.firebaseEnabled,
      firebaseApiKey: firebaseApiKeyController.text,
      firebaseAuthDomain: firebaseAuthDomainController.text,
      firebaseProjectId: firebaseProjectIdController.text,
      firebaseStorageBucket: firebaseStorageBucketController.text,
      firebaseMessagingSenderId: firebaseMessagingSenderIdController.text,
      firebaseAppId: firebaseAppIdController.text,
      firebaseMeasurementId: firebaseMeasurementIdController.text,
      geocodingEnabled: widget.controller.state.config.geocodingEnabled,
      geocodingProvider: _providerApiValue(selectedProvider),
      geocodingApiKey: reverseGeoApiKeyController.text,
      geocodingUserAgent: userAgentController.text,
      geocodingProviderActive: widget.controller.state.config.geocodingProviderActive,
      googleSsoEnabled: widget.controller.state.config.googleSsoEnabled,
      googleClientId: googleClientIdController.text,
      googleClientSecret: googleClientSecretController.text,
      googleRedirectUrl: googleRedirectUrlController.text,
      openaiEnabled: widget.controller.state.config.openaiEnabled,
      openaiApiKey: openAiApiKeyController.text,
      openaiOrgId: openAiOrgIdController.text,
      openaiModel: _openAiApiModel(selectedModel),
      openaiMaxTokens: maxTokens,
    );
    widget.controller.updateConfig(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final colorScheme = Theme.of(context).colorScheme;
    final state = widget.controller.state;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "API Configuration",
                    style: AppFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Third-Party Integrations",
                    style: AppFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: AppShimmer(width: 12, height: 12, radius: 6),
                    ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: (state.isSaving || state.isLoading)
                    ? null
                    : () {
                        _updateConfig();
                        widget.controller.saveConfig();
                      },
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
                  child: state.isSaving
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
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (state.isLoading) ...[
            const SizedBox(height: 24),
            _buildLoadingShimmer(width),
          ] else ...[
            const SizedBox(height: 24),
            // Add form fields here
            Text('Form fields would go here'),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(double width) {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppShimmer(
            width: width * 0.8,
            height: 20,
            radius: 4,
          ),
        ),
      ),
    );
  }
}