import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 14,
          vertical: isSmallScreen ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
       //   border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 10.58 : 11.96,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
