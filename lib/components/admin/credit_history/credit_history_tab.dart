// components/admin/credit_history_tab.dart
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:fleet_stack/components/admin/credit_history/credit_history_details_screen.dart';
import 'package:fleet_stack/components/admin/credit_history/email_screen.dart';
import 'package:fleet_stack/components/admin/credit_history/add_deduct_credit_screen.dart'; // Add this import
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditHistoryTab extends StatefulWidget {
  const CreditHistoryTab({super.key});

  @override
  State<CreditHistoryTab> createState() => _CreditHistoryTabState();
}

class _CreditHistoryTabState extends State<CreditHistoryTab> {
  DateTime? _startDate;
  DateTime? _endDate;

  void _showDateRangePicker() async {
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: [_startDate, _endDate],
    );

    if (values != null && values.length == 2) {
      setState(() {
        _startDate = values[0];
        _endDate = values[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double descFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 4;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TITLE
              Text(
                "History",
                style: GoogleFonts.inter(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              // DATE RANGE PICKER
              GestureDetector(
                onTap: _showDateRangePicker,
                child: Row(
                  children: [
                    Text(
                      _startDate == null
                          ? "Select Date Range"
                          : "${_startDate!.toIso8601String().substring(0, 10)} - ${_endDate!.toIso8601String().substring(0, 10)}",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today, size: 18, color: colorScheme.onSurface),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // DOWNLOAD + EMAIL + ADD/DEDUCT
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // DOWNLOAD
              GestureDetector(
                onTap: () {
                  // TODO: implement download logic
                },
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      "Download",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // EMAIL
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreditHistoryEmailScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      "Email",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // ADD/DEDUCT CREDIT
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddDeductCreditScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      "Add/Deduct",
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 12),

          // TRANSACTION LIST
          Column(
            children: [
              _buildTransactionItem(
                description: "Credit Added By Super Admin",
                date: "19 Oct 2023, 10:57 am",
                amount: "+8000",
                color: colorScheme.primary,
                descFontSize: descFontSize,
              ),
              _buildTransactionItem(
                description:
                    "1 credit used to add new Device MH05DK7183 (358980100912667)",
                date: "19 Oct 2023, 11:09 am",
                amount: "-1",
                color: colorScheme.error,
                descFontSize: descFontSize,
              ),
              _buildTransactionItem(
                description:
                    "1 credit used to add new Device chasis no-33174 (358980100919886)",
                date: "19 Oct 2023, 1:17 pm",
                amount: "-1",
                color: colorScheme.error,
                descFontSize: descFontSize,
              ),
              _buildTransactionItem(
                description:
                    "1 credit used for device CHASSIS NO 27004 (358980100868752)",
                date: "19 Oct 2023, 1:25 pm",
                amount: "-1",
                color: colorScheme.error,
                descFontSize: descFontSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String description,
    required String date,
    required String amount,
    required Color color,
    required double descFontSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditHistoryDetailsScreen(
              date: date,
              description: description,
              amount: amount,
              balance: "8000",
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}