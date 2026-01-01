// screens/teams/add_team_screen.dart
import 'dart:math';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ScrollController _hScrollController = ScrollController();


  String? selectedCountryCode;
  final countryCodes = ["+91 (India)", "+1 (US/Canada)", "+44 (UK)", "+61 (Australia)"];
  
  bool _askChangePassword = true;
  
  late Map<String, Map<String, bool>> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = {
      'Dashboard': {'View': true, 'Create': false, 'Edit': false, 'Delete/Manage': false},
      'Users': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'Vehicles': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'Devices': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'SIM Cards': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'Drivers': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'Payments': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'Finance Plans': {'View': true, 'Create': true, 'Edit': true, 'Delete/Manage': true},
      'Settings': {'View': true, 'Create': false, 'Edit': false, 'Delete/Manage': true},
      'Roles': {'View': true, 'Create': false, 'Edit': false, 'Delete/Manage': true},
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);
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
                    "Add New Team Member",
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
                  "Enter details and assign permissions in one step.",
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
                                label: "Mobile",
                                hint: "Enter mobile number",
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
                          hint: "Enter username",
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
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              final generated = _generatePassword();
                              setState(() {
                                _passwordController.text = generated;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _askChangePassword,
                          onChanged: (v) => setState(() => _askChangePassword = v!),
                          title: Text(
                            "Ask member to change password after first login.",
                            style: GoogleFonts.inter(fontSize: fs - 2),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Permissions",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(w),
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Viewer 10 scopes",
                              style: GoogleFonts.inter(
                                fontSize: fs - 2,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text("Customize as needed"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                       Scrollbar(
  controller: _hScrollController,
  thumbVisibility: true,     // 👈 always visible
  trackVisibility: true,     // 👈 show track (desktop/admin)
  thickness: 6,
  radius: const Radius.circular(8),
  scrollbarOrientation: ScrollbarOrientation.bottom,
  child: SingleChildScrollView(
    controller: _hScrollController,
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Module')),
        DataColumn(label: Text('View')),
        DataColumn(label: Text('Create')),
        DataColumn(label: Text('Edit')),
        DataColumn(label: Text('Delete/Manage')),
      ],
      rows: _permissions.keys.map((module) {
        return DataRow(
          cells: [
            DataCell(Text(module)),
            DataCell(Checkbox(
              value: _permissions[module]!['View'],
              onChanged: (value) {
                setState(() {
                  _permissions[module]!['View'] = value!;
                });
              },
            )),
            DataCell(Checkbox(
              value: _permissions[module]!['Create'],
              onChanged: (value) {
                setState(() {
                  _permissions[module]!['Create'] = value!;
                });
              },
            )),
            DataCell(Checkbox(
              value: _permissions[module]!['Edit'],
              onChanged: (value) {
                setState(() {
                  _permissions[module]!['Edit'] = value!;
                });
              },
            )),
            DataCell(Checkbox(
              value: _permissions[module]!['Delete/Manage'],
              onChanged: (value) {
                setState(() {
                  _permissions[module]!['Delete/Manage'] = value!;
                });
              },
            )),
          ],
        );
      }).toList(),
    ),
  ),
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
                                  "Save Member",
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
  final Widget? suffixIcon;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
    this.suffixIcon,
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
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              suffixIcon: suffixIcon,
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