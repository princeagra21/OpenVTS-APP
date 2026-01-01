// components/fleet/search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({super.key});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final double hp = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double bodyFs = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double iconSize = titleFontSize + 6;

    return Container(
      width: double.infinity,
      height: hp * 3.5,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "Search vehicles, users, devices...",
          hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6), fontSize: bodyFs),
          prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.primary.withOpacity(0.7)),
          border: InputBorder.none,
          focusColor: colorScheme.primary,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.transparent, width: 0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: hp, vertical: hp),
        ),
      ),
    );
  }
}