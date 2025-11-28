// components/cards/stats_row.dart
import 'package:fleet_stack/components/card/card_starts.dart';
import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Expanded(
                child: GlassmorphicStatCard(
                  icon: Icons.admin_panel_settings,
                  number: "276",
                  subtitle: "All Admins",
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: GlassmorphicStatCard(
                  icon: Icons.directions_car,
                  number: "3,577",
                  subtitle: "Total Vehicles",
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GlassmorphicStatCard(
                  icon: Icons.trending_up,
                  number: "2,986",
                  subtitle: "Active Vehicles",
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: GlassmorphicStatCard(
                  icon: Icons.people,
                  number: "3,847",
                  subtitle: "Total Users",
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GlassmorphicStatCard(
                  icon: Icons.arrow_outward,
                  number: "57,067",
                  subtitle: "License Issued",
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: GlassmorphicStatCard(
                  icon: Icons.verified,
                  number: "48,234",
                  subtitle: "License Used",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}