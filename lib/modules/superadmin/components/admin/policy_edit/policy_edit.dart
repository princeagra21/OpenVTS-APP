// screens/policy/policy_edit_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_policy.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_policy_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PolicyEditScreen extends StatefulWidget {
  const PolicyEditScreen({super.key});

  @override
  State<PolicyEditScreen> createState() => _PolicyEditScreenState();
}

class _PolicyEditScreenState extends State<PolicyEditScreen> {
  // Postman-confirmed endpoints for this screen:
  // - GET /policies
  // - PATCH /superadmin/policy (body keys: PolicyType, PolicyText)
  String selectedPolicy = "Terms of Service";

  static const List<String> _defaultPolicyTypes = [
    "Terms of Service",
    "Privacy Policy",
    "Cookie Policy",
    "Refund Policy",
  ];

  late final Map<String, String> policies;
  late TextEditingController policyController;
  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  DateTime? _lastSaveAt;
  CancelToken? _loadToken;
  CancelToken? _saveToken;
  ApiClient? _apiClient;
  UserPolicyRepository? _repo;

  @override
  void initState() {
    super.initState();
    policies = _emptyPolicyMap();
    policyController = TextEditingController(text: policies[selectedPolicy]);
    _loadPolicies();
  }

  Map<String, String> _emptyPolicyMap() {
    return {for (final type in _defaultPolicyTypes) type: ''};
  }

  void _updatePolicyContent() {
    policyController.text = policies[selectedPolicy] ?? "";
  }

  void _commitCurrentPolicy() {
    policies[selectedPolicy] = policyController.text;
  }

  UserPolicyRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserPolicyRepository(api: _apiClient!);
    return _repo!;
  }

  String _policyTypeFromDisplay(String displayName) {
    switch (displayName) {
      case "Terms of Service":
        return "TERMS_OF_SERVICE";
      case "Privacy Policy":
        return "PRIVACY_POLICY";
      case "Cookie Policy":
        return "COOKIE_POLICY";
      case "Refund Policy":
        return "REFUND_POLICY";
      default:
        return displayName
            .trim()
            .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
            .toUpperCase();
    }
  }

  String _displayFromPolicy(UserPolicy policy) {
    final type = policy.policyType.trim().toUpperCase();
    if (type.contains('TERMS')) return "Terms of Service";
    if (type.contains('PRIVACY')) return "Privacy Policy";
    if (type.contains('COOKIE')) return "Cookie Policy";
    if (type.contains('REFUND')) return "Refund Policy";

    final title = policy.title.trim();
    if (title.isNotEmpty) return title;

    if (type.isEmpty) return '';
    final parts = type.split('_').where((e) => e.isNotEmpty);
    if (parts.isEmpty) return '';
    return parts.map((p) => p[0] + p.substring(1).toLowerCase()).join(' ');
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSaveErrorOnce(String message) {
    if (_saveErrorShown || !mounted) return;
    _saveErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadPolicies() async {
    _loadToken?.cancel('Reload user policies');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getPolicies(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (list) {
          final merged = _emptyPolicyMap();

          for (final item in list) {
            final display = _displayFromPolicy(item);
            if (display.isEmpty) continue;
            merged[display] = item.policyText;
          }

          setState(() {
            policies
              ..clear()
              ..addAll(merged);
            if (!policies.containsKey(selectedPolicy)) {
              selectedPolicy = policies.keys.isNotEmpty
                  ? policies.keys.first
                  : "Terms of Service";
            }
            _updatePolicyContent();
            _loading = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          setState(() => _loading = false);
          final message =
              (error is ApiException &&
                  (error.statusCode == 401 || error.statusCode == 403))
              ? 'Not authorized to load policies.'
              : "Couldn't load policies.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showLoadErrorOnce("Couldn't load policies.");
    }
  }

  Future<void> _saveAll() async {
    if (_saving) return;

    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) return;
    _lastSaveAt = now;

    _commitCurrentPolicy();

    _saveToken?.cancel('Retry save policies');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'policies': policies.entries
          .map(
            (e) => <String, dynamic>{
              'PolicyType': _policyTypeFromDisplay(e.key),
              'PolicyText': e.value,
            },
          )
          .toList(),
    };

    try {
      final res = await _repoOrCreate().updatePolicies(
        payload,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Policies saved')));
        },
        failure: (error) {
          setState(() => _saving = false);
          final message =
              (error is ApiException &&
                  (error.statusCode == 401 || error.statusCode == 403))
              ? 'Not authorized to update policies.'
              : "Couldn't save policies.";
          _showSaveErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveErrorOnce("Couldn't save policies.");
    }
  }

  void _resetAllToTemplates() {
    setState(() {
      policies
        ..clear()
        ..addAll(_emptyPolicyMap());
      selectedPolicy = "Terms of Service";
      _updatePolicyContent();
    });
  }

  void _resetSelectedToTemplate() {
    final template = "";
    setState(() {
      policies[selectedPolicy] = template;
      policyController.text = template;
    });
  }

  @override
  void didUpdateWidget(covariant PolicyEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePolicyContent();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Policy edit disposed');
    _saveToken?.cancel('Policy edit disposed');
    policyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return AppLayout(
      title: "Open VTS",
      subtitle: "User Policy",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              _buildLoadingSkeleton(context, hp, fs)
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(hp),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: (_saving || _loading)
                              ? null
                              : _resetAllToTemplates,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: hp + 4,
                              vertical: hp - 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: colorScheme.onSurface,
                          ),
                          label: Text(
                            "Clear All",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: (_saving || _loading) ? null : _saveAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: hp + 4,
                              vertical: hp - 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: SizedBox(
                            width: 18,
                            height: 18,
                            child: _saving
                                ? const AppShimmer(
                                    width: 18,
                                    height: 18,
                                    radius: 9,
                                  )
                                : Icon(
                                    Icons.save_outlined,
                                    color: colorScheme.onPrimary,
                                  ),
                          ),
                          label: Text(
                            "Save All",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // TITLE
                    Row(
                      children: [
                        Text(
                          "User Policy Management",
                          style: GoogleFonts.roboto(
                            fontSize: fs + 6,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                        if (_loading) ...[
                          const SizedBox(width: 8),
                          const AppShimmer(width: 12, height: 12, radius: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create and manage legal agreements for your users",
                      style: GoogleFonts.roboto(
                        fontSize: fs - 1,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // POLICY SELECTOR
                    Container(
                      padding: EdgeInsets.all(hp),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Policy to Edit",
                            style: GoogleFonts.roboto(
                              fontSize: fs + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedPolicy,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            style: GoogleFonts.roboto(
                              fontSize: fs,
                              color: colorScheme.onSurface,
                            ),
                            dropdownColor: colorScheme.surface,
                            items: policies.keys
                                .map(
                                  (key) => DropdownMenuItem(
                                    value: key,
                                    child: Text(key),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (v) => v != null
                                      ? setState(() {
                                          _commitCurrentPolicy();
                                          selectedPolicy = v;
                                          _updatePolicyContent();
                                        })
                                      : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // POLICY EDITOR
                    Container(
                      padding: EdgeInsets.all(hp),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description_rounded,
                                size: fs + 8,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedPolicy,
                                style: GoogleFonts.roboto(
                                  fontSize: fs + 4,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Configure the policy content and settings",
                            style: GoogleFonts.roboto(
                              fontSize: fs - 2,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // WORD COUNT + RESET
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${policyController.text.trim().split(' ').where((e) => e.isNotEmpty).length} words",
                                style: GoogleFonts.roboto(
                                  fontSize: fs - 2,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : _resetSelectedToTemplate,
                                child: Text(
                                  "Clear Text",
                                  style: GoogleFonts.roboto(
                                    fontSize: fs - 2,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // TEXT EDITOR
                          TextField(
                            controller: policyController,
                            maxLines: null,
                            minLines: 18,
                            onChanged: _saving
                                ? null
                                : (value) => setState(
                                    () => policies[selectedPolicy] = value,
                                  ),
                            style: GoogleFonts.roboto(
                              fontSize: fs,
                              color: colorScheme.onSurface,
                              height: 1.7,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter policy content here...",
                              hintStyle: GoogleFonts.roboto(
                                fontSize: fs,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.all(20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Plain text format. Updates will be reflected immediately for users.",
                            style: GoogleFonts.roboto(
                              fontSize: fs - 4,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context, double hp, double fs) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              AppShimmer(width: 120, height: 40, radius: 12),
              SizedBox(width: 12),
              AppShimmer(width: 110, height: 40, radius: 12),
            ],
          ),
          const SizedBox(height: 28),
          AppShimmer(width: fs * 9, height: 30, radius: 8),
          const SizedBox(height: 8),
          const AppShimmer(width: 340, height: 14, radius: 8),
          const SizedBox(height: 32),
          _buildLoadingCard(
            context: context,
            hp: hp,
            titleWidth: 190,
            fields: 1,
          ),
          const SizedBox(height: 28),
          _buildLoadingCard(
            context: context,
            hp: hp,
            titleWidth: 220,
            fields: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({
    required BuildContext context,
    required double hp,
    required double titleWidth,
    required int fields,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final double labelWidth = (width * 0.24).clamp(90, 180).toDouble();

    return Container(
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(width: titleWidth, height: 22, radius: 8),
          const SizedBox(height: 16),
          for (int i = 0; i < fields; i++) ...[
            AppShimmer(width: labelWidth, height: 12, radius: 8),
            const SizedBox(height: 8),
            const AppShimmer(width: double.infinity, height: 50, radius: 14),
            if (i != fields - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
