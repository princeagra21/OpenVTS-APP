// screens/settings/localization_settings_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocalizationSettingsScreen extends StatelessWidget {
  const LocalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Localization",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LocalizationHeader(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class LocalizationHeader extends StatefulWidget {
  const LocalizationHeader({super.key});

  @override
  State<LocalizationHeader> createState() => _LocalizationHeaderState();
}

class _LocalizationHeaderState extends State<LocalizationHeader> {
  String selectedLanguage = "EN";
  String textDirection = "LTR";
  String dateFormat = "dd MMM yyyy";
  String timeFormat = "24-hour";
  String selectedTimezoneOffset = "+00:00"; // Store offset; assume loaded as this
  String units = "KM";
  double lat = 19.0760;
  double lng = 72.8777;
  int zoom = 10;

  final DateTime previewDate = DateTime(2025, 12, 7, 15, 28);
  final List<String> months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final Map<String, String> languageMap = {
    "EN": "English",
    "FR": "French",
    "ES": "Spanish",
    "DE": "German",
  };

  // Timezone list: offset value + region/city label (to avoid confusion)
  final List<Map<String, String>> timezoneOptions = [
    {"offset": "+00:00", "label": "UTC (GMT+00:00)"},
    {"offset": "+01:00", "label": "Europe/London (GMT+01:00)"},
    {"offset": "+02:00", "label": "Europe/Paris (GMT+02:00)"},
    {"offset": "-05:00", "label": "America/New_York (GMT-05:00)"},
    {"offset": "+05:30", "label": "Asia/Kolkata (GMT+05:30)"},
    // Add more region/city entries as needed
  ];

  // Helper to get label from offset (for preview or storage)
  String getTimezoneLabel(String offset) {
    return timezoneOptions.firstWhere(
      (tz) => tz['offset'] == offset,
      orElse: () => {"label": "Unknown"},
    )['label']!;
  }

  String getFormattedDate() {
    String day = previewDate.day.toString().padLeft(2, '0');
    String month = previewDate.month.toString().padLeft(2, '0');
    String year = previewDate.year.toString();
    String monthName = months[previewDate.month];
    return switch (dateFormat) {
      "dd MMM yyyy" => "$day $monthName $year",
      "MM/dd/yyyy" => "$month/$day/$year",
      "yyyy-MM-dd" => "$year-$month-$day",
      _ => "$day $monthName $year",
    };
  }

