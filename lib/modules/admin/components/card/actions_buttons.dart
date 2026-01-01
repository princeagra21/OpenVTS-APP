// components/fleet/actions_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../utils/adaptive_utils.dart';

class ActionsButtons extends StatelessWidget {
  const ActionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final double hp = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double iconSize = titleFontSize + 6;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    // <-- tweak this to control how rounded the buttons are
    final double btnRadius = 12; // try 8 or 6 for less rounding

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          // Left button -> filled primary (announcement / speaker)
          Expanded(
            child: Material(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(btnRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(btnRadius),
                onTap: () {
                  context.push('/admin/notify-user');
                },
                splashColor: colorScheme.onPrimary.withOpacity(0.12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: spacing,
                    horizontal: spacing,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign,
                        size: iconSize,
                        color: colorScheme.onPrimary,
                      ),
                      SizedBox(width: spacing),
                      Text(
                        'Notify Users',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: spacing),

          // Right button -> outlined (buy credit / coins)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(btnRadius),
                onTap: () {
                  // TODO: buy credit logic
                },
                splashColor: colorScheme.primary.withOpacity(0.08),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: spacing,
                    horizontal: spacing,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(btnRadius),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.05), width: 1.5),
                    color: colorScheme.primary.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.database_upload,
                        size: iconSize,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: spacing),
                      Text(
                        'Buy Credits',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
