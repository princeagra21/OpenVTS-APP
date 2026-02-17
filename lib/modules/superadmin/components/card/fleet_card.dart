// components/fleet/fleet_overview_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_total_counts.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

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
    this.radius = 25.0, // default to 25 to match your design
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FleetOverviewBox extends StatefulWidget {
  const FleetOverviewBox({super.key});

  @override
  State<FleetOverviewBox> createState() => _FleetOverviewBoxState();
}

class _FleetOverviewBoxState extends State<FleetOverviewBox> {
  SuperadminTotalCounts? _counts;
  bool _loadingCounts = false;
  bool _countsErrorShown = false;
  CancelToken? _countsCancelToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void dispose() {
    _countsCancelToken?.cancel('FleetOverviewBox disposed');
    super.dispose();
  }

  Future<void> _loadCounts() async {
    _countsCancelToken?.cancel('Reload counts');
    final token = CancelToken();
    _countsCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingCounts = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getTotalCounts(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (counts) {
          if (!mounted) return;
          setState(() {
            _counts = counts;
            _loadingCounts = false;
            _countsErrorShown = false;
          });
        },
        failure: (_) {
          if (!mounted) return;
          setState(() => _loadingCounts = false);
          if (_countsErrorShown) return;
          _countsErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't load counts. Showing fallback data."),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCounts = false);
      if (_countsErrorShown) return;
      _countsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load counts. Showing fallback data."),
        ),
      );
    }
  }

  String _fmtInt(int v) => v.toString();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    // Adaptive values from our design system
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2; // 14–18
    final double bigNumberFontSize =
        titleFontSize * 2.4; // ~34–43, scales perfectly
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    ); // 13–15
    final double capsuleFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    ); // 13–15
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(
      screenWidth,
    ); // 6–10

    const fallbackTotalVehicles = 3579;
    const fallbackActiveVehicles = 2300;
    const fallbackTotalUsers = 2097;
    const fallbackTotalAdmins = 234;
    const fallbackLicensesUsed = 34298;

    final counts = _counts;
    final totalVehicles = counts == null
        ? fallbackTotalVehicles
        : counts.totalVehicles;
    final activeVehicles = counts == null
        ? fallbackActiveVehicles
        : counts.activeVehicles;
    final totalUsers = counts == null ? fallbackTotalUsers : counts.totalUsers;
    final totalAdmins = counts == null
        ? fallbackTotalAdmins
        : counts.totalAdmins;
    final licensesUsed = counts == null
        ? fallbackLicensesUsed
        : counts.licensesUsed;

    return CustomBox(
      radius: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Your fleet Today",
                      style: GoogleFonts.inter(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_loadingCounts)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              //  Container(
              //  padding: EdgeInsets.symmetric(
              //  horizontal: spacing + 4,
              //  vertical: spacing - 2,
              //  ),
              // decoration: BoxDecoration(
              // border: Border.all(color: colorScheme.onSurface, width: 1),
              //             borderRadius: BorderRadius.circular(20),
              ///         ),
              //         child: Text(
              //          "Today 12M",
              //          style: GoogleFonts.inter(
              //            fontSize: badgeFontSize,
              //            fontWeight: FontWeight.w600,
              //            color: colorScheme.onSurface,
              //          ),
              //        ),
              //     ),
            ],
          ),

          SizedBox(height: spacing + 4),

          // Big Number
          Text(
            _fmtInt(totalVehicles),
            style: GoogleFonts.inter(
              fontSize: bigNumberFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),

          SizedBox(height: spacing),

          // Description
          Text(
            "Total Vehicles across all admins",
            style: GoogleFonts.inter(
              fontSize: descriptionFontSize,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),

          SizedBox(height: spacing + 6),

          // Capsules
          Wrap(
            spacing: spacing + 4,
            runSpacing: spacing + 2,
            children: [
              _capsule(
                context,
                "Active ${_fmtInt(activeVehicles)}",
                capsuleFontSize,
                spacing,
              ),
              _capsule(
                context,
                "Users ${_fmtInt(totalUsers)}",
                capsuleFontSize,
                spacing,
              ),
              _capsule(
                context,
                "Admins ${_fmtInt(totalAdmins)}",
                capsuleFontSize,
                spacing,
              ),
              _capsule(
                context,
                "Licenses used ${_fmtInt(licensesUsed)}",
                capsuleFontSize,
                spacing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _capsule(
    BuildContext context,
    String text,
    double fontSize,
    double spacing,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing + 8, vertical: spacing),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999), // TRUE PILL
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
