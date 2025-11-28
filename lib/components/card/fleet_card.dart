import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Reusable CustomBox widget
class CustomBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const CustomBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }
}

// Fleet Overview Box
class FleetOverviewBox extends StatelessWidget {
  const FleetOverviewBox({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBox(
      radius: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your fleet Today",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Today 12M",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // --- Big number ---
          Text(
            "3579",
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 6),

          // --- Description ---
          Text(
            "Total Vehicles across all admins",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          // --- Capsules ---
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _capsule(context, "Active 2300"),
              _capsule(context, "Users 2097"),
              _capsule(context, "Admins 234"),
              _capsule(context, "Licenses used 34298"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _capsule(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}
