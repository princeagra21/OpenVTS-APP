// components/home/fleet_overview.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../utils/app_utils.dart';

class FleetOverview extends StatelessWidget {
  const FleetOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.70),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.white.withOpacity(0.65),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row – "Your fleet today" + Date Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your fleet today",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      letterSpacing: 0.4,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Today · 12:00 PM",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Massive Headline Number
              Text(
                "3,577",
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -2,
                  color: isDark ? Colors.white : Colors.black,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Total vehicles across all admins",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),

              const SizedBox(height: 28),

              // Premium Stat Chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatChip("Active", "2,986", Colors.greenAccent, isDark),
                  _buildStatChip("Users", "3,847", Colors.blueAccent, isDark),
                  _buildStatChip("Admins", "267", Colors.orangeAccent, isDark),
                  _buildStatChip("Licenses", "48,234", Colors.purpleAccent, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.4 : 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}