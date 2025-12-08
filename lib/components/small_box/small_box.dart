import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmallTab extends StatefulWidget {
  final String label;
  final bool? selected;       // optional, defaults to true
  final double? fontSize;     // optional, defaults to current value
  final VoidCallback? onTap;

  const SmallTab({
    super.key,
    required this.label,
    this.selected,
    this.fontSize,
    this.onTap,
  });

  @override
  _SmallTabState createState() => _SmallTabState();
}

class _SmallTabState extends State<SmallTab> {
  late bool isSelected;

  @override
  void initState() {
    super.initState();
    // default to true if not provided
    isSelected = widget.selected ?? true;
  }

  void toggleSelected() {
    setState(() {
      isSelected = true; // required tab always true on tap
    });
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;
    final double calculatedFontSize = widget.fontSize ??
        (isSmallScreen ? 10.58 : 11.96); // default behavior

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: toggleSelected,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 14,
          vertical: isSmallScreen ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: calculatedFontSize,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
