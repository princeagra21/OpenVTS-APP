// components/charts/vehicle_status_box.dart
// (Unchanged, as per request - no vehicle status in revenue, but conditional in home)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

class VehicleStatusBox extends StatefulWidget {
  const VehicleStatusBox({super.key});

  @override
  State<VehicleStatusBox> createState() => _VehicleStatusBoxState();
}

class _VehicleStatusBoxState extends State<VehicleStatusBox> {
  final List<Map<String, dynamic>> statusData = [
    {"label": "Running",           "count": "2,986", "percent": 26.6},
    {"label": "Stop",              "count": "111",   "percent": 0.99},
    {"label": "Not Working (48h)", "count": "7,194", "percent": 64.08},
    {"label": "No Data",           "count": "935",   "percent": 8.33},
  ];

  Color _lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final int red = (color.red + (255 - color.red) * amount).round();
    final int green = (color.green + (255 - color.green) * amount).round();
    final int blue = (color.blue + (255 - color.blue) * amount).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final int red = (color.red * (1 - amount)).round();
    final int green = (color.green * (1 - amount)).round();
    final int blue = (color.blue * (1 - amount)).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  Map<String, dynamic> getStatusMeta(String label) {
    final key = label.toLowerCase();
    if (key.startsWith('running')) {
      return {
        'color': Colors.green,
        'icon': Icons.check,
      };
    } else if (key.startsWith('stop')) {
      return {
        'color': Colors.yellow[700]!,
        'icon': Icons.warning_amber_rounded,
      };
    } else if (key.contains('not work') || key.contains('not working')) {
      return {
        'color': Colors.redAccent,
        'icon': Icons.error_outline,
      };
    } else if (key.contains('no data')) {
      return {
        'color': Colors.grey[400]!,
        'icon': null,
      };
    } else {
      return {
        'color': Colors.grey[400]!,
        'icon': null,
      };
    }
  }

  List<Color> getColors(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final modeBrightness = Theme.of(context).brightness;
    final primaryBrightness = ThemeData.estimateBrightnessForColor(primary);

    if (modeBrightness == primaryBrightness) {
      if (primaryBrightness == Brightness.dark) {
        final shifted = _lighten(primary, 0.4);
        return [
          shifted,
          _darken(shifted, 0.2),
          _darken(shifted, 0.4),
          _darken(shifted, 0.6),
        ];
      } else {
        final shifted = _darken(primary, 0.4);
        return [
          shifted,
          _lighten(shifted, 0.2),
          _lighten(shifted, 0.4),
          _lighten(shifted, 0.6),
        ];
      }
    } else {
      return [
        primary,
        _darken(primary, 0.3),
        _darken(primary, 0.5),
        _darken(primary, 0.7),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double legendFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.2,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.directions_car,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: padding),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vehicle Status",
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    "Live distribution",
                    style: GoogleFonts.inter(
                      fontSize: descriptionFontSize,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: spacing + 6),

          // --- Bullet list with fixed status color & icons ---
          Column(
            children: statusData.asMap().entries.map((entry) {
              final data = entry.value;
              final meta = getStatusMeta(data["label"] as String);
              final Color dotColor = meta['color'] as Color;
              final IconData? innerIcon = meta['icon'] as IconData?;

              const double bulletSize = 18.0;
              const double innerIconSize = 12.0;

              final double percentValue = (data["percent"] as num).toDouble();

              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing / 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // colored bullet with optional icon
                    Container(
                      width: bulletSize,
                      height: bulletSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                      child: innerIcon != null
                          ? Center(
                              child: Icon(
                                innerIcon,
                                size: innerIconSize,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),

                    SizedBox(width: spacing),

                    // Label
                    Expanded(
                      child: Text(
                        data["label"] as String,
                        style: GoogleFonts.inter(
                          fontSize: legendFontSize,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                    ),

                    // Count + Percent (right aligned)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data["count"] as String,
                          style: GoogleFonts.inter(
                            fontSize: legendFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        // <-- Updated: plain percentage text in parentheses
                        Text(
  '(${(data["percent"] as double).toStringAsFixed(1)}%)',
  style: GoogleFonts.inter(
    fontSize: legendFontSize,
    fontWeight: FontWeight.w600,
    color: dotColor, // 👈 status color
  ),
),

                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          SizedBox(height: padding),
        ],
      ),
    );
  }
}