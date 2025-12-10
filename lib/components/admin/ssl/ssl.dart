import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SSLManagementScreen extends StatefulWidget {
  const SSLManagementScreen({super.key});

  @override
  State<SSLManagementScreen> createState() => _SSLManagementScreenState();
}

class _SSLManagementScreenState extends State<SSLManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final cs = Theme.of(context).colorScheme; // shortcut

    final List<Map<String, dynamic>> domains = [
      {
        "domain": "track.contoso-logistics.com",
        "expiry": "12 Jan 2026",
        "status": "Active",
        "statusColor": cs.primary, // replaced Colors.green
        "actions": ["Renew", "Uninstall", "Details"],
      },
      {
        "domain": "fleet.alpha.dev",
        "expiry": "05 Nov 2025",
        "status": "Expiring Soon",
        "statusColor": cs.secondary, // replaced orange
        "actions": ["Renew", "Details"],
      },
      {
        "domain": "portal.omimportexport.in",
        "expiry": "—",
        "status": "Pending",
        "statusColor": cs.outline, // replaced grey
        "actions": ["Install SSL", "Details"],
      },
      {
        "domain": "gps.fleetstackglobal.com",
        "expiry": "Invalid Date",
        "status": "Error",
        "statusColor": cs.error, // replaced red
        "actions": ["Install SSL", "Uninstall", "Details"],
      },
      {
        "domain": "telematics.newtechauto.co",
        "expiry": "15 Sept 2025",
        "status": "Expired",
        "statusColor": cs.error,
        "actions": ["Install SSL", "Uninstall", "Details"],
      },
    ];

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
                  Text(
                    "SSL Management",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
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
                  ...domains.map((domain) {
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
                                  domain["domain"],
                                  style: GoogleFonts.inter(
                                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Expiry: ${domain["expiry"]}",
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(width) - 5,
                                    color: cs.onSurface.withOpacity(0.65),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (domain["statusColor"] as Color)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: domain["statusColor"]
                                          .withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    domain["status"],
                                    style: GoogleFonts.inter(
                                      fontSize:
                                          AdaptiveUtils.getSubtitleFontSize(width) -
                                              5,
                                      fontWeight: FontWeight.w600,
                                      color: domain["statusColor"],
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
                                icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.primary),
                                onSelected: (action) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Selected: $action")),
                                  );
                                },
                                itemBuilder: (context) =>
                                    domain["actions"]
                                        .map<PopupMenuItem<String>>((action) {
                                  return PopupMenuItem<String>(
                                    value: action,
                                    child: Text(action),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

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
