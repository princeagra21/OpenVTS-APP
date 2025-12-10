// screens/settings/localization_settings_screen.dart
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
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
  String timezone = "+01:00";
  String units = "KM";
  double lat = 19.0760;
  double lng = 72.8777;
  int zoom = 10;

  final DateTime previewDate = DateTime(2025, 12, 7, 15, 28);
  final List<String> months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
          // TOP BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  selectedLanguage = "EN";
                  textDirection = "LTR";
                  dateFormat = "dd MMM yyyy";
                  timeFormat = "24-hour";
                  timezone = "+01:00";
                  units = "KM";
                  lat = 19.0760;
                  lng = 72.8777;
                  zoom = 10;
                }),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(Icons.refresh_outlined, color: colorScheme.onPrimary),
                label: Text("Reset", style: GoogleFonts.inter(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(Icons.save_outlined, color: colorScheme.onPrimary),
                label: Text("Save", style: GoogleFonts.inter(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          // LIVE PREVIEW
          _buildSection(
            context: context,
            title: "Live Preview",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Lang: $selectedLanguage • Dir: $textDirection • TZ: $timezone", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3, color: colorScheme.onSurface.withOpacity(0.87))),
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
                          _previewItem("Map Center", "$lat, $lng", width, colorScheme),
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
              items: ["EN", "FR", "ES", "DE"].map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
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
                  label: Text("LTR"), selected: textDirection == "LTR",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(color: textDirection == "LTR" ? colorScheme.onPrimary : colorScheme.onSurface),
                  onSelected: (_) => setState(() => textDirection = "LTR"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text("RTL"), selected: textDirection == "RTL",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(color: textDirection == "RTL" ? colorScheme.onPrimary : colorScheme.onSurface),
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
              items: ["dd MMM yyyy", "MM/dd/yyyy", "yyyy-MM-dd"].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
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
                      label: Text("24-hour clock", ), selected: timeFormat == "24-hour",
                      selectedColor: colorScheme.primary,
                      labelStyle: GoogleFonts.inter(color: timeFormat == "24-hour" ? colorScheme.onPrimary : colorScheme.onSurface, ),
                      onSelected: (_) => setState(() => timeFormat = "24-hour"),
                    ),
                    const SizedBox(width:12),
                    ChoiceChip(
                      label: Text("12-hour clock"), selected: timeFormat == "12-hour",
                      selectedColor: colorScheme.primary,
                      labelStyle: GoogleFonts.inter(color: timeFormat == "12-hour" ? colorScheme.onPrimary : colorScheme.onSurface),
                      onSelected: (_) => setState(() => timeFormat = "12-hour"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Example: ${getFormattedTime()}", style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.8))),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TIMEZONE
          _buildSection(
            context: context,
            title: "Timezone",
            child: DropdownButtonFormField<String>(
              value: timezone,
              decoration: _dropdownDecoration(context),
              items: ["+00:00", "+01:00", "+02:00", "-05:00"].map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
              onChanged: (v) => v != null ? setState(() => timezone = v) : null,
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
                  label: Text("KM"), selected: units == "KM",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(color: units == "KM" ? colorScheme.onPrimary : colorScheme.onSurface),
                  onSelected: (_) => setState(() => units = "KM"),
                ),
                const SizedBox(width:12),
                ChoiceChip(
                  label: Text("MILES"), selected: units == "MILES",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(color: units == "MILES" ? colorScheme.onPrimary : colorScheme.onSurface),
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
                    const SizedBox(width:16),
                    Expanded(child: _buildInputField(context, "LONGITUDE", lng.toStringAsFixed(4), (v) => lng = double.tryParse(v) ?? lng)),
                  ],
                ),
                const SizedBox(height:24),
                Text("ZOOM LEVEL", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87))),
                Slider(
                  value: zoom.toDouble(),
                  min: 1, max: 20, divisions: 19,
                  activeColor: colorScheme.primary,
                  label: zoom.toString(),
                  onChanged: (v) => setState(() => zoom = v.toInt()),
                ),
              ],
            ),
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
            Text(subtitle, style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.8))),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87))),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initial)..selection = TextSelection.fromPosition(TextPosition(offset: initial.length)),
          onChanged: onChanged,
          style: GoogleFonts.inter(color: colorScheme.onSurface),
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