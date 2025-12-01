import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class CreditHistoryEmailScreen extends StatelessWidget {
  const CreditHistoryEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double inputFontSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP ROW: SEND EMAIL + CLOSE ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Send Email",
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 26),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- CENTERED SUBTITLE ----------
              Center(
                child: Text(
                  "Compose and send an email",
                  style: GoogleFonts.inter(
                    fontSize: inputFontSize,
                    color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------- INPUT FIELDS ----------
              _buildTextField(label: "To", fontSize: inputFontSize, hint: "Enter recipient email"),
              const SizedBox(height: 12),
              _buildTextField(label: "CC", fontSize: inputFontSize, hint: "CC recipient email"),
              const SizedBox(height: 12),
              _buildTextField(label: "BCC", fontSize: inputFontSize, hint: "BCC recipient email"),
              const SizedBox(height: 12),
              _buildTextField(label: "Subject", fontSize: inputFontSize, hint: "Email subject"),
              const SizedBox(height: 12),

              // ---------- MESSAGE FIELD ----------
             Expanded(
  child: TextField(
    maxLines: 5, // <-- shows resize handle on desktop/web
    minLines: 5,
    textAlignVertical: TextAlignVertical.top,
    decoration: InputDecoration(
      labelText: "Message",
      labelStyle: GoogleFonts.inter(fontSize: inputFontSize),
      hintText: "Type your message here",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.all(12),
    ),
  ),
),

              const SizedBox(height: 16),

              // ---------- SEND BUTTON ----------
              GestureDetector(
                onTap: () {
                  // TODO: implement send email functionality
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      "Send",
                      style: GoogleFonts.inter(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  // ------------------ REUSABLE TEXTFIELD ------------------
  Widget _buildTextField({
    required String label,
    required double fontSize,
    required String hint,
  }) {
    return TextField(
      style: GoogleFonts.inter(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: fontSize),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
