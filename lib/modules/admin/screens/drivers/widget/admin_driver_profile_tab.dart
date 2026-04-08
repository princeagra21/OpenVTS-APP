import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDriverProfileTab extends StatefulWidget {
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
  State<AdminDriverProfileTab> createState() => _AdminDriverProfileTabState();
}

class _AdminDriverProfileTabState extends State<AdminDriverProfileTab> {
  bool _statusSubmitting = false;
  bool _statusErrorShown = false;
  CancelToken? _statusToken;
  ApiClient? _api;
  AdminDriversRepository? _repo;

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

  AdminDriversRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminDriversRepository(api: _api!);
    return _repo!;
  }

  Future<void> _toggleActive(bool current) async {
    if (_statusSubmitting) return;
    final driverId = widget.driverId.trim();
    if (driverId.isEmpty) return;

    setState(() => _statusSubmitting = true);
    _statusToken?.cancel('Driver status update');
    final token = CancelToken();
    _statusToken = token;

    try {
      final res = await _repoOrCreate().updateDriverStatus(
        driverId,
        !current,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (_) {
          setState(() => _statusSubmitting = false);
          widget.onRefresh();
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _statusSubmitting = false);
          if (_statusErrorShown) return;
          _statusErrorShown = true;
          final msg = err is ApiException
              ? (err.message.isNotEmpty
                  ? err.message
                  : "Couldn't update driver status.")
              : "Couldn't update driver status.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusSubmitting = false);
      if (_statusErrorShown) return;
      _statusErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update driver status.")),
      );
    }
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
    final isActive = widget.details?.isActive ?? false;

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
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Driver Overview",
                style: GoogleFonts.roboto(
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
                onPressed: _statusSubmitting
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
                  style: GoogleFonts.roboto(
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
                  ? colorScheme.surfaceVariant
                  : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: GoogleFonts.roboto(
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
                        style: GoogleFonts.roboto(
                          fontSize: titleFs,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: GoogleFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: GoogleFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  ? colorScheme.surfaceVariant
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
                  style: GoogleFonts.roboto(
                    fontSize: labelFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  primaryUser,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
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
    IconData _titleIcon(String t) {
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
                style: GoogleFonts.roboto(
                  fontSize: labelFs,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Icon(
                _titleIcon(title),
                size: 14 * scale,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pair.date,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (pair.time.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pair.time,
              style: GoogleFonts.roboto(
                fontSize: subValueFs,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                style: GoogleFonts.roboto(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _keyValueRow(
            context,
            "Address ID",
            addressData.id,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "Line",
            addressData.line,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "City",
            addressData.city,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "State",
            addressData.state,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "Postal",
            addressData.postal,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "Country",
            addressData.country,
            labelFs,
            detailValueFs,
          ),
        ],
      ),
    );
  }

  Widget _keyValueRow(
    BuildContext context,
    String label,
    String value,
    double labelFs,
    double valueFs,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
    final raw = details.raw['address'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw.cast());
      return _AddressData(
        id: _safe(map['id']?.toString()),
        line: _safe(map['addressLine']?.toString()),
        city: _safe(map['cityId']?.toString()),
        state: _safe(map['stateCode']?.toString()),
        postal: _safe(map['pincode']?.toString()),
        country: _safe(map['countryCode']?.toString()),
      );
    }
    return const _AddressData(
      id: '—',
      line: '—',
      city: '—',
      state: '—',
      postal: '—',
      country: '—',
    );
  }

  String _addressLine(AdminDriverDetails? details) {
    if (details == null) return '—';
    final raw = details.raw['address'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw.cast());
      final full = _safe(map['fullAddress']?.toString());
      if (full != '—') return full;
      final line = _safe(map['addressLine']?.toString());
      final city = _safe(map['cityId']?.toString());
      final state = _safe(map['stateCode']?.toString());
      final country = _safe(map['countryCode']?.toString());
      final pin = _safe(map['pincode']?.toString());
      final parts = [line, city, state, country, pin]
          .where((e) => e.isNotEmpty && e != '—')
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return _safe(details.addressLocation);
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
