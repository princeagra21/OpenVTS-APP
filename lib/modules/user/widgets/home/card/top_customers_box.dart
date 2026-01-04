// components/top_customers_box.dart  // New file, similar to RecentActivityBox but adapted
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackground;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double hPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) - 4;
    final double vPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class TopCustomersBox extends StatefulWidget {
  const TopCustomersBox({super.key});

  @override
  State<TopCustomersBox> createState() => _TopCustomersBoxState();
}

class _TopCustomersBoxState extends State<TopCustomersBox> {
  Map<String, Color> getTierColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      "Enterprise": colorScheme.primary,
      "Pro": colorScheme.secondary,
      "Growth": Colors.green,
    };
  }

  late final List<Map<String, dynamic>> topCustomers;

  @override
  void initState() {
    super.initState();

    topCustomers = [
      {"name": "Acme Logistics", "vehicles": "418", "tier": "Enterprise"},
      {"name": "Northline", "vehicles": "126", "tier": "Pro"},
      {"name": "Sunroad", "vehicles": "88", "tier": "Growth"},
      {"name": "IndiTrans", "vehicles": "62", "tier": "Pro"},
    ];
  }

  Widget buildCustomerItem(Map<String, dynamic> customer) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final tierColors = getTierColors(context);

    final name = customer["name"] as String;
    final initials = name.split(" ").map((e) => e[0]).take(2).join();

    /*

    final avatar = CircleAvatar(
      radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
      backgroundColor: colorScheme.primary.withOpacity(0.1),
      child: Text(initials,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary)),
    );
    */

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: GoogleFonts.inter(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600)),
        Text("${customer["vehicles"]} Vehicles",
            style: GoogleFonts.inter(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54))),
      ],
    );

    final right = Container(
      padding: EdgeInsets.symmetric(
          horizontal: itemPadding + 2,
          vertical: itemPadding - 2),
      decoration: BoxDecoration(
        color: tierColors[customer["tier"]],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(customer["tier"],
          style: GoogleFonts.inter(
              color: colorScheme.onPrimary,
              fontSize: badgeFontSize)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
        //  avatar,
          SizedBox(width: itemPadding + 2),
          Expanded(child: content),
          SizedBox(width: itemPadding + 2),
          right,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double linkFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Customers",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              InkWell(
                onTap: () {
                  context.push(
                    '/admin/all-customers',
                  );
                },
                child: Text("View all",
                    style: GoogleFonts.inter(
                        fontSize: linkFontSize,
                        color: colorScheme.primary)),
              ),
            ],
          ),
          SizedBox(height: padding),
          SizedBox(
            height: 320,
            child: ListView.separated(
              itemCount: topCustomers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.onSurface.withOpacity(0.08),
              ),
              itemBuilder: (_, i) => buildCustomerItem(topCustomers[i]),
            ),
          ),
        ],
      ),
    );
  }
}