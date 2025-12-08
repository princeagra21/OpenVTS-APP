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
      subtitle: "localization",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizationHeader(),
            const SizedBox(height: 24),
            // You can add more boxes here if needed
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
  final List<String> months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String getFormattedDate() {
    String day = previewDate.day.toString().padLeft(2, '0');
    String month = previewDate.month.toString().padLeft(2, '0');
    String year = previewDate.year.toString();
    String monthName = months[previewDate.month];

    switch (dateFormat) {
      case "dd MMM yyyy":
        return "$day $monthName $year";
      case "MM/dd/yyyy":
        return "$month/$day/$year";
      case "yyyy-MM-dd":
        return "$year-$month-$day";
      default:
        return "$day $monthName $year";
    }
  }

  String getFormattedTime() {
    String minute = previewDate.minute.toString().padLeft(2, '0');
    if (timeFormat == "24-hour") {
      String hour = previewDate.hour.toString().padLeft(2, '0');
      return "$hour:$minute";
    } else {
      int hour = previewDate.hour % 12 == 0 ? 12 : previewDate.hour % 12;
      String ampm = previewDate.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $ampm";
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- RIGHT BUTTONS (TOP RIGHT) ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedLanguage = "EN";
                        textDirection = "LTR";
                        dateFormat = "dd MMM yyyy";
                        timeFormat = "24-hour";
                        timezone = "+01:00";
                        units = "KM";
                        lat = 19.0760;
                        lng = 72.8777;
                        zoom = 10;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: hp + 2,
                        vertical: hp - 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh_outlined,
                      color: Colors.white,
                      size: AdaptiveUtils.getIconSize(width),
                    ),
                    label: Text(
                      "Reset",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: hp + 2,
                        vertical: hp - 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: AdaptiveUtils.getIconSize(width),
                    ),
                    label: Text(
                      "Save",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16), // space between buttons and text

              // ---------------- LEFT TEXTS ----------------
              Text(
                "Localization Settings",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure language, timezone, date formats, and map focus for your application.",
                softWrap: true,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                  fontWeight: FontWeight.w200,
                  color: Colors.black.withOpacity(0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================== Live Preview ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Live Preview",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Lang: $selectedLanguage • Dir: $textDirection • TZ: $timezone",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
               Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // ---------- HEADER ROW ----------
    Row(
      children: [
        Expanded(
          child: Text(
            "Date",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Time",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            "Map Center",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
      ],
    ),

    SizedBox(height: 4),

    // ---------- VALUES ROW ----------
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            getFormattedDate(),
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w400,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            getFormattedTime(),
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w400,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$lat, $lng",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              Text(
                "Zoom: $zoom",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ],
)

              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Default Language ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Default Language",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Primary language",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(color: Colors.black, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedLanguage = newValue);
                      }
                    },
                    items: <String>["EN", "FR", "ES", "DE"].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Text Direction ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Text Direction",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("LTR"),
                      selected: textDirection == "LTR",
                      onSelected: (bool selected) {
                        setState(() => textDirection = "LTR");
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text("RTL"),
                      selected: textDirection == "RTL",
                      onSelected: (bool selected) {
                        setState(() => textDirection = "RTL");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Date Format ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date Format",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Display style",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: dateFormat,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(color: Colors.black, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => dateFormat = newValue);
                      }
                    },
                    items: <String>["dd MMM yyyy", "MM/dd/yyyy", "yyyy-MM-dd"].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Time Format ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Time Format",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("24-hour clock"),
                      selected: timeFormat == "24-hour",
                      onSelected: (bool selected) {
                        setState(() => timeFormat = "24-hour");
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text("12-hour clock"),
                      selected: timeFormat == "12-hour",
                      onSelected: (bool selected) {
                        setState(() => timeFormat = "12-hour");
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Example: ${getFormattedTime()}",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Timezone ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Timezone",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: timezone,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(color: Colors.black, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => timezone = newValue);
                      }
                    },
                    items: <String>["+00:00", "+01:00", "+02:00", "-05:00"].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Units ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Units",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("KM"),
                      selected: units == "KM",
                      onSelected: (bool selected) {
                        setState(() => units = "KM");
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text("MILES"),
                      selected: units == "MILES",
                      onSelected: (bool selected) {
                        setState(() => units = "MILES");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Map Focus ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Map Focus",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LATITUDE",
                            style: GoogleFonts.inter(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                            ),
                            controller: TextEditingController(text: lat.toStringAsFixed(4)),
                            onChanged: (value) {
                              setState(() => lat = double.tryParse(value) ?? lat);
                            },
                            decoration: _inputDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LONGITUDE",
                            style: GoogleFonts.inter(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                            ),
                            controller: TextEditingController(text: lng.toStringAsFixed(4)),
                            onChanged: (value) {
                              setState(() => lng = double.tryParse(value) ?? lng);
                            },
                            decoration: _inputDecoration(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "ZOOM LEVEL",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: zoom.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: zoom.toString(),
                  activeColor: Colors.black,
                  onChanged: (double value) {
                    setState(() {
                      zoom = value.toInt();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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