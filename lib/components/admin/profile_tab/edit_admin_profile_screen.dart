// components/admin/edit_admin_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_picker/country_picker.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  // Controllers for the textfields
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
                    "Edit Admin Profile",
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
                  "Update admin details",
                  style: GoogleFonts.inter(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------- Full Name ----------
              _buildTextField(controller: _nameController, hint: "Full Name"),

              const SizedBox(height: 12),

              // ---------- Email ----------
              _buildTextField(controller: _emailController, hint: "Email"),

              const SizedBox(height: 12),

              // ---------- Phone with country picker ----------
              Row(
                children: [
                 GestureDetector(
  onTap: () {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: GoogleFonts.inter(fontSize: 16, color: Colors.black),
        bottomSheetHeight: 500, // optional, adjust height
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Text(
          _selectedCountry != null ? "+${_selectedCountry!.phoneCode}" : "+234",
          style: GoogleFonts.inter(fontSize: 16),
        ),
        const SizedBox(width: 4),
        if (_selectedCountry != null)
          Text(_selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 18)),
        const Icon(Icons.arrow_drop_down),
      ],
    ),
  ),
),

                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(controller: _phoneController, hint: "Phone Number"),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ---------- Address ----------
              _buildTextField(controller: _addressController, hint: "Address"),

              const SizedBox(height: 12),

              // ---------- Country Code & State ----------
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(controller: _countryController, hint: "Country Code"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(controller: _stateController, hint: "State Code"),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ---------- City & Pincode ----------
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(controller: _cityController, hint: "City Name"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(controller: _pincodeController, hint: "Pincode"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------- Save Changes ----------
              _infinityButton(
                text: "Save Changes",
                onTap: () {
                  // TODO: implement save logic
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
  Widget _buildTextField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Reusable full-width button
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
