import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class VehicleLogsTab extends StatefulWidget {
  const VehicleLogsTab({super.key});

  @override
  State<VehicleLogsTab> createState() => _VehicleLogsTabState();
}

class _VehicleLogsTabState extends State<VehicleLogsTab> {
  List<DateTime?> _selectedRange = [
    DateTime.now(),
    DateTime.now().add(const Duration(days: 1)),
  ];

  final Color blackColor = Colors.black; // single source of truth for black

  String get formattedRange {
    final start = _selectedRange[0];
    final end = _selectedRange[1];

    if (start == null || end == null) return "";

    return "${_formatDate(start)} - ${_formatDate(end)}";
  }

  String _formatDate(DateTime date) {
    return "${_month(date.month)} ${date.day}, ${date.year}";
  }

  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  Future<void> _pickDateRange() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(350, 350),
      value: _selectedRange,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: blackColor,
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        dayTextStyle: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.w500,
        ),
        todayTextStyle: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
        ),
        controlsTextStyle: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        okButtonTextStyle: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
        ),
        cancelButtonTextStyle: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (results != null) {
      setState(() => _selectedRange = results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Responsive values
    final double buttonWidth = screenWidth < 420 ? 120 : 150;
    final double iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final double fontSize = screenWidth < 420 ? 12 : 14;
    final double textFieldPadding = screenWidth < 420 ? 10 : 14;
    final double emptyStatePadding = screenWidth < 420 ? 20 : 30;

    // Cyclic rounded radius for text fields
    final double textFieldRadius = screenWidth < 360
        ? 8
        : screenWidth < 420
            ? 10
            : 12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            children: [
              Icon(Icons.list_alt_rounded, size: iconSize, color: blackColor),
              SizedBox(width: AdaptiveUtils.getLeftSectionSpacing(screenWidth)),
              Text(
                "Vehicle Logs",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(screenWidth),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 4),

          Text(
            "Generate and filter vehicle GPS logs",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 20),

          /// DATE RANGE TEXTFIELD
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: textFieldPadding, vertical: textFieldPadding),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(textFieldRadius),
                border: Border.all(color: blackColor, width: 1.3),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, size: iconSize, color: blackColor),
                  SizedBox(width: 10),
                  Text(
                    formattedRange,
                    style: GoogleFonts.inter(fontSize: fontSize),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          /// SEARCH TEXT FIELD
          TextField(
            style: GoogleFonts.inter(fontSize: fontSize),
            decoration: InputDecoration(
              hintText: "Search by IMEI, coordinate, attributes...",
              hintStyle: GoogleFonts.inter(fontSize: fontSize),
              prefixIcon: Icon(Icons.search, size: iconSize, color: blackColor),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(vertical: textFieldPadding),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(textFieldRadius),
                borderSide: BorderSide(color: blackColor, width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(textFieldRadius),
                borderSide: BorderSide(color: blackColor, width: 1.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(textFieldRadius),
                borderSide: BorderSide(color: blackColor),
              ),
            ),
          ),

          SizedBox(height: 20),

          /// BUTTONS → CENTER + SAME SIZE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.file_download, size: iconSize, color: blackColor),
                  label: Text(
                    "Export CSV",
                    style: GoogleFonts.inter(fontSize: fontSize, color: blackColor),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: textFieldPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(textFieldRadius),
                      side: BorderSide(color: blackColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.email, size: iconSize, color: blackColor),
                  label: Text(
                    "Email",
                    style: GoogleFonts.inter(fontSize: fontSize, color: blackColor),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: textFieldPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(textFieldRadius),
                      side: BorderSide(color: blackColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 30),

          /// EMPTY STATE BOX
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(emptyStatePadding),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(textFieldRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file, size: 40, color: blackColor),
                SizedBox(height: 12),
                Text(
                  "No Logs Found",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Try adjusting your date range or search filter",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
