// screens/policy/policy_edit_screen.dart
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PolicyEditScreen extends StatefulWidget {
  const PolicyEditScreen({super.key});

  @override
  State<PolicyEditScreen> createState() => _PolicyEditScreenState();
}

class _PolicyEditScreenState extends State<PolicyEditScreen> {
  String selectedPolicy = "Terms of Service";

  final Map<String, String> policies = {
    "Terms of Service": "Welcome to FleetStack. By accessing or using our platform, you agree to comply with and be bound by these Terms of Service...",
    "Privacy Policy": "We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we handle your personal data...",
    "Cookie Policy": "This website uses cookies to enhance user experience and analyze performance and traffic on our website...",
    "Refund Policy": "We offer refunds within 14 days of purchase if you are not satisfied with our service. To request a refund, please contact support...",
  };

  late TextEditingController policyController;

  @override
  void initState() {
    super.initState();
    policyController = TextEditingController(text: policies[selectedPolicy]);
  }

  void _updatePolicyContent() {
    policyController.text = policies[selectedPolicy] ?? "";
  }

  @override
  void didUpdateWidget(covariant PolicyEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePolicyContent();
  }

  @override
  void dispose() {
    policyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "User Policy",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          selectedPolicy = "Terms of Service";
                          _updatePolicyContent();
                        }),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                          padding: EdgeInsets.symmetric(horizontal: hp + 4, vertical: hp - 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
                        label: Text("Reset All", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.symmetric(horizontal: hp + 4, vertical: hp - 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.save_outlined, color: colorScheme.onPrimary),
                        label: Text("Save All", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // TITLE
                  Text("User Policy Management", style: GoogleFonts.inter(fontSize: fs + 6, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withOpacity(0.9))),
                  const SizedBox(height: 8),
                  Text("Create and manage legal agreements for your users", style: GoogleFonts.inter(fontSize: fs - 1, color: colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 32),

                  // POLICY SELECTOR
                  Container(
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select Policy to Edit", style: GoogleFonts.inter(fontSize: fs + 2, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.9))),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedPolicy,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                          ),
                          style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface),
                          dropdownColor: colorScheme.surface,
                          items: policies.keys.map((key) => DropdownMenuItem(value: key, child: Text(key))).toList(),
                          onChanged: (v) => v != null ? setState(() {
                            selectedPolicy = v;
                            _updatePolicyContent();
                          }) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // POLICY EDITOR
                  Container(
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.description_rounded, size: fs + 8, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(selectedPolicy, style: GoogleFonts.inter(fontSize: fs + 4, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.9))),
                        ]),
                        const SizedBox(height: 12),
                        Text("Configure the policy content and settings", style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onSurface.withOpacity(0.7))),
                        const SizedBox(height: 20),

                        // WORD COUNT + RESET
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${policyController.text.trim().split(' ').where((e) => e.isNotEmpty).length} words", style: GoogleFonts.inter(fontSize: fs - 2, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withOpacity(0.8))),
                            TextButton(
                              onPressed: () => setState(() => policyController.text = policies[selectedPolicy] ?? ""),
                              child: Text("Reset to Template", style: GoogleFonts.inter(fontSize: fs - 2, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // TEXT EDITOR
                        TextField(
                          controller: policyController,
                          maxLines: null,
                          minLines: 18,
                          style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface, height: 1.7),
                          decoration: InputDecoration(
                            hintText: "Enter policy content here...",
                            hintStyle: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface.withOpacity(0.5)),
                            filled: true,
                            fillColor: colorScheme.surface,
                            contentPadding: const EdgeInsets.all(20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text("Plain text format. Updates will be reflected immediately for users.", style: GoogleFonts.inter(fontSize: fs - 4, color: colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}