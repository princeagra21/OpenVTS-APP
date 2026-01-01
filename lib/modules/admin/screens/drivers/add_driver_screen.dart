// screens/drivers/add_driver_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedCountryCode;
  String? selectedPrimaryUser;

  final countryCodes = ["+91 (India)", "+1 (US/Canada)", "+44 (UK)", "+61 (Australia)"];
  final users = ["John Doe", "Fleet Admin", "New User"];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
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
                    "Add New Driver",
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
              Center(
                child: Text(
                  "Add a new driver to your fleet with all required information.",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(w) - 2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
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
                          "Personal Information",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(w),
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Name",
                          hint: "Enter full name",
                          controller: _nameController,
                          prefixIcon: Icons.person_rounded,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        // Phone with country code
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: StylishDropdown(
                                label: "Country Code",
                                hint: "Select code",
                                value: selectedCountryCode,
                                items: countryCodes,
                                onChanged: (v) => setState(() => selectedCountryCode = v),
                                width: w,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: StylishTextField(
                                label: "Phone Number",
                                hint: "Enter phone number",
                                controller: _phoneNumberController,
                                prefixIcon: Icons.phone_rounded,
                                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                                width: w,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Email",
                          hint: "Enter email address",
                          controller: _emailController,
                          prefixIcon: Icons.email_rounded,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Address",
                          hint: "Enter full address (e.g., street, city, state, country)",
                          controller: _addressController,
                          prefixIcon: Icons.location_on_rounded,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Account Information",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(w),
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Username",
                          hint: "Enter username (e.g., @username)",
                          controller: _usernameController,
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 16),

                        StylishTextField(
                          label: "Password",
                          hint: "Enter password",
                          controller: _passwordController,
                          prefixIcon: Icons.lock_rounded,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          width: w,
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "User Assignment",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(w),
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StylishSelectWithAdd(
                          label: "Select Primary User",
                          hint: "Select user",
                          value: selectedPrimaryUser,
                          items: users,
                          onChanged: (v) => setState(() => selectedPrimaryUser = v),
                          onAdd: () {},
                          width: w,
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
                                  "Add Driver",
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
              const SizedBox(height: 20),
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

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
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
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
  fillColor: cs.surface, // or cs.surfaceVariant
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
  filled: true,
  fillColor: cs.surface, // or cs.surfaceVariant
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: cs.primary, width: 2),
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

/// ───────────────────────────────────────────────
/// SELECT WITH ADD BUTTON (USER / IMEI / SIM)
/// ───────────────────────────────────────────────
class StylishSelectWithAdd extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAdd;
  final double width;

  const StylishSelectWithAdd({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onAdd,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;    
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
           style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),),
        const SizedBox(height: 8),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: value,
                    hint: Text(hint),
                    items: items
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: cs.primary),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}