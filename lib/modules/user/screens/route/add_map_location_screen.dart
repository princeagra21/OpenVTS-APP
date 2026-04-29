import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMapLocationScreen extends StatefulWidget {
  const AddMapLocationScreen({super.key});

  @override
  State<AddMapLocationScreen> createState() => _AddMapLocationScreenState();
}

class _AddMapLocationScreenState extends State<AddMapLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  IconData _selectedIcon = Icons.location_on;

  final List<IconData> _iconOptions = [
    Icons.location_on,
    Icons.place,
    Icons.flag,
    Icons.home,
    Icons.store,
    Icons.star,
  ];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w);
    final fontSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pick Location from Map",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _labelController,
                          hintText: "Label (required)",
                          prefixIcon: Icons.label,
                          fontSize: fontSize,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a label';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Icon selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Icon",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: _iconOptions.map((icon) {
                                final isSelected = icon == _selectedIcon;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedIcon = icon),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? cs.primary : cs.surface,
                                      border: Border.all(
                                        color: cs.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Icon(icon, color: isSelected ? cs.onPrimary : cs.primary),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  foregroundColor: cs.primary,
                                  side: BorderSide(color: cs.primary),
                                ),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.pop(context, {
                                      'label': _labelController.text.trim(),
                                      'icon': _selectedIcon,
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                ),
                                child: const Text("Continue to Pick"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
