import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RolesTab extends StatefulWidget {
  const RolesTab({super.key});

  @override
  State<RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<RolesTab> {
  String _selectedRole = 'Full Admin';
  Map<String, String> _permissions = {};
  final List<String> modules = [
    "Tenants",
    "Users",
    "Roles",
    "Vehicles",
    "Devices",
    "SIM/APN",
    "Live Tracking",
    "Geofences",
    "Alerts",
    "Commands",
    "Reports",
    "Billing",
    "Integrations",
    "Support",
    "SSL"
  ];

  @override
  void initState() {
    super.initState();
    for (var module in modules) {
      _permissions[module] = 'Full';
    }
  }

  Widget _buildSettingField({
    required IconData icon,
    required String label,
    required String hint,
    required List<DropdownMenuItem<String>> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant,
          ),
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          items: items,
          value: _selectedRole,
          onChanged: (value) {
            setState(() {
              _selectedRole = value!;
            });
            print("Selected $label: $value");
          },
        ),
      ],
    );
  }

  Widget _buildPermissionRow(String module, double screenWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          module,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Full",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "Full",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      print("Selected access for $module: $value");
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Manage",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "Manage",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      print("Selected access for $module: $value");
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Edit",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "Edit",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      print("Selected access for $module: $value");
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "View",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      print("Selected access for $module: $value");
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "None",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "None",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      print("Selected access for $module: $value");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    List<Widget> permissionRows = [];
    for (var module in modules) {
      permissionRows.add(_buildPermissionRow(module, screenWidth));
      permissionRows.add(const SizedBox(height: 20));
    }
    if (permissionRows.isNotEmpty) {
      permissionRows.removeLast();
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Roles Header
            Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 24, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Roles",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSettingField(
              icon: Icons.person,
              label: "Select Role",
              hint: "Select Role",
              items: const [
                DropdownMenuItem(value: "Full Admin", child: Text("Full Admin")),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Permissions overview for this role",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 20),
            ...permissionRows,
          ],
        ),
      ),
    );
  }
}