  String getFormattedTime() {
    String minute = previewDate.minute.toString().padLeft(2, '0');
    if (timeFormat == "24-hour") {
      return "${previewDate.hour.toString().padLeft(2, '0')}:$minute";
    } else {
      int hour = previewDate.hour % 12 == 0 ? 12 : previewDate.hour % 12;
      String ampm = previewDate.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $ampm";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          Text(
            "Localization Settings",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure language, timezone, date formats, and map focus for your application.",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          // LIVE PREVIEW (updated to use label)
          _buildSection(
            context: context,
            title: "Live Preview",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lang: ${languageMap[selectedLanguage]} • Dir: $textDirection • TZ: ${getTimezoneLabel(selectedTimezoneOffset)}",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _previewItem("Date", getFormattedDate(), width, colorScheme)),
                    Expanded(child: _previewItem("Time", getFormattedTime(), width, colorScheme)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _previewItem("Map Center", "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}", width, colorScheme),
                          const SizedBox(height: 6),
                          _previewItem("Zoom", "$zoom", width, colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // DEFAULT LANGUAGE
          _buildSection(
            context: context,
            title: "Default Language",
            subtitle: "Primary language",
            child: DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: _dropdownDecoration(context),
              items: languageMap.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => selectedLanguage = v) : null,
            ),
          ),
          const SizedBox(height: 24),
          // TEXT DIRECTION
          _buildSection(
            context: context,
            title: "Text Direction",
            child: Row(
              children: [
                ChoiceChip(
                  label: Text("LTR"),
                  selected: textDirection == "LTR",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: textDirection == "LTR" ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => textDirection = "LTR"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text("RTL"),
                  selected: textDirection == "RTL",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: textDirection == "RTL" ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => textDirection = "RTL"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // DATE FORMAT
          _buildSection(
            context: context,
            title: "Date Format",
            subtitle: "Display style",
            child: DropdownButtonFormField<String>(
              value: dateFormat,
              decoration: _dropdownDecoration(context),
              items: ["dd MMM yyyy", "MM/dd/yyyy", "yyyy-MM-dd"]
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2)),
                      ))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => dateFormat = v) : null,
            ),
          ),
          const SizedBox(height: 24),
          // TIME FORMAT
          _buildSection(
            context: context,
            title: "Time Format",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("24-hour clock"),
                      selected: timeFormat == "24-hour",
                      selectedColor: colorScheme.primary,
                      labelStyle: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                        color: timeFormat == "24-hour" ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => timeFormat = "24-hour"),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text("12-hour clock"),
                      selected: timeFormat == "12-hour",
                      selectedColor: colorScheme.primary,
                      labelStyle: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                        color: timeFormat == "12-hour" ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => timeFormat = "12-hour"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Example: ${getFormattedTime()}",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // TIMEZONE (now uses region/city labels to avoid confusion)
          _buildSection(
            context: context,
            title: "Timezone",
            child: DropdownButtonFormField<String>(
              value: selectedTimezoneOffset,
              decoration: _dropdownDecoration(context),
              items: timezoneOptions
                  .map((tz) => DropdownMenuItem<String>(
                        value: tz['offset'],
                        child: Text(tz['label']!, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2)),
                      ))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => selectedTimezoneOffset = v) : null,
            ),
          ),
          const SizedBox(height: 24),
          // UNITS
          _buildSection(
            context: context,
            title: "Units",
            child: Row(
              children: [
                ChoiceChip(
                  label: Text("KM"),
                  selected: units == "KM",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: units == "KM" ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => units = "KM"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text("MILES"),
                  selected: units == "MILES",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: units == "MILES" ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => units = "MILES"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // MAP FOCUS
          _buildSection(
            context: context,
            title: "Map Focus",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInputField(context, "LATITUDE", lat.toStringAsFixed(4), (v) => lat = double.tryParse(v) ?? lat)),
                    SizedBox(width: AdaptiveUtils.getLeftSectionSpacing(width).toDouble() * 2),
                    Expanded(child: _buildInputField(context, "LONGITUDE", lng.toStringAsFixed(4), (v) => lng = double.tryParse(v) ?? lng)),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "ZOOM LEVEL",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                Slider(
                  value: zoom.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: colorScheme.primary,
                  label: zoom.toString(),
                  onChanged: (v) => setState(() => zoom = v.toInt()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // BOTTOM BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  selectedLanguage = "EN";
                  textDirection = "LTR";
                  dateFormat = "dd MMM yyyy";
                  timeFormat = "24-hour";
                  selectedTimezoneOffset = "+00:00";
                  units = "KM";
                  lat = 19.0760;
                  lng = 72.8777;
                  zoom = 10;
                }),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(Icons.refresh_outlined, color: colorScheme.onPrimary, size: AdaptiveUtils.getIconSize(width)),
                label: Text(
                  "Reset",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Save logic - e.g., store selectedTimezoneOffset as the offset
                },
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(Icons.save_outlined, color: colorScheme.onPrimary, size: AdaptiveUtils.getIconSize(width)),
                label: Text(
                  "Save",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required BuildContext context, required String title, String? subtitle, Widget? child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) + 2, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.87))),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _previewItem(String label, String value, double width, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3, color: colorScheme.onSurface.withOpacity(0.8))),
      ],
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: AdaptiveUtils.isVerySmallScreen(width) ? 10 : 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  Widget _buildInputField(BuildContext context, String label, String initial, void Function(String) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initial)..selection = TextSelection.fromPosition(TextPosition(offset: initial.length)),
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}
