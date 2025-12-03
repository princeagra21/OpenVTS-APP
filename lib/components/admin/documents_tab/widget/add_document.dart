import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final TextEditingController typeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String? _selectedExpiry;
  String? _selectedFile;

  Future<void> pickExpiryDate() async {
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(12),
      value: [],
    );

    if (result != null && result.isNotEmpty && result.first != null) {
      setState(() {
        _selectedExpiry =
            "${result.first!.day}/${result.first!.month}/${result.first!.year}";
      });
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------ TOP ROW ------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Document",
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 26),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ------------ Document Type ------------
              _inputField(
                controller: typeController,
                label: "Document Type",
                hint: "e.g., Insurance Policy",
              ),

              const SizedBox(height: 16),

              // ------------ Name ------------
              _inputField(
                controller: nameController,
                label: "Name",
                hint: "e.g., Insurance Policy 2025.pdf",
              ),

              const SizedBox(height: 16),

              // ------------ Expiry Date ------------
              Text(
                "Expiry",
                style: GoogleFonts.inter(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: pickExpiryDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    _selectedExpiry ?? "Select date",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black.withOpacity(
                          _selectedExpiry == null ? 0.5 : 1),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ------------ Tags ------------
              _inputField(
                controller: tagsController,
                label: "Tags",
                hint: "e.g., compliance",
              ),

              const SizedBox(height: 24),

              // ------------ Upload Container ------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    style: BorderStyle.solid,
                  ),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  children: [
                    Text(
                      "Drag & drop your file here",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "PDF, Images, DOCX — up to 50 MB",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Choose File Button
                    GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _selectedFile ?? "Choose File",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ------------ Note Optional ------------
              _inputField(
                controller: noteController,
                label: "Note (optional)",
                hint: "Add any additional details",
                maxLines: 3,
              ),

              const SizedBox(height: 26),

              // ------------ Add Document Button ------------
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      "Add Document",
                      style: GoogleFonts.inter(
                        fontSize: labelSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Shared Textfield Widget ----------
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
