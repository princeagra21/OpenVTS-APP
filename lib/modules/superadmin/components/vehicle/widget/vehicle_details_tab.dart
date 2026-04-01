// components/vehicle/vehicle_details_tab.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsTab extends StatelessWidget {
  final String vehicleId;
  final VehicleDetails? details;

  const VehicleDetailsTab({super.key, required this.vehicleId, this.details});

  String _safe(String? value) {
    if (value == null) return '-';
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _withUnit(String? value, String unit) {
    final safe = _safe(value);
    if (safe == '-') return safe;
    return safe.toLowerCase().contains(unit.toLowerCase())
        ? safe
        : '$safe $unit';
  }

  String _formatDate(String? value) {
    final safe = _safe(value);
    if (safe == '-') return safe;
    final parsed = DateTime.tryParse(safe);
    if (parsed == null) return safe;
    final local = parsed.toLocal();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    final hour = (local.hour % 12 == 0 ? 12 : local.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$day $month ${local.year} • $hour:$minute $suffix';
  }

  String _daysRemaining(String? value) {
    final safe = _safe(value);
    if (safe == '-') return '-';
    final parsed = DateTime.tryParse(safe);
    if (parsed == null) return '-';
    final days = parsed.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return '1 day remaining';
    return '$days days remaining';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final detail = details;

    final speed = _withUnit(detail?.speed, 'km/h');
    final ignition = _safe(detail?.ignition);
    final engineHours = _withUnit(detail?.engineHours, 'h');
    final odometer = _withUnit(detail?.odometer, 'km');
    final vin = _safe(detail?.vin);
    final imei = _safe(detail?.imei);
    final timezone = _safe(detail?.gmtOffset);
    final model = _safe(detail?.model);
    final vehicleType = _safe(detail?.type);
    final simNumber = _safe(detail?.simNumber);
    final simProvider = _safe(detail?.simProviderName);
    final ignitionSource = _safe(
      (detail?.device ?? const <String, dynamic>{})['ignitionSource']
          ?.toString(),
    );
    final planName = _safe(detail?.planName);
    final planPrice = _safe(detail?.planPrice);
    final planCurrency = _safe(detail?.planCurrency);
    final planDays = _safe(detail?.planDurationDays);
    final createdAt = _formatDate(
      (detail?.data ?? const <String, dynamic>{})['createdAt']?.toString(),
    );
    final primaryExpiry = _formatDate(detail?.primaryExpiry);
    final secondaryExpiry = _formatDate(detail?.secondaryExpiry);
    final primaryUserName = _safe(detail?.primaryUserName);
    final primaryUserEmail = _safe(detail?.primaryUserEmail);
    final primaryUserUsername = _safe(detail?.primaryUserUsername);
    final addedByName = _safe(detail?.addedByName);
    final addedByEmail = _safe(detail?.addedByEmail);
    final addedByUsername = _safe(detail?.addedByUsername);
    final driverName = _safe(detail?.driverName);
    final driverEmail = _safe(detail?.driverEmail);
    final driverPhone = _safe(detail?.driverPhone);
    final lastSeen = _formatDate(detail?.lastSeen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsContainer(
          context,
          colorScheme,
          width,
          speed: speed,
          ignition: ignition,
          engineHours: engineHours,
          odometer: odometer,
        ),
        const SizedBox(height: 20),
        _buildIdentifiersContainer(
          context,
          colorScheme,
          width,
          vin: vin,
          imei: imei,
          timezone: timezone,
        ),
        const SizedBox(height: 20),
        _buildMetaContainer(
          colorScheme,
          width,
          model: model,
          vehicleType: vehicleType,
          simNumber: simNumber,
          simProvider: simProvider,
        ),
        const SizedBox(height: 20),
        _buildDeviceSection(
          colorScheme,
          width,
          ignitionSource: ignitionSource,
          planName: planName,
          planPrice: planPrice,
          planCurrency: planCurrency,
          planDays: planDays,
          createdAt: createdAt,
        ),
        const SizedBox(height: 20),
        _buildSubscriptionSection(
          colorScheme,
          width,
          primaryExpiry: primaryExpiry,
          secondaryExpiry: secondaryExpiry,
          primaryRemaining: _daysRemaining(detail?.primaryExpiry),
          secondaryRemaining: _daysRemaining(detail?.secondaryExpiry),
        ),
        const SizedBox(height: 20),
        _buildPeopleSection(
          colorScheme,
          width,
          primaryUserName: primaryUserName,
          primaryUserEmail: primaryUserEmail,
          primaryUserUsername: primaryUserUsername,
          addedByName: addedByName,
          addedByEmail: addedByEmail,
          addedByUsername: addedByUsername,
          driverName: driverName,
          driverEmail: driverEmail,
          driverPhone: driverPhone,
        ),
        const SizedBox(height: 20),
        _buildRecentEventsContainer(
          colorScheme,
          width,
          createdAt: createdAt,
          lastSeen: lastSeen,
          primaryExpiry: primaryExpiry,
          secondaryExpiry: secondaryExpiry,
        ),
        const SizedBox(height: 24),
        DeleteVehicleBox(vehicleId: vehicleId),
        const SizedBox(height: 40),
      ],
    );
  }

  // SECTION HEADER (smaller)
  Widget _buildSectionHeader(
    IconData icon,
    String title,
    ColorScheme scheme,
    double width,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _card(ColorScheme scheme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // VEHICLE STATS
  Widget _buildStatsContainer(
    BuildContext context,
    ColorScheme scheme,
    double width, {
    required String speed,
    required String ignition,
    required String engineHours,
    required String odometer,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.speed, "VEHICLE STATS", scheme, width),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("SPEED", speed, width, context),
              _buildStatItem("IGNITION", ignition, width, context),
              _buildStatItem("ENGINE HOURS", engineHours, width, context),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatItem("ODOMETER", odometer, width, context, fullWidth: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    double width,
    BuildContext context, {
    bool fullWidth = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // IDENTIFIERS
  Widget _buildIdentifiersContainer(
    BuildContext context,
    ColorScheme scheme,
    double width, {
    required String vin,
    required String imei,
    required String timezone,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.badge, "IDENTIFIERS", scheme, width),
          const SizedBox(height: 12),
          _identifier(context, "VIN", vin, width),
          const SizedBox(height: 8),
          _identifier(context, "IMEI", imei, width),
          const SizedBox(height: 8),
          _identifier(context, "Timezone", timezone, width, showCopy: false),
        ],
      ),
    );
  }

  Widget _identifier(
    BuildContext ctx,
    String label,
    String value,
    double width, {
    bool showCopy = true,
  }) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: Icon(Icons.copy, size: 16, color: colorScheme.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text("$label copied")));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetaContainer(
    ColorScheme scheme,
    double width, {
    required String model,
    required String vehicleType,
    required String simNumber,
    required String simProvider,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.list_alt, "VEHICLE META", scheme, width),
          const SizedBox(height: 12),
          _metaRow("Model", model, "Type", vehicleType, width, scheme),
          const SizedBox(height: 8),
          _metaRow(
            "SIM Number",
            simNumber,
            "Provider",
            simProvider,
            width,
            scheme,
          ),
        ],
      ),
    );
  }

  Widget _metaRow(
    String l1,
    String v1,
    String l2,
    String v2,
    double width,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        Expanded(child: _metaItem(l1, v1, width, scheme)),
        const SizedBox(width: 12),
        Expanded(child: _metaItem(l2, v2, width, scheme)),
      ],
    );
  }

  Widget _metaItem(
    String label,
    String value,
    double width,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection(
    ColorScheme scheme,
    double width, {
    required String ignitionSource,
    required String planName,
    required String planPrice,
    required String planCurrency,
    required String planDays,
    required String createdAt,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.memory, "DEVICE & PLAN", scheme, width),
          const SizedBox(height: 12),
          _statRow("Ignition Source", ignitionSource, width, scheme),
          const SizedBox(height: 6),
          _statRow("Plan", planName, width, scheme),
          const SizedBox(height: 6),
          _statRow(
            "Price",
            planPrice == '-'
                ? '-'
                : '$planPrice ${planCurrency == '-' ? '' : planCurrency}'
                      .trim(),
            width,
            scheme,
          ),
          const SizedBox(height: 6),
          _statRow(
            "Duration",
            planDays == '-' ? '-' : '$planDays days',
            width,
            scheme,
          ),
          const SizedBox(height: 6),
          _statRow("Created", createdAt, width, scheme),
        ],
      ),
    );
  }

  Widget _statRow(
    String label,
    String value,
    double width,
    ColorScheme scheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(
    ColorScheme scheme,
    double width, {
    required String primaryExpiry,
    required String secondaryExpiry,
    required String primaryRemaining,
    required String secondaryRemaining,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.calendar_month,
            "SUBSCRIPTION",
            scheme,
            width,
          ),
          const SizedBox(height: 12),
          _subRow("Primary", primaryExpiry, primaryRemaining, width, scheme),
          const SizedBox(height: 8),
          _subRow(
            "Secondary",
            secondaryExpiry,
            secondaryRemaining,
            width,
            scheme,
          ),
        ],
      ),
    );
  }

  Widget _subRow(
    String label,
    String date,
    String daysLeft,
    double width,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                daysLeft,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) - 5,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleSection(
    ColorScheme scheme,
    double width, {
    required String primaryUserName,
    required String primaryUserEmail,
    required String primaryUserUsername,
    required String addedByName,
    required String addedByEmail,
    required String addedByUsername,
    required String driverName,
    required String driverEmail,
    required String driverPhone,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.people, "PEOPLE", scheme, width),
          const SizedBox(height: 12),
          _buildPersonBlock(
            "Primary User",
            primaryUserName,
            primaryUserEmail,
            '-',
            primaryUserUsername == '-' ? '-' : '@$primaryUserUsername',
            width,
            scheme,
          ),
          const SizedBox(height: 16),
          _buildPersonBlock(
            "Added By",
            addedByName,
            addedByEmail,
            '-',
            addedByUsername == '-' ? '-' : '@$addedByUsername',
            width,
            scheme,
          ),
          if (driverName != '-') ...[
            const SizedBox(height: 16),
            _buildPersonBlock(
              "Driver",
              driverName,
              driverEmail,
              driverPhone,
              '-',
              width,
              scheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonBlock(
    String title,
    String name,
    String email,
    String phone,
    String username,
    double width,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (email != '-') ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          if (phone != '-' || username != '-') ...[
            const SizedBox(height: 2),
            Text(
              [phone, username].where((v) => v != '-').join(' • '),
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentEventsContainer(
    ColorScheme scheme,
    double width, {
    required String createdAt,
    required String lastSeen,
    required String primaryExpiry,
    required String secondaryExpiry,
  }) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.history, "RECENT EVENTS", scheme, width),
          const SizedBox(height: 12),
          _buildEventItem("Vehicle created", createdAt, width, scheme),
          if (lastSeen != '-') ...[
            const Divider(height: 16),
            _buildEventItem("Last update", lastSeen, width, scheme),
          ],
          if (primaryExpiry != '-') ...[
            const Divider(height: 16),
            _buildEventItem("Primary expiry", primaryExpiry, width, scheme),
          ],
          if (secondaryExpiry != '-') ...[
            const Divider(height: 16),
            _buildEventItem("Secondary expiry", secondaryExpiry, width, scheme),
          ],
        ],
      ),
    );
  }

  Widget _buildEventItem(
    String title,
    String time,
    double width,
    ColorScheme scheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
            color: scheme.onSurface,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class DeleteVehicleBox extends StatefulWidget {
  final String vehicleId;
  const DeleteVehicleBox({super.key, required this.vehicleId});

  @override
  State<DeleteVehicleBox> createState() => _DeleteVehicleBoxState();
}

class _DeleteVehicleBoxState extends State<DeleteVehicleBox> {
  bool _submitting = false;
  CancelToken? _deleteToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void dispose() {
    _deleteToken?.cancel('DeleteVehicleBox disposed');
    super.dispose();
  }

  Future<void> _onDeletePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _deleteToken?.cancel('Previous delete request');
    final token = CancelToken();
    _deleteToken = token;

    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.deleteVehicle(
        widget.vehicleId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _submitting = false);
          Navigator.of(context).pop(true);
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _submitting = false);
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to delete vehicle.'
              : "Couldn't delete vehicle.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't delete vehicle.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width);
    final double fontSize = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: colorScheme.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danger Zone",
            style: GoogleFonts.roboto(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This action cannot be undone. It will permanently delete this vehicle and remove all associated data.",
                  style: GoogleFonts.roboto(
                    fontSize: fontSize - 2,
                    color: colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _submitting ? null : _onDeletePressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 1.8,
                    vertical: padding * 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: _submitting
                          ? const AppShimmer(width: 12, height: 12, radius: 6)
                          : const SizedBox.shrink(),
                    ),
                    if (_submitting) const SizedBox(width: 8),
                    Text(
                      "Delete Vehicle",
                      style: GoogleFonts.roboto(
                        fontSize: fontSize - 2,
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
