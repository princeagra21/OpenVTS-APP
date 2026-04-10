import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/user/screens/drivers/driver_screen.dart';
import 'package:fleet_stack/modules/user/screens/sub_users/sub_user_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _selectedTab = 'Drivers';

  final List<String> _tabs = const [
    'Drivers',
    'Sub Users',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 12.0
        : AdaptiveUtils.isSmallScreen(width)
            ? 14.0
            : 18.0;
    final topPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(width)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 70,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NavigateBox(
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'Accounts',
                  subtitle: 'Switch between account sections below.',
                  onTabSelected: (tab) => setState(() => _selectedTab = tab),
                ),
                const SizedBox(height: 16),
                if (_selectedTab == 'Drivers')
                  DriverScreen(embedded: true)
                else
                  SubUserScreen(embedded: true),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: UserHomeAppBar(
              title: 'Accounts',
              leadingIcon: Icons.group_outlined,
              onClose: () => context.go('/user/home'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigateBox extends StatelessWidget {
  final String selectedTab;
  final List<String> tabs;
  final String title;
  final String subtitle;
  final ValueChanged<String> onTabSelected;

  const _NavigateBox({
    required this.selectedTab,
    required this.tabs,
    required this.title,
    required this.subtitle,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSubtitle = 12 * scale;
    final double fsTab = 13 * scale;

    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: fsSubtitle,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tabs.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SmallTab(
                      label: tab,
                      selected: selectedTab == tab,
                      fontSize: fsTab,
                      onTap: () => onTabSelected(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final double? fontSize;
  final VoidCallback? onTap;

  const _SmallTab({
    required this.label,
    this.selected = false,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double defaultFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 420 ? 10 : 14,
          vertical: screenWidth < 420 ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? defaultFontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
