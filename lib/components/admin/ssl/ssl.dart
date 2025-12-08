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

    final List<Map<String, dynamic>> domains = [
      {
        "domain": "track.contoso-logistics.com",
        "expiry": "12 Jan 2026",
        "status": "Active",
        "statusColor": Colors.green,
        "actions": ["Renew", "Uninstall", "Details"],
      },
      {
        "domain": "fleet.alpha.dev",
        "expiry": "05 Nov 2025",
        "status": "Expiring Soon",
        "statusColor": Colors.orange,
        "actions": ["Renew", "Details"],
      },
      {
        "domain": "portal.omimportexport.in",
        "expiry": "—",
        "status": "Pending",
        "statusColor": Colors.grey,
        "actions": ["Install SSL", "Details"],
      },
      {
        "domain": "gps.fleetstackglobal.com",
        "expiry": "Invalid Date",
        "status": "Error",
        "statusColor": Colors.red,
        "actions": ["Install SSL", "Uninstall", "Details"],
      },
      {
        "domain": "telematics.newtechauto.co",
        "expiry": "15 Sept 2025",
        "status": "Expired",
        "statusColor": Colors.red,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      "SSL Management",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      "Manage SSL certificates for your domains",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getTitleFontSize(width),
        fontWeight: FontWeight.w200,
        color: Colors.black.withOpacity(0.9),
      ),
    ),

                  const SizedBox(height: 32),

                  

                  // Inside your domains.map
...domains.map((domain) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
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
              // Domain & Expiry
              Text(
                domain["domain"],
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Expiry: ${domain["expiry"]}",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              // Status container under domain/expiry
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: domain["statusColor"].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: domain["statusColor"].withOpacity(0.2)),
                ),
                child: Text(
                  domain["status"],
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w600,
                    color: domain["statusColor"],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Actions Column with Dropdown
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.topRight,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (action) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Selected: $action")),
                );
              },
              itemBuilder: (context) =>
                  domain["actions"].map<PopupMenuItem<String>>((action) {
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