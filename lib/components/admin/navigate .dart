import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigateBox extends StatefulWidget {
  const NavigateBox({super.key});

  @override
  State<NavigateBox> createState() => _NavigateBoxState();
}

class _NavigateBoxState extends State<NavigateBox> {
  String selectedTab = "Profile";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 420;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NAVIGATE",
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 14 : 16,
            //  fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["Profile", "Credit History", "Documents", "Vehicles", "Setting", "Roles"]
                  .map((tab) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8,),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => setState(() => selectedTab = tab),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedTab == tab ? Colors.black : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      //  border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: selectedTab == tab ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}