import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/ssl_certificate_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SSLManagementScreen extends StatefulWidget {
  const SSLManagementScreen({super.key});

  @override
  State<SSLManagementScreen> createState() => _SSLManagementScreenState();
}

class _SSLManagementScreenState extends State<SSLManagementScreen> {
  // Postman-confirmed SSL-related endpoint(s):
  // - GET /superadmin/domainlist
  // No SSL action endpoints (renew/delete/activate) were found in Postman.
  List<SslCertificateItem> _items = <SslCertificateItem>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _actionUnavailableShown = false;
  CancelToken? _token;
  ApiClient? _apiClient;
  SuperadminRepository? _repo;

  SuperadminRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= SuperadminRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadSsl();
  }

  @override
  void dispose() {
    _token?.cancel('SSL screen disposed');
    super.dispose();
  }

  Future<void> _loadSsl() async {
    _token?.cancel('Reload SSL certificates');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getSslCertificates(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (items) {
          setState(() {
            _loading = false;
            _errorShown = false;
            _items = items;
          });
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load SSL domains.'
              : "Couldn't load SSL domains.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load SSL domains.")),
      );
    }
  }

  Color _statusColor(String status, ColorScheme cs) {
    final s = status.trim().toLowerCase();
    if (s == 'valid' || s.contains('active')) return cs.primary;
    if (s == 'not_installed' || s.contains('not installed')) return cs.error;
    if (s.contains('active')) return cs.primary;
    if (s.contains('expiring')) return cs.secondary;
    if (s.contains('pending')) return cs.outline;
    if (s.contains('error') || s.contains('expired')) return cs.error;
    return cs.outline;
  }

  String _statusLabel(SslCertificateItem item) {
    final s = item.status.trim();
    if (s.isEmpty) return 'Unknown';
    return s
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  List<String> _actionsFor(SslCertificateItem item) {
    final rawActions = item.raw['actions'];
    if (rawActions is List) {
      return rawActions
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    final s = item.status.trim().toLowerCase();
    if (s.contains('active')) return const ['Renew', 'Uninstall'];
    if (s.contains('expiring')) return const ['Renew'];
    if (s.contains('pending')) return const ['Install SSL'];
    if (s.contains('error') || s.contains('expired')) {
      return const ['Install SSL', 'Uninstall'];
    }
    return const [];
  }

  String _formatExpiry(SslCertificateItem item) {
    final parsed = item.expiryDate;
    if (parsed != null) {
      const months = <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = parsed.day.toString().padLeft(2, '0');
      final month = months[parsed.month - 1];
      return '$day $month ${parsed.year}';
    }

    final raw = item.expiryText.trim();
    if (raw.isNotEmpty) return raw;
    return '—';
  }

  String? _meaningfulText(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (text.toLowerCase() == 'null') return null;
    return text;
  }

  Widget _buildMetaText(
    BuildContext context, {
    required String label,
    required String? value,
    Color? color,
    int maxLines = 2,
  }) {
    final meaningful = _meaningfulText(value);
    if (meaningful == null) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        "$label: $meaningful",
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
          color: color ?? cs.onSurface.withOpacity(0.65),
        ),
      ),
    );
  }

  void _handleUnavailableAction() {
    if (!kDebugMode || _actionUnavailableShown || !mounted) return;
    _actionUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action API not available yet')),
    );
  }

  Widget _buildSslCardShimmer(ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: 140, height: 14, radius: 8),
                SizedBox(height: 10),
                AppShimmer(width: 88, height: 26, radius: 14),
              ],
            ),
          ),
          SizedBox(width: 12),
          AppShimmer(width: 28, height: 28, radius: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final cs = Theme.of(context).colorScheme; // shortcut
    final showSkeleton = _loading && _items.isEmpty;
    final showNoData = !_loading && _items.isEmpty;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "SSL Management",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      children: [
                        const TextSpan(text: "SSL Management"),
                        if (_loading)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: AppShimmer(
                                width: 12,
                                height: 12,
                                radius: 6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage SSL certificates for your domains",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w200,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Domain cards
                  if (showSkeleton)
                    ...List<Widget>.generate(4, (_) => _buildSslCardShimmer(cs))
                  else if (showNoData)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: Text(
                        "No domains found.",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          color: cs.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ..._items.map((item) {
                      final domainName = item.domain.trim().isEmpty
                          ? "—"
                          : item.domain.trim();
                      final statusText = _statusLabel(item);
                      final statusColor = _statusColor(statusText, cs);
                      final actions = _actionsFor(item);
                      final companyName = _meaningfulText(item.companyName);
                      final issuer = _meaningfulText(item.issuer);
                      final validFrom = _meaningfulText(item.validFrom);
                      final validTo = _meaningfulText(item.validTo);
                      final expiry = _formatExpiry(item);
                      final expiryText = expiry == '—' ? null : expiry;
                      final errorText = _meaningfulText(item.error);
                      final daysRemaining = item.daysRemaining;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outline.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Domain + Status Column
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    domainName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: AdaptiveUtils.getTitleFontSize(
                                        width,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  if (companyName != null)
                                    _buildMetaText(
                                      context,
                                      label: "Company",
                                      value: companyName,
                                      maxLines: 1,
                                    ),
                                  _buildMetaText(
                                    context,
                                    label: "Issuer",
                                    value: issuer,
                                    maxLines: 1,
                                  ),
                                  _buildMetaText(
                                    context,
                                    label: "Valid From",
                                    value: validFrom,
                                    maxLines: 1,
                                  ),
                                  _buildMetaText(
                                    context,
                                    label: "Valid To",
                                    value: validTo ?? expiryText,
                                    maxLines: 1,
                                  ),
                                  if (daysRemaining != null)
                                    _buildMetaText(
                                      context,
                                      label: "Days Remaining",
                                      value: "$daysRemaining",
                                      maxLines: 1,
                                    ),
                                  _buildMetaText(
                                    context,
                                    label: "Error",
                                    value: errorText,
                                    color: cs.error,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 8),

                                  // Status chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: GoogleFonts.inter(
                                        fontSize:
                                            AdaptiveUtils.getSubtitleFontSize(
                                              width,
                                            ) -
                                            5,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions (3-dot menu)
                            if (actions.isNotEmpty)
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    onSelected: (_) =>
                                        _handleUnavailableAction(),
                                    itemBuilder: (context) => actions
                                        .map<PopupMenuItem<String>>((action) {
                                          return PopupMenuItem<String>(
                                            value: action,
                                            child: Text(action),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
