import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
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
    "Terms of Service":
        """Welcome to FleetStack. By accessing or using our platform, you agree to comply with and be bound by these Terms of Service...""",
    "Privacy Policy":
        """We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we handle your personal data...""",
    "Cookie Policy":
        """This website uses cookies to enhance user experience and analyze performance and traffic on our website...""",
    "Refund Policy":
        """We offer refunds within 14 days of purchase if you are not satisfied with our service. To request a refund, please contact support...""",
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
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

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
            // Main Header Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  // -----------------------------------------------------------------
                  // BUTTONS AT THE VERY TOP (aligned to the right)
                  // -----------------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedPolicy = "Terms of Service";
                            _updatePolicyContent();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: hp + 2,
                            vertical: hp - 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_outlined,
                            color: Colors.white),
                        label: Text(
                          "Reset All",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Save all changes
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: hp + 2,
                            vertical: hp - 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined,
                            color: Colors.white),
                        label: Text(
                          "Save All",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------------
                  // TITLE + DESCRIPTION (now below the buttons)
                  // -----------------------------------------------------------------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "User Policy Management",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Create and manage legal agreements for your users",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Policy Selection Dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Policy to Edit",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(width),
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                          child: DropdownButton<String>(
                            value: selectedPolicy,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            underline: const SizedBox(),
                            style: GoogleFonts.inter(
                              color: Colors.black,
                             fontSize: AdaptiveUtils.getTitleFontSize(width),
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedPolicy = newValue;
                                  _updatePolicyContent();
                                });
                              }
                            },
                            items: policies.keys
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Policy Content Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size:
                                  AdaptiveUtils.getTitleFontSize(width) + 5,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedPolicy,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getTitleFontSize(width) + 2,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Configure the policy content and settings",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Word count + Reset to Template button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${policyController.text.trim().split(' ').length} words",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                        5,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  policyController.text =
                                      policies[selectedPolicy] ?? "";
                                });
                              },
                              child: Text(
                                "Reset to Template",
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Policy TextField
                        TextField(
                          controller: policyController,
                          maxLines: null,
                          minLines: 15,
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: AdaptiveUtils.getTitleFontSize(width),
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter policy content here...",
                            hintStyle: GoogleFonts.inter(
                              color: Colors.black.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Plain text format. Updates will be reflected immediately for users.",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 6,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
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

  @override
  void dispose() {
    policyController.dispose();
    super.dispose();
  }
}