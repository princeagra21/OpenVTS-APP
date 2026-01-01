// components/admin/admin_settings_tab.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  String? _selectedTheme = 'system';
  String? _selectedUnit = 'KM';

  Widget _buildSettingField({
    required IconData icon,
    required String label,
    required String hint,
    required List<DropdownMenuItem<String>> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

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
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
          onChanged: (value) {
            print("Selected $label: $value");
          },
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String value,
    required String label,
    required bool textOnTop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    final bool isSelected = _selectedTheme == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedTheme = value);
          print("Selected theme: $value");
        },
        child: Column(
          children: [
            if (textOnTop)
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            Radio<String>(
              value: value,
              groupValue: _selectedTheme,
              activeColor: colorScheme.primary,
              onChanged: (v) => setState(() => _selectedTheme = v),
            ),
            if (!textOnTop)
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Main Admin Settings Container
          Container(
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
                  Row(
                    children: [
                      Icon(Icons.settings, size: 24, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Admin Settings",
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
                    icon: Icons.language,
                    label: "Language",
                    hint: "Select Language",
                    items: const [
                      DropdownMenuItem(value: "en", child: Text("English")),
                      DropdownMenuItem(value: "fr", child: Text("French")),
                      DropdownMenuItem(value: "es", child: Text("Spanish")),
                      DropdownMenuItem(value: "de", child: Text("German")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.date_range,
                    label: "Date Format",
                    hint: "Select Date Format",
                    items: const [
                      DropdownMenuItem(value: "dd/MM/yyyy", child: Text("DD/MM/YYYY")),
                      DropdownMenuItem(value: "MM/dd/yyyy", child: Text("MM/DD/YYYY")),
                      DropdownMenuItem(value: "yyyy-MM-dd", child: Text("YYYY-MM-DD")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.access_time,
                    label: "Time Format",
                    hint: "Select Time Format",
                    items: const [
                      DropdownMenuItem(value: "12h", child: Text("12-hour")),
                      DropdownMenuItem(value: "24h", child: Text("24-hour")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.public,
                    label: "Time Zone",
                    hint: "Select Time Zone",
                    items: const [
                      DropdownMenuItem(value: "GMT", child: Text("GMT")),
                      DropdownMenuItem(value: "UTC", child: Text("UTC")),
                      DropdownMenuItem(value: "EST", child: Text("EST")),
                      DropdownMenuItem(value: "PST", child: Text("PST")),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.calendar_view_week,
                    label: "First Day of Week",
                    hint: "Select First Day",
                    items: const [
                      DropdownMenuItem(value: "monday", child: Text("Monday")),
                      DropdownMenuItem(value: "sunday", child: Text("Sunday")),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Theme Selection Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.brightness_6, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Theme",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThemeOption(value: "light", label: "Light", textOnTop: true),
                    _buildThemeOption(value: "dark", label: "Dark", textOnTop: false),
                    _buildThemeOption(value: "system", label: "System", textOnTop: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Units Selection Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Units",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedUnit = 'KM'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Radio<String>(
                              value: "KM",
                              groupValue: _selectedUnit,
                              activeColor: colorScheme.primary,
                              onChanged: (v) => setState(() => _selectedUnit = v),
                            ),
                            Text(
                              "KM",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedUnit == 'KM' ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedUnit = 'MILES'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Radio<String>(
                              value: "MILES",
                              groupValue: _selectedUnit,
                              activeColor: colorScheme.primary,
                              onChanged: (v) => setState(() => _selectedUnit = v),
                            ),
                            Text(
                              "MILES",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedUnit == 'MILES' ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}