import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  String selectedRoleTitle = "Custom Role";
  String selectedCurrency = "USD";
  int selectedAmount = 5;

  // Permission levels: None = 0, View = 1, Edit = 2, Manage = 3, Full = 4
  final Map<String, int> permissions = {
    "Tenants": 4,
    "Users": 4,
    "Roles": 4,
    "Vehicles": 4,
    "Devices": 4,
    "SIM/APN": 4,
    "Live Tracking": 4,
    "Geofences": 4,
    "Alerts": 4,
    "Commands": 4,
    "Reports": 4,
    "Billing": 4,
    "Integrations": 4,
    "Support": 4,
    "SSL": 4,
  };

  final List<String> currencies = ["USD", "EUR", "GBP", "INR", "AED", "SAR"];
  final List<int> amounts = [0, 5, 10, 25, 50, 100, 250, 500];

  late final Map<String, Map<String, int>> presets = {
    "Full Admin": {
      "Tenants": 4,
      "Users": 4,
      "Roles": 4,
      "Vehicles": 4,
      "Devices": 4,
      "SIM/APN": 4,
      "Live Tracking": 4,
      "Geofences": 4,
      "Alerts": 4,
      "Commands": 4,
      "Reports": 4,
      "Billing": 4,
      "Integrations": 4,
      "Support": 4,
      "SSL": 4,
    },
    "Ops Manager": {
      "Tenants": 4,
      "Users": 4,
      "Roles": 3,
      "Vehicles": 4,
      "Devices": 4,
      "SIM/APN": 4,
      "Live Tracking": 4,
      "Geofences": 4,
      "Alerts": 4,
      "Commands": 4,
      "Reports": 4,
      "Billing": 2,
      "Integrations": 2,
      "Support": 3,
      "SSL": 2,
    },
    "Support": {
      "Tenants": 1,
      "Users": 2,
      "Roles": 1,
      "Vehicles": 2,
      "Devices": 2,
      "SIM/APN": 2,
      "Live Tracking": 1,
      "Geofences": 1,
      "Alerts": 2,
      "Commands": 1,
      "Reports": 2,
      "Billing": 1,
      "Integrations": 1,
      "Support": 4,
      "SSL": 1,
    },
    "Read Only": {
      "Tenants": 1,
      "Users": 1,
      "Roles": 1,
      "Vehicles": 1,
      "Devices": 1,
      "SIM/APN": 1,
      "Live Tracking": 1,
      "Geofences": 1,
      "Alerts": 1,
      "Commands": 1,
      "Reports": 1,
      "Billing": 1,
      "Integrations": 1,
      "Support": 1,
      "SSL": 1,
    },
  };

  void _applyPreset(String preset) {
    setState(() {
      permissions.addAll(presets[preset]!);
    });
  }

  void _setAllPermissions(int level) {
    setState(() {
      for (var key in permissions.keys) {
        permissions[key] = level;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Role Permissions",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  // Header Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(horizontal: hp + 2, vertical: hp - 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            label: Text(
                              "Delete",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: hp + 2, vertical: hp - 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.save_outlined, color: Colors.white),
                            label: Text(
                              "Save",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Role Permissions",
                            style: GoogleFonts.inter(
                              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Configure access levels for different modules",
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                              fontWeight: FontWeight.w200,
                              color: Colors.black.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                 // Role Title + Monthly Cost (stacked vertically)
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Role Title
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Role Title",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getTitleFontSize(width),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: selectedRoleTitle),
          onChanged: (v) => selectedRoleTitle = v,
          decoration: _inputDecoration(hint: "Enter role name"),
        ),
      ],
    ),
    const SizedBox(height: 24),

    // Monthly Cost
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Monthly Cost",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getTitleFontSize(width),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Currency + Amount stacked vertically
        Column(
          children: [
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCurrency,
                  isExpanded: true,
                  style: GoogleFonts.inter(color: Colors.black),
                  onChanged: (v) => setState(() => selectedCurrency = v!),
                  items: currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedAmount,
                  isExpanded: true,
                  style: GoogleFonts.inter(color: Colors.black),
                  onChanged: (v) => setState(() => selectedAmount = v!),
                  items: amounts
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a == 0 ? "Free" : "$a"),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
),

                  const SizedBox(height: 32),

                  // Quick Presets
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quick Presets",
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center, // center alignment
                        children: [
                          "Full Admin",
                          "Ops Manager",
                          "Support",
                          "Read Only",
                        ].map((preset) {
                          return _LocalTab(
                            label: preset,
                            selected: false,
                            onTap: () => _applyPreset(preset),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Set All Permissions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Set all:",
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center, // center alignment
                        children: [
                          {"label": "None", "level": 0},
                          {"label": "View", "level": 1},
                          {"label": "Edit", "level": 2},
                          {"label": "Manage", "level": 3},
                          {"label": "Full", "level": 4},
                        ].map((item) {
                          return _LocalTab(
                            label: item["label"] as String,
                            selected: false,
                            onTap: () => _setAllPermissions(item["level"] as int),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Permissions Table
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(flex: 3, child: Text("Module", style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
                            Expanded(flex: 5, child: Text("Access", style: GoogleFonts.inter(fontWeight: FontWeight.w800))),
                          ],
                        ),
                        const Divider(height: 32),
                        ...permissions.keys.map((module) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(module, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                Expanded(
                                  flex: 5,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center, // center alignment
                                    children: [
                                      {"label": "None", "level": 0},
                                      {"label": "View", "level": 1},
                                      {"label": "Edit", "level": 2},
                                      {"label": "Manage", "level": 3},
                                      {"label": "Full", "level": 4},
                                    ].map((item) {
                                      final level = item["level"] as int;
                                      final label = item["label"] as String;
                                      final isSelected = permissions[module] == level;
                                      return _LocalTab(
                                        label: label,
                                        selected: isSelected,
                                        onTap: () => setState(() => permissions[module] = level),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.black.withOpacity(0.6), fontSize: 14),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
    );
  }
}

class _LocalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LocalTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool small = MediaQuery.of(context).size.width < 420;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 4 : 6), // slightly smaller vertical padding
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center( // center text vertically
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
