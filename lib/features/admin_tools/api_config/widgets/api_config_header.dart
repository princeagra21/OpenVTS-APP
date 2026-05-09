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
  static const List<String> _providerOptions = [
    'OSM Nominatim(FREE - No key)',
    'Google map (Paid - 5\$/100req)',
    'HERE Map(FREE - 250K/Month)',
    'TomTom(FREE - 250o/day)',
    'MapBox(FREE - 100/Month)',
    'Location IQ(FREE - 1000/day)',
  ];

  static const List<String> _modelOptions = [
    'GPT-4 TURBO (Recommended)',
    'GPT-4',
  ];

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
    firebaseApiKeyController = TextEditingController(
      text: config.firebaseApiKey,
    );
    firebaseAuthDomainController = TextEditingController(
      text: config.firebaseAuthDomain,
    );
    firebaseProjectIdController = TextEditingController(
      text: config.firebaseProjectId,
    );
    firebaseStorageBucketController = TextEditingController(
      text: config.firebaseStorageBucket,
    );
    firebaseMessagingSenderIdController = TextEditingController(
      text: config.firebaseMessagingSenderId,
    );
    firebaseAppIdController = TextEditingController(text: config.firebaseAppId);
    firebaseMeasurementIdController = TextEditingController(
      text: config.firebaseMeasurementId,
    );
    reverseGeoApiKeyController = TextEditingController(
      text: config.geocodingApiKey,
    );
    userAgentController = TextEditingController(
      text: config.geocodingUserAgent,
    );
    googleClientIdController = TextEditingController(
      text: config.googleClientId,
    );
    googleClientSecretController = TextEditingController(
      text: config.googleClientSecret,
    );
    googleRedirectUrlController = TextEditingController(
      text: config.googleRedirectUrl,
    );
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
    final config = widget.controller.state.config;
    _setControllerText(firebaseApiKeyController, config.firebaseApiKey);
    _setControllerText(firebaseAuthDomainController, config.firebaseAuthDomain);
    _setControllerText(firebaseProjectIdController, config.firebaseProjectId);
    _setControllerText(
      firebaseStorageBucketController,
      config.firebaseStorageBucket,
    );
    _setControllerText(
      firebaseMessagingSenderIdController,
      config.firebaseMessagingSenderId,
    );
    _setControllerText(firebaseAppIdController, config.firebaseAppId);
    _setControllerText(
      firebaseMeasurementIdController,
      config.firebaseMeasurementId,
    );
    _setControllerText(reverseGeoApiKeyController, config.geocodingApiKey);
    _setControllerText(userAgentController, config.geocodingUserAgent);
    _setControllerText(googleClientIdController, config.googleClientId);
    _setControllerText(googleClientSecretController, config.googleClientSecret);
    _setControllerText(googleRedirectUrlController, config.googleRedirectUrl);
    _setControllerText(openAiApiKeyController, config.openaiApiKey);
    _setControllerText(openAiOrgIdController, config.openaiOrgId);

    selectedProvider = _providerUiValue(config.geocodingProvider);
    selectedModel = _openAiUiModel(config.openaiModel);
    maxTokens = config.openaiMaxTokens;
    if (mounted) setState(() {});
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
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

  void _updateConfig({
    bool? firebaseEnabled,
    bool? geocodingEnabled,
    bool? geocodingProviderActive,
    bool? googleSsoEnabled,
    bool? openaiEnabled,
    int? openaiMaxTokens,
  }) {
    final current = widget.controller.state.config;
    final newConfig = ApiConfigModel(
      firebaseEnabled: firebaseEnabled ?? current.firebaseEnabled,
      firebaseApiKey: firebaseApiKeyController.text,
      firebaseAuthDomain: firebaseAuthDomainController.text,
      firebaseProjectId: firebaseProjectIdController.text,
      firebaseStorageBucket: firebaseStorageBucketController.text,
      firebaseMessagingSenderId: firebaseMessagingSenderIdController.text,
      firebaseAppId: firebaseAppIdController.text,
      firebaseMeasurementId: firebaseMeasurementIdController.text,
      geocodingEnabled: geocodingEnabled ?? current.geocodingEnabled,
      geocodingProvider: _providerApiValue(selectedProvider),
      geocodingApiKey: reverseGeoApiKeyController.text,
      geocodingUserAgent: userAgentController.text,
      geocodingProviderActive:
          geocodingProviderActive ?? current.geocodingProviderActive,
      googleSsoEnabled: googleSsoEnabled ?? current.googleSsoEnabled,
      googleClientId: googleClientIdController.text,
      googleClientSecret: googleClientSecretController.text,
      googleRedirectUrl: googleRedirectUrlController.text,
      openaiEnabled: openaiEnabled ?? current.openaiEnabled,
      openaiApiKey: openAiApiKeyController.text,
      openaiOrgId: openAiOrgIdController.text,
      openaiModel: _openAiApiModel(selectedModel),
      openaiMaxTokens: openaiMaxTokens ?? maxTokens,
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
            _buildConfigForm(context, width),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildMessage(context, state.errorMessage!, colorScheme.error),
            ],
            if (state.lastSaveAt != null) ...[
              const SizedBox(height: 16),
              _buildMessage(
                context,
                'Saved ${TimeOfDay.fromDateTime(state.lastSaveAt!).format(context)}',
                Colors.green,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConfigForm(BuildContext context, double width) {
    final config = widget.controller.state.config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          title: 'Firebase',
          children: [
            _buildSwitchField(
              title: 'Enable Firebase',
              value: config.firebaseEnabled,
              onChanged: (value) => _updateConfig(firebaseEnabled: value),
            ),
            _buildTextField(
              'API Key',
              firebaseApiKeyController,
              obscureText: true,
            ),
            _buildTextField('Auth Domain', firebaseAuthDomainController),
            _buildTextField('Project ID', firebaseProjectIdController),
            _buildTextField('Storage Bucket', firebaseStorageBucketController),
            _buildTextField(
              'Messaging Sender ID',
              firebaseMessagingSenderIdController,
            ),
            _buildTextField('App ID', firebaseAppIdController),
            _buildTextField('Measurement ID', firebaseMeasurementIdController),
          ],
        ),
        _buildSection(
          context,
          title: 'Reverse Geocoding',
          children: [
            _buildSwitchField(
              title: 'Enable Geocoding',
              value: config.geocodingEnabled,
              onChanged: (value) => _updateConfig(geocodingEnabled: value),
            ),
            _buildDropdown(
              label: 'Provider',
              value: selectedProvider,
              options: _providerOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedProvider = value);
                _updateConfig();
              },
            ),
            _buildSwitchField(
              title: 'Provider Active',
              value: config.geocodingProviderActive,
              onChanged: (value) =>
                  _updateConfig(geocodingProviderActive: value),
            ),
            _buildTextField(
              'API Key',
              reverseGeoApiKeyController,
              obscureText: true,
            ),
            _buildTextField('User Agent', userAgentController),
          ],
        ),
        _buildSection(
          context,
          title: 'Google SSO',
          children: [
            _buildSwitchField(
              title: 'Enable Google SSO',
              value: config.googleSsoEnabled,
              onChanged: (value) => _updateConfig(googleSsoEnabled: value),
            ),
            _buildTextField('Client ID', googleClientIdController),
            _buildTextField(
              'Client Secret',
              googleClientSecretController,
              obscureText: true,
            ),
            _buildTextField('Redirect URL', googleRedirectUrlController),
          ],
        ),
        _buildSection(
          context,
          title: 'OpenAI',
          children: [
            _buildSwitchField(
              title: 'Enable OpenAI',
              value: config.openaiEnabled,
              onChanged: (value) => _updateConfig(openaiEnabled: value),
            ),
            _buildTextField(
              'API Key',
              openAiApiKeyController,
              obscureText: true,
            ),
            _buildTextField('Organization ID', openAiOrgIdController),
            _buildDropdown(
              label: 'Model',
              value: selectedModel,
              options: _modelOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedModel = value);
                _updateConfig();
              },
            ),
            _buildTokenLimitField(context),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
          const SizedBox(height: 4),
          Divider(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildSwitchField({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) => _updateConfig(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final selected = options.contains(value) ? value : options.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTokenLimitField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max Tokens: $maxTokens',
          style: AppFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Slider(
          value: maxTokens.clamp(256, 8192).toDouble(),
          min: 256,
          max: 8192,
          divisions: 31,
          label: maxTokens.toString(),
          onChanged: (value) {
            final next = value.round();
            setState(() => maxTokens = next);
            _updateConfig(openaiMaxTokens: next);
          },
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, String message, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: AppFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(double width) {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppShimmer(width: width * 0.8, height: 20, radius: 4),
        ),
      ),
    );
  }
}
