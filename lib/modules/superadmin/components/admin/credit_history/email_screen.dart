// components/admin/credit_history/email_screen.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditHistoryEmailScreen extends StatelessWidget {
  const CreditHistoryEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double inputFontSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: SEND EMAIL + CLOSE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Send Email",
                    style: GoogleFonts.roboto(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 26, color: colorScheme.onSurface),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // CENTERED SUBTITLE
              Center(
                child: Text(
                  "Compose and send an email",
                  style: GoogleFonts.roboto(
                    fontSize: inputFontSize,
                    color: colorScheme.onSurface.withOpacity(0.54),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // INPUT FIELDS
              _buildTextField(
                label: "To",
                fontSize: inputFontSize,
                hint: "Enter recipient email",
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: "CC",
                fontSize: inputFontSize,
                hint: "CC recipient email",
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: "BCC",
                fontSize: inputFontSize,
                hint: "BCC recipient email",
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: "Subject",
                fontSize: inputFontSize,
                hint: "Email subject",
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 12),

              // MESSAGE FIELD
              Expanded(
                child: TextField(
                  maxLines: null,
                  minLines: 5,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.roboto(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: "Message",
                    labelStyle: GoogleFonts.roboto(fontSize: inputFontSize, color: colorScheme.onSurface),
                    hintText: "Type your message here",
                    hintStyle: GoogleFonts.roboto(color: colorScheme.onSurface.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SEND BUTTON
              GestureDetector(
                onTap: () {
                  // TODO: implement send email functionality
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      "Send",
                      style: GoogleFonts.roboto(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // REUSABLE TEXTFIELD
  Widget _buildTextField({
    required String label,
    required double fontSize,
    required String hint,
    required ColorScheme colorScheme,
  }) {
    return TextField(
      style: GoogleFonts.roboto(fontSize: fontSize, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(fontSize: fontSize, color: colorScheme.onSurface),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: colorScheme.onSurface.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
    );
  }
}