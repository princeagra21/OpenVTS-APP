import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicStatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String subtitle;

  const GlassmorphicStatCard({
    super.key,
    required this.icon,
    required this.number,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), // smaller
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16, // smaller blur
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.2),
                  isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.white.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.08 : 0.2),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Subtitle and Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10, // smaller
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white.withOpacity(0.75)
                            : Colors.black.withOpacity(0.65),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5), // smaller
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 16, // smaller
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6), // spacing before number

                // 🔢 Number below
                Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 20, // smaller
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
