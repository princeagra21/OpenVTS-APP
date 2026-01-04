// components/admin/edit_admin_profile_screen.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: "Muhammad Sani Yusuf");
  final TextEditingController _emailController =
      TextEditingController(text: "Muhammad@fleetstackglobal.com");
  final TextEditingController _phoneController = TextEditingController(text: "08012345678");
  final TextEditingController _addressController =
      TextEditingController(text: "No4 Dawakin Tofa Science Quarters");
  final TextEditingController _stateController = TextEditingController(text: "KANO");
  final TextEditingController _countryController = TextEditingController(text: "NG");
  final TextEditingController _cityController = TextEditingController(text: "Kano City");
  final TextEditingController _pincodeController = TextEditingController(text: "700001");

  Country? _selectedCountry;

  // Reusable minimal InputDecoration — exactly like ApiConfigSettingsScreen
  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Admin Profile",
                    style: GoogleFonts.inter(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 28, color: colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                "Update admin details",
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Full Name
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Full Name").copyWith(
                          prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: _emailController,
                        style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Email").copyWith(
                          prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Phone + Country Code
                      Row(
                        children: [
                          // Country Code Picker Button (now matches style)
                          GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                onSelect: (Country country) {
                                  setState(() => _selectedCountry = country);
                                },
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Search',
                                    filled: true,
                                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedCountry != null) Text(_selectedCountry!.flagEmoji),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCountry?.phoneCode ?? "234",
                                    style: GoogleFonts.inter(fontSize: 16),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Phone Field
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                              decoration: _minimalDecoration(context, hint: "Phone Number").copyWith(
                                prefixIcon: Icon(Icons.phone_outlined, color: colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Address
                      TextField(
                        controller: _addressController,
                        style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Address").copyWith(
                          prefixIcon: Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Country & State Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _countryController,
                              style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                              decoration: _minimalDecoration(context, hint: "Country Code").copyWith(
                                prefixIcon: Icon(Icons.public, color: colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _stateController,
                              style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                              decoration: _minimalDecoration(context, hint: "State").copyWith(
                                prefixIcon: Icon(Icons.flag_outlined, color: colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // City & Pincode Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                              decoration: _minimalDecoration(context, hint: "City").copyWith(
                                prefixIcon: Icon(Icons.location_city_outlined, color: colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
                              decoration: _minimalDecoration(context, hint: "Pincode").copyWith(
                                prefixIcon: Icon(Icons.pin_drop_outlined, color: colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Save Button — now matches ApiConfig style
                      GestureDetector(
                        onTap: () {
                          // TODO: Save changes
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              "Save Changes",
                              style: GoogleFonts.inter(
                                fontSize: labelSize,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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