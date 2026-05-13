import 'package:open_vts/features/admin/presentation/controllers/admin_driver_detail_controller.dart';
import 'package:country_picker/country_picker.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_driver_providers.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AdminDriverProfileTab extends ConsumerStatefulWidget {
  final AdminDriverDetails? details;
  final bool loading;
  final double bodyFontSize;
  final String driverId;
  final VoidCallback onRefresh;

  const AdminDriverProfileTab({
    super.key,
    required this.details,
    required this.loading,
    required this.bodyFontSize,
    required this.driverId,
    required this.onRefresh,
  });

  @override
  ConsumerState<AdminDriverProfileTab> createState() => _AdminDriverProfileTabState();
}

class _AdminDriverProfileTabState extends ConsumerState<AdminDriverProfileTab> {
  bool? _activeOverride;

  String _safe(String? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _initials(String source) {
    final clean = source.trim();
    if (clean.isEmpty || clean == '—') return '--';
    final parts = clean
        .split(RegExp(r'\\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  _DatePair _formatDateTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return const _DatePair('—', '');
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return _DatePair(text, '');
    final local = parsed.toLocal();
    final date = '${local.day}/${local.month}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return _DatePair(date, time);
  }


  Future<void> _toggleActive(bool current) async {
    final driverId = widget.driverId.trim();
    if (driverId.isEmpty) return;
    final updated = await ref
        .read(adminDriverDetailControllerProvider(driverId).notifier)
        .updateStatus(!current);
    if (!mounted) return;
    if (updated) {
      updateLocalUiState(this, () => _activeOverride = !current);
      widget.onRefresh();
      return;
    }
    final message = ref.read(adminDriverDetailControllerProvider(driverId)).errorMessage ??
        "Couldn't update driver status.";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const AppShimmer(
        width: double.infinity,
        height: 360,
        radius: 12,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fs = 14 * scale;

    final displayName = _safe(
      widget.details?.fullName,
      fallback: _safe(widget.details?.username),
    );
    final username = _safe(widget.details?.username);
    final email = _safe(widget.details?.email);
    final phone = _safe(widget.details?.fullPhone);
    final status = _safe(widget.details?.statusLabel);
    final primaryUser = _safe(widget.details?.primaryUserName);
    final verification = _safe(widget.details?.verifiedLabel);
    final created =
        _formatDateTime(_safe(widget.details?.createdAt, fallback: ''));

    final address = _addressLine(widget.details);
    final isActive = _activeOverride ?? widget.details?.isActive ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildOverviewCard(
          context,
          padding: padding,
          fs: fs,
          colorScheme: colorScheme,
          displayName: displayName,
          username: username,
          email: email,
          phone: phone,
          status: status,
          primaryUser: primaryUser,
          verification: verification,
          created: created,
          address: address,
          details: widget.details,
          isActive: isActive,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required double padding,
    required double fs,
    required ColorScheme colorScheme,
    required String displayName,
    required String username,
    required String email,
    required String phone,
    required String status,
    required String primaryUser,
    required String verification,
    required _DatePair created,
    required String address,
    required AdminDriverDetails? details,
    required bool isActive,
  }) {
    final double scale = fs / 14;
    final double fsSection = 18 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Driver Overview",
                style: AppFonts.roboto(
                  fontSize: fsSection,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: ref.watch(adminDriverDetailControllerProvider(widget.driverId)).isSaving
                    ? null
                    : () => _toggleActive(isActive),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isActive ? Icons.toggle_on : Icons.toggle_off,
                  size: 18 * scale,
                  color: colorScheme.primary,
                ),
                label: Text(
                  isActive ? "Set Inactive" : "Set Active",
                  style: AppFonts.roboto(
                    fontSize: 13 * scale,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: padding),
          _buildAccountCard(
            context,
            name: displayName,
            username: username,
            email: email,
            phone: phone,
            status: status,
            fs: fs,
            colorScheme: colorScheme,
          ),
          SizedBox(height: padding),
          _buildMetaGrid(
            context,
            fs: fs,
            colorScheme: colorScheme,
            primaryUser: primaryUser,
            status: status,
            verification: verification,
            created: created,
          ),
          SizedBox(height: padding),
          _buildPrimaryUserCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            primaryUser: primaryUser,
          ),
          SizedBox(height: padding),
          _buildAddressCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            address: address,
            details: details,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String name,
    required String username,
    required String email,
    required String phone,
    required String status,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double avatarSize = 40 * scale;
    final double titleFs = 14 * scale;
    final double subtitleFs = 12 * scale;
    final double statusFs = 11 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHighest
                  : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: AppFonts.roboto(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppFonts.roboto(
                          fontSize: titleFs,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: AppFonts.roboto(
                          fontSize: statusFs,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: AppFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: AppFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: AppFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaGrid(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String primaryUser,
    required String status,
    required String verification,
    required _DatePair created,
  }) {
    final equalizedCreated =
        created.time.isEmpty ? _DatePair(created.date, ' ') : created;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gap = 10;
        final double cellWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Primary User",
                pair: _DatePair(primaryUser, ' '),
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Status",
                pair: _DatePair(status, ' '),
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Verification",
                pair: _DatePair(verification, ' '),
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Created",
                pair: equalizedCreated,
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryUserCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String primaryUser,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double iconBox = 40 * scale;
    final double iconSize = 18 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified_user_outlined,
              size: iconSize,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Primary User",
                  style: AppFonts.roboto(
                    fontSize: labelFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  primaryUser,
                  softWrap: true,
                  style: AppFonts.roboto(
                    fontSize: titleFs,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required _DatePair pair,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
    final double subValueFs = 12 * scale;
    IconData titleIcon(String t) {
      final l = t.toLowerCase();
      if (l.contains('primary')) return Icons.verified_user_outlined;
      if (l.contains('status')) return Icons.verified_user_outlined;
      if (l.contains('verification')) return Icons.verified_outlined;
      if (l.contains('created')) return Icons.event;
      return Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: labelFs,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Icon(
                titleIcon(title),
                size: 14 * scale,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pair.date,
            style: AppFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            softWrap: true,
          ),
          if (pair.time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pair.time,
              style: AppFonts.roboto(
                fontSize: subValueFs,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String address,
    required AdminDriverDetails? details,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
    final double detailValueFs = 12 * scale;
    final addressData = _addressData(details);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14 * scale,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                "Address",
                style: AppFonts.roboto(
                  fontSize: labelFs,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            address,
            softWrap: true,
            style: AppFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _keyValueColumn(
                  "City",
                  addressData.city,
                  labelFs,
                  detailValueFs,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _keyValueColumn(
                  "State",
                  addressData.state,
                  labelFs,
                  detailValueFs,
                  colorScheme,
                  align: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _keyValueColumn(
                  "Country",
                  addressData.country,
                  labelFs,
                  detailValueFs,
                  colorScheme,
                  align: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyValueColumn(
    String label,
    String value,
    double labelFs,
    double valueFs,
    ColorScheme colorScheme, {
    TextAlign align = TextAlign.left,
  }) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: align,
          style: AppFonts.roboto(
            fontSize: labelFs,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: align,
          style: AppFonts.roboto(
            fontSize: valueFs,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  _AddressData _addressData(AdminDriverDetails? details) {
    if (details == null) {
      return const _AddressData(
        id: '—',
        line: '—',
        city: '—',
        state: '—',
        postal: '—',
        country: '—',
      );
    }
    final parsed = _parseStateCountryFromAddress(
      details.fullAddress.trim().isNotEmpty
          ? details.fullAddress
          : _safe(details.addressLocation, fallback: ''),
    );
    return _AddressData(
      id: '—',
      line: _safe(details.addressLine),
      city: _safe(details.city),
      state: parsed.$1.isNotEmpty ? parsed.$1 : _safe(details.stateCode),
      postal: _safe(details.pincode),
      country: parsed.$2.isNotEmpty
          ? parsed.$2
          : _countryNameFromCode(_safe(details.countryCode)),
    );
  }

  String _addressLine(AdminDriverDetails? details) {
    if (details == null) return '—';
    final full = _safe(details.fullAddress);
    if (full != '—') return full;
    final parsed = _parseStateCountryFromAddress(
      _safe(details.addressLocation, fallback: ''),
    );
    final parts = [
      _safe(details.addressLine),
      _safe(details.city),
      parsed.$1.isNotEmpty ? parsed.$1 : _safe(details.stateCode),
      parsed.$2.isNotEmpty ? parsed.$2 : _countryNameFromCode(_safe(details.countryCode)),
      _safe(details.pincode),
    ].where((e) => e.isNotEmpty && e != '—').toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return _safe(details.addressLocation);
  }


  (String, String) _parseStateCountryFromAddress(String fullAddress) {
    final raw = fullAddress.trim();
    if (raw.isEmpty || raw == '—') return ('', '');
    final parts = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length < 2) return ('', '');

    final filtered = List<String>.from(parts);
    final numericOnly = RegExp(r'^[0-9 -]+$');
    if (filtered.isNotEmpty && numericOnly.hasMatch(filtered.last)) {
      filtered.removeLast();
    }
    if (filtered.length < 2) return ('', '');
    final country = filtered.last;
    final state = filtered.length >= 3 ? filtered[filtered.length - 2] : '';
    return (state, country);
  }

  String _countryNameFromCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || normalized == '—') return '—';
    final parsed = Country.tryParse(normalized);
    return parsed?.name ?? normalized;
  }
}

class _AddressData {
  final String id;
  final String line;
  final String city;
  final String state;
  final String postal;
  final String country;

  const _AddressData({
    required this.id,
    required this.line,
    required this.city,
    required this.state,
    required this.postal,
    required this.country,
  });
}

class _DatePair {
  final String date;
  final String time;

  const _DatePair(this.date, this.time);
}

