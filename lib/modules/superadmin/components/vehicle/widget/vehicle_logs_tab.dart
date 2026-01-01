// components/vehicle/widget/vehicle_logs_tab.dart
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String get formattedRange {
    final start = _selectedRange[0];
    final end = _selectedRange[1];
    if (start == null || end == null) return "Select date range";
    return "${_formatDate(start)} – ${_formatDate(end)}";
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _pickDateRange() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(350, 380),
      value: _selectedRange,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
      ),
    );

    if (results != null && results.length == 2) {
      setState(() => _selectedRange = results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final double smallFs = fs - 2;

    return SingleChildScrollView(           // This is the key
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(hp),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,          // Important!
            children: [
              // HEADER
              Row(
                children: [
                  Icon(Icons.list_alt_rounded,
                      size: fs + 4,
                      color: colorScheme.primary),
                  SizedBox(width: hp / 2),
                  Text("Vehicle Logs",
                      style: GoogleFonts.inter(
                          fontSize: fs + 2,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Generate and filter vehicle GPS logs",
                style: GoogleFonts.inter(
                    fontSize: smallFs,
                    color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),

              // DATE RANGE PICKER
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: hp, vertical: hp * 0.9),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: colorScheme.primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month,
                          size: fs + 4, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(formattedRange,
                          style: GoogleFonts.inter(
                              fontSize: fs, color: colorScheme.onSurface)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SEARCH FIELD
              TextField(
                style: GoogleFonts.inter(
                    fontSize: fs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText:
                      "Search by IMEI, coordinate, attributes...",
                  hintStyle: GoogleFonts.inter(
                      fontSize: fs,
                      color: colorScheme.onSurface.withOpacity(0.6)),
                  prefixIcon:
                      Icon(Icons.search, size: fs + 4, color: colorScheme.primary),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: hp * 0.9),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: colorScheme.outline.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: colorScheme.primary, width: 2)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.file_download,
                          size: fs + 2, color: colorScheme.primary),
                      label: Text("Export CSV",
                          style: GoogleFonts.inter(
                              fontSize: fs,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: hp * 0.9),
                        side: BorderSide(
                            color: colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.email,
                          size: fs + 2, color: colorScheme.primary),
                      label: Text("Email",
                          style: GoogleFonts.inter(
                              fontSize: fs,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: hp * 0.9),
                        side: BorderSide(
                            color: colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // EMPTY STATE
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(hp * 2),
                decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Icon(Icons.insert_drive_file_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text("No Logs Found",
                        style: GoogleFonts.inter(
                            fontSize: fs + 2,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withOpacity(0.8))),
                    const SizedBox(height: 6),
                    Text(
                      "Try adjusting your date range or search filter",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: smallFs,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // extra safe space
            ],
          ),
        ),
      ),
    );
  }
}