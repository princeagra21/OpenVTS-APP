import 'package:dio/dio.dart';
import 'package:country_picker/country_picker.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/admin/update_user_password_screen.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/edit_company_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminUserProfileTab extends StatefulWidget {
  final AdminUserDetails? details;
  final bool loading;
  final double bodyFontSize;
  final String userId;
  final void Function({bool silent}) onRefresh;

  const AdminUserProfileTab({
    super.key,
    required this.details,
    required this.loading,
    required this.bodyFontSize,
    required this.userId,
    required this.onRefresh,
  });

  @override
  State<AdminUserProfileTab> createState() => _AdminUserProfileTabState();
}

class _AdminUserProfileTabState extends State<AdminUserProfileTab> {
  bool _statusSubmitting = false;
  bool _statusErrorShown = false;
  CancelToken? _statusToken;
  ApiClient? _api;
  AdminUsersRepository? _repo;

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

  Future<void> _openExternalLink(String rawUrl) async {
    final text = rawUrl.trim();
    if (text.isEmpty || text == '—') return;
    final normalized =
        text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openCompanyEdit() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditCompanyScreen(
          profile: AdminProfile(widget.details?.raw ?? const <String, dynamic>{}),
        ),
      ),
    );
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
    final vehicles = (widget.details?.vehiclesCount ?? 0).toString();
    final lastLogin =
        _formatDateTime(_safe(widget.details?.lastLoginAt, fallback: ''));
    final created =
        _formatDateTime(_safe(widget.details?.joinedAt, fallback: ''));

    final address = _addressLine(widget.details);
    final company = _companyData(widget.details);
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
          vehicles: vehicles,
          lastLogin: lastLogin,
          created: created,
          address: address,
          company: company,
          details: widget.details,
          isActive: isActive,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _statusToken?.cancel('User profile tab disposed');
    super.dispose();
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
    required String vehicles,
    required _DatePair lastLogin,
    required _DatePair created,
    required String address,
    required _CompanyData company,
    required AdminUserDetails? details,
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
                "User Overview",
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
                icon: _statusSubmitting
                    ? SizedBox(
                        width: 14 * scale,
                        height: 14 * scale,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UpdateUserPasswordScreen(userId: widget.userId),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.lock_outline,
                  size: 18 * scale,
                  color: colorScheme.primary,
                ),
                label: Text(
                  "Password",
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
            vehiclesCount: vehicles,
            status: status,
            lastLogin: lastLogin,
            created: created,
          ),
          SizedBox(height: padding),
          _buildCompanyCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            company: company,
          ),
          SizedBox(height: padding),
          _buildAddressCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            address: address,
            details: details,
          ),
          // Contacts grid removed (email/phone already shown above).
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
    required String vehiclesCount,
    required String status,
    required _DatePair lastLogin,
    required _DatePair created,
  }) {
    final equalizedLogin = lastLogin.time.isEmpty
        ? _DatePair(lastLogin.date, ' ')
        : lastLogin;
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
                title: "Vehicles",
                pair: _DatePair(vehiclesCount, ' '),
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
                title: "Last Login",
                pair: equalizedLogin,
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
      if (l.contains('vehicle')) return Icons.directions_car_outlined;
      if (l.contains('status')) return Icons.verified_user_outlined;
      if (l.contains('login')) return Icons.schedule;
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
    required AdminUserDetails? details,
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

  Widget _buildContactsGrid(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String email,
    required String phone,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 12 * scale;
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 14 * scale,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Email",
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
                      email,
                      style: GoogleFonts.roboto(
                        fontSize: valueFs,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14 * scale,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Phone",
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
                      phone,
                      style: GoogleFonts.roboto(
                        fontSize: valueFs,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompanyCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required _CompanyData company,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.apartment,
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
                      "Company",
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: titleFs,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (company.websiteUrl != '—') ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openExternalLink(company.websiteUrl),
                        child: Text(
                          company.websiteUrl,
                          style: GoogleFonts.roboto(
                            fontSize: labelFs,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openCompanyEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.14),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (company.socialLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: company.socialLinks
                    .map(
                      (link) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openExternalLink(link.url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.surfaceVariant
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Text(
                            link.label,
                            style: GoogleFonts.roboto(
                              fontSize: labelFs,
                              height: 14 / 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
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
          style: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
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

  _CompanyData _companyData(AdminUserDetails? details) {
    if (details == null) {
      return const _CompanyData('—', '—', <_CompanyLink>[]);
    }
    Map<String, dynamic>? company;
    final companies = details.raw['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      company = Map<String, dynamic>.from(companies.first as Map);
    }
    company ??= details.raw['company'] is Map
        ? Map<String, dynamic>.from(details.raw['company'] as Map)
        : null;
    final name = _safe(company?['name']?.toString());
    final websiteUrlRaw = (company?['websiteUrl'] ?? '').toString().trim();
    final websiteFallback = (company?['website'] ?? '').toString().trim();
    final customDomain = (company?['customDomain'] ?? '').toString().trim();
    final rootWebsiteUrl = (details.raw['websiteUrl'] ?? '').toString().trim();
    final rootWebsite = (details.raw['website'] ?? '').toString().trim();
    final socialWebsite = company?['socialLinks'] is Map
        ? ((company?['socialLinks'] as Map)['website'] ?? '').toString().trim()
        : '';
    final websiteUrl = _safe(
      websiteUrlRaw.isNotEmpty
          ? websiteUrlRaw
          : websiteFallback.isNotEmpty
          ? websiteFallback
          : rootWebsiteUrl.isNotEmpty
          ? rootWebsiteUrl
          : rootWebsite.isNotEmpty
          ? rootWebsite
          : customDomain.isNotEmpty
          ? customDomain
          : socialWebsite,
    );
    final social = company?['socialLinks'];
    final links = <_CompanyLink>[];
    if (social is Map) {
      social.forEach((key, value) {
        final v = (value?.toString() ?? '').trim();
        if (v.isEmpty) return;
        links.add(_CompanyLink(label: _titleCaseKey(key.toString()), url: v));
      });
    }
    return _CompanyData(name, websiteUrl, links);
  }

  _AddressData _addressData(AdminUserDetails? details) {
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
      final parsed = _parseStateCountryFromAddress(
        _safe(map['fullAddress']?.toString(), fallback: '').isNotEmpty
            ? _safe(map['fullAddress']?.toString(), fallback: '')
            : _safe(details.location, fallback: ''),
      );
      final countryName = _safe(
        map['countryName']?.toString().isNotEmpty == true
            ? map['countryName']?.toString()
            : details.country,
      );
      final stateName = _safe(
        map['stateName']?.toString().isNotEmpty == true
            ? map['stateName']?.toString()
            : details.state,
      );
      return _AddressData(
        id: _safe(map['id']?.toString()),
        line: _safe(map['addressLine']?.toString()),
        city: _safe(
          map['cityName']?.toString().isNotEmpty == true
              ? map['cityName']?.toString()
              : (map['city']?.toString().isNotEmpty == true
                  ? map['city']?.toString()
                  : map['cityId']?.toString()),
        ),
        state: stateName != '—'
            ? stateName
            : (parsed.$1.isNotEmpty
                ? parsed.$1
                : _safe(map['stateCode']?.toString())),
        postal: _safe(map['pincode']?.toString()),
        country: countryName != '—'
            ? countryName
            : (parsed.$2.isNotEmpty
                ? parsed.$2
                : _countryNameFromCode(_safe(map['countryCode']?.toString()))),
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

  String _titleCaseKey(String key) {
    final cleaned = key.replaceAll(RegExp(r'[_\\-]+'), ' ').trim();
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
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
    final last = filtered.isNotEmpty ? filtered.last : '';
    final numericOnly = RegExp(r'^[0-9\- ]+$');
    if (numericOnly.hasMatch(last)) {
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
    if (parsed == null) return normalized;
    return parsed.name;
  }

  String _addressLine(AdminUserDetails? details) {
    if (details == null) return '—';
    final raw = details.raw['address'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw.cast());
      final full = _safe(map['fullAddress']?.toString());
      if (full != '—') return full;
      final line = _safe(map['addressLine']?.toString());
      final city = _safe(
        map['cityName']?.toString().isNotEmpty == true
            ? map['cityName']?.toString()
            : (map['city']?.toString().isNotEmpty == true
                ? map['city']?.toString()
                : map['cityId']?.toString()),
      );
      final state = _safe(
        map['stateName']?.toString().isNotEmpty == true
            ? map['stateName']?.toString()
            : details.state,
      );
      final country = _safe(
        map['countryName']?.toString().isNotEmpty == true
            ? map['countryName']?.toString()
            : details.country,
      );
      final pin = _safe(map['pincode']?.toString());
      final stateCode = _safe(map['stateCode']?.toString());
      final countryCode = _safe(map['countryCode']?.toString());
      final parts = [
        line,
        city,
        state != '—' ? state : stateCode,
        country != '—' ? country : countryCode,
        pin,
      ]
          .where((e) => e.isNotEmpty && e != '—')
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return _safe(details.location);
  }

  AdminUsersRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminUsersRepository(api: _api!);
    return _repo!;
  }

  Future<void> _toggleActive(bool current) async {
    if (_statusSubmitting) return;
    final userId = widget.userId.trim();
    if (userId.isEmpty) return;

    setState(() => _statusSubmitting = true);
    _statusToken?.cancel('User status update');
    final token = CancelToken();
    _statusToken = token;

    try {
      final res = await _repoOrCreate().updateUserStatus(
        userId,
        !current,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (_) {
          setState(() => _statusSubmitting = false);
          widget.onRefresh(silent: true);
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _statusSubmitting = false);
          if (_statusErrorShown) return;
          _statusErrorShown = true;
          final msg = err is ApiException
              ? (err.message.isNotEmpty
                  ? err.message
                  : "Couldn't update user status.")
              : "Couldn't update user status.";
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
        const SnackBar(content: Text("Couldn't update user status.")),
      );
    }
  }
}

class _CompanyData {
  final String name;
  final String websiteUrl;
  final List<_CompanyLink> socialLinks;

  const _CompanyData(this.name, this.websiteUrl, this.socialLinks);
}

class _CompanyLink {
  final String label;
  final String url;

  const _CompanyLink({required this.label, required this.url});
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
