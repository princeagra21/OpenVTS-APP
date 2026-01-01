import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickOverviewScreen extends StatelessWidget {
  final String fileName;

  const QuickOverviewScreen({
    super.key,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      fileName,
                      style: GoogleFonts.inter(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 26, color: colorScheme.onSurface),
                  )
                ],
              ),

              const SizedBox(height: 12),

              // SUBTITLE
              Text(
                "Quick Overview",
                style: GoogleFonts.inter(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 20),

              // PREVIEW BOX
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 150),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    "No preview available",
                    style: TextStyle(
                      fontSize: labelSize,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // (Optional) Add more sections later
            ],
          ),
        ),
      ),
    );
  }
}