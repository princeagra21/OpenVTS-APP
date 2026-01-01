// screens/account/add_user_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? selectedRole;
  String selectedCountryCode = "+91 (India)";

  final roles = ["Admin", "User", "Sub-User", "Driver", "Manager", "Team"];
  final countryCodes = ["+91 (India)", "+1 (US/Canada)", "+44 (UK)", "+971 (UAE)"];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add User",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // ─── FORM ───────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Basic Information",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Full Name",
                          hint: "Enter full name",
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Username",
                          hint: "Enter username",
                          controller: _usernameController,
                          prefixIcon: Icons.account_circle_outlined,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
                              return "Only lowercase letters, numbers, and underscores";
                            }
                            return null;
                          },
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishDropdown(
                          label: "Role",
                          hint: "Select role",
                          value: selectedRole,
                          items: roles,
                          onChanged: (v) =>
                              setState(() => selectedRole = v),
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Password",
                          hint: "Enter password",
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Contact Information",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Email",
                          hint: "Enter email address",
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                              return "Invalid email";
                            }
                            return null;
                          },
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            SizedBox(
                              width: w * 0.4,
                              child: StylishDropdown(
                                label: "Country Code",
                                hint: "Select code",
                                value: selectedCountryCode,
                                items: countryCodes,
                                onChanged: (v) =>
                                    setState(() => selectedCountryCode = v!),
                                width: w,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StylishTextField(
                                label: "Phone Number",
                                hint: "Enter phone number",
                                controller: _phoneController,
                                prefixIcon: Icons.phone_outlined,
                                validator: (v) =>
                                    v == null || v.isEmpty ? "Required" : null,
                                width: w,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                       // ─── ACTION BUTTONS ─────────────────
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(36), // reduced by 30%
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: cs.primary.withOpacity(0.2)),
          ),
        ),
        child: Text(
          "Cancel",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // SUBMIT LOGIC
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(36), // reduced by 30%
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          "Add User",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  ],
),

                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH TEXT FIELD
/// ───────────────────────────────────────────────
class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;
  final bool obscureText;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ───────────────────────────────────────────────
/// STYLISH DROPDOWN
/// ───────────────────────────────────────────────
class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double width;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,      
            iconDisabledColor: cs.primary,     
            focusColor: cs.surface,
            value: value,
            hint: Text(
              hint,
              style: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
            ),
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}