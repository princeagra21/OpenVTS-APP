// components/admin/add_new_admin_screen.dart
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/adaptive_utils.dart';

class AddNewAdminScreen extends StatefulWidget {
  const AddNewAdminScreen({super.key});

  @override
  State<AddNewAdminScreen> createState() => _AddNewAdminScreenState();
}

class _AddNewAdminScreenState extends State<AddNewAdminScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();

  Country? _selectedCountry;

  // Reusable minimal InputDecoration — matching the style
  InputDecoration _minimalDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surface.withOpacity(0.05), // Subtle fill for depth
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }

  // Reusable label style
  TextStyle _labelStyle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double labelSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return GoogleFonts.inter(
      fontSize: labelSize - 2,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withOpacity(0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(w);
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);     // ~18–22
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);        // ~14–16

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add New Admin",
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, size: 28, color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Create a new admin account",
                  style: GoogleFonts.inter(
                    fontSize: labelSize + 2,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      Text("Full Name", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter full name").copyWith(
                          prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email
                      Text("Email", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter email").copyWith(
                          prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Phone
                      Text("Phone Number", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Country Code Picker Button (styled to match fields)
                          GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: true,
                                onSelect: (Country country) {
                                  setState(() => _selectedCountry = country);
                                },
                                countryListTheme: CountryListThemeData(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  inputDecoration: InputDecoration(
                                    hintText: 'Search',
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                              height: 54, // Match field height approx
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedCountry != null) Text(_selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "+${_selectedCountry?.phoneCode ?? '234'}",
                                    style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
                              style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                              decoration: _minimalDecoration(context, hint: "Enter phone number").copyWith(
                                prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Username
                      Text("Username", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter username").copyWith(
                          prefixIcon: Icon(Icons.account_circle_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Password
                      Text("Password", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter password").copyWith(
                          prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Company Name
                      Text("Company Name", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _companyController,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter company name").copyWith(
                          prefixIcon: Icon(Icons.business_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Address
                      Text("Address", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter address").copyWith(
                          prefixIcon: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Country & State
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Country", style: _labelStyle(context)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _countryController,
                                  style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                                  decoration: _minimalDecoration(context, hint: "Enter country code").copyWith(
                                    prefixIcon: Icon(Icons.public, color: Theme.of(context).colorScheme.primary, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("State", style: _labelStyle(context)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _stateController,
                                  style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                                  decoration: _minimalDecoration(context, hint: "Enter state").copyWith(
                                    prefixIcon: Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // City & Pincode
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("City", style: _labelStyle(context)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _cityController,
                                  style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                                  decoration: _minimalDecoration(context, hint: "Enter city").copyWith(
                                    prefixIcon: Icon(Icons.location_city_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Pincode", style: _labelStyle(context)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                                  decoration: _minimalDecoration(context, hint: "Enter pincode").copyWith(
                                    prefixIcon: Icon(Icons.pin_drop_outlined, color: Theme.of(context).colorScheme.primary, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Credits
                      Text("Credits", style: _labelStyle(context)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _creditsController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width), color: Theme.of(context).colorScheme.onSurface),
                        decoration: _minimalDecoration(context, hint: "Enter credits").copyWith(
                          prefixIcon: Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Add Button ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Validate inputs and add new admin (e.g., API call)
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            "Add Admin",
                            style: GoogleFonts.inter(
                              fontSize: labelSize + 2,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
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