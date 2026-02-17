import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/ssl_certificate_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
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
  static const List<Map<String, dynamic>> _fallbackDomains = [
    {
      "domain": "track.contoso-logistics.com",
      "expiry": "12 Jan 2026",
      "status": "Active",
      "actions": ["Renew", "Uninstall", "Details"],
    },
    {
      "domain": "fleet.alpha.dev",
      "expiry": "05 Nov 2025",
      "status": "Expiring Soon",
      "actions": ["Renew", "Details"],
    },
    {
      "domain": "portal.omimportexport.in",
      "expiry": "—",
      "status": "Pending",
      "actions": ["Install SSL", "Details"],
    },
    {
      "domain": "gps.fleetstackglobal.com",
      "expiry": "Invalid Date",
      "status": "Error",
      "actions": ["Install SSL", "Uninstall", "Details"],
    },
    {
      "domain": "telematics.newtechauto.co",
      "expiry": "15 Sept 2025",
      "status": "Expired",
      "actions": ["Install SSL", "Uninstall", "Details"],
    },
  ];

  late List<SslCertificateItem> _items;
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
    _items = _fallbackDomains
        .map((m) => SslCertificateItem(Map<String, dynamic>.from(m)))
        .toList();
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
            if (items.isNotEmpty) {
              _items = items;
            }
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
              : "Couldn't load SSL domains. Showing fallback values.";
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
        const SnackBar(
          content: Text("Couldn't load SSL domains. Showing fallback values."),
        ),
      );
    }
  }

  Color _statusColor(String status, ColorScheme cs) {
    final s = status.trim().toLowerCase();
    if (s.contains('active')) return cs.primary;
    if (s.contains('expiring')) return cs.secondary;
    if (s.contains('pending')) return cs.outline;
    if (s.contains('error') || s.contains('expired')) return cs.error;
    return cs.outline;
  }

  String _statusLabel(SslCertificateItem item) {
    final s = item.status.trim();
    return s.isEmpty ? 'Unknown' : s;
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
    if (s.contains('active')) return const ['Renew', 'Uninstall', 'Details'];
    if (s.contains('expiring')) return const ['Renew', 'Details'];
    if (s.contains('pending')) return const ['Install SSL', 'Details'];
    if (s.contains('error') || s.contains('expired')) {
      return const ['Install SSL', 'Uninstall', 'Details'];
    }
    return const ['Details'];
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

  void _handleUnavailableAction() {
    if (!kDebugMode || _actionUnavailableShown || !mounted) return;
    _actionUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action API not available yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final cs = Theme.of(context).colorScheme; // shortcut

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
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cs.primary,
                                  ),
                                ),
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
                  ..._items.map((item) {
                    final domainName = item.domain.trim().isEmpty
                        ? "—"
                        : item.domain.trim();
                    final statusText = _statusLabel(item);
                    final statusColor = _statusColor(statusText, cs);
                    final actions = _actionsFor(item);
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withOpacity(0.1)),
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
                                  style: GoogleFonts.inter(
                                    fontSize: AdaptiveUtils.getTitleFontSize(
                                      width,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Expiry: ${_formatExpiry(item)}",
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(
                                          width,
                                        ) -
                                        5,
                                    color: cs.onSurface.withOpacity(0.65),
                                  ),
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
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onSelected: (_) => _handleUnavailableAction(),
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
