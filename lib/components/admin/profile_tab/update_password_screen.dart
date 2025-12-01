// components/admin/update_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // Top Row: Title + Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Update Password",
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

              const SizedBox(height: 12),

              // Center text
              Center(
                child: Text(
                  "Securely update your account password",
                  style: GoogleFonts.inter(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- New Password ----------
              _buildTextField(
                controller: _newPasswordController,
                hint: "New Password",
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),

              const SizedBox(height: 12),

              // ---------- Confirm Password ----------
              _buildTextField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- Save Changes ----------
              _infinityButton(
                text: "Update Password",
                onTap: () {
                  // TODO: implement password update logic
                  Navigator.pop(context);
                },
                fontSize: labelSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable textfield
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  // Full-width button
  Widget _infinityButton({required String text, required VoidCallback onTap, required double fontSize}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
