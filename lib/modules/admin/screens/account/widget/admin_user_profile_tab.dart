import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserProfileTab extends StatelessWidget {
  final AdminUserDetails? details;
  final bool loading;
  final double bodyFontSize;

  const AdminUserProfileTab({
    super.key,
    required this.details,
    required this.loading,
    required this.bodyFontSize,
  });

  String _initials(String source) {
    final clean = source.trim();
    if (clean.isEmpty || clean == '—') return '--';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 120,
                  radius: 25,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 120,
                  radius: 25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 120,
                  radius: 25,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 120,
                  radius: 25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          detailsCard(
            context,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 80, height: 16, radius: 8),
                SizedBox(height: 12),
                Row(
                  children: [
                    AppShimmer(width: 40, height: 40, radius: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppShimmer(
                            width: double.infinity,
                            height: 18,
                            radius: 8,
                          ),
                          SizedBox(height: 6),
                          AppShimmer(width: 150, height: 14, radius: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                AppShimmer(width: 70, height: 16, radius: 8),
                SizedBox(height: 12),
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: 220, height: 16, radius: 8),
                SizedBox(height: 24),
                AppShimmer(width: 80, height: 16, radius: 8),
                SizedBox(height: 12),
                AppShimmer(width: double.infinity, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: 180, height: 16, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: 210, height: 16, radius: 8),
              ],
            ),
          ),
        ],
      );
    }

    final displayName = safeText(
      details?.companyName,
      fallback: safeText(details?.fullName),
    );
    final username = safeText(details?.username);
    final websiteOrLocation = safeText(
      details?.location,
      fallback: safeText(details?.country),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoBox(
                context,
                title: 'Vehicles',
                content: '${details?.vehiclesCount ?? 0}',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _infoBox(
                context,
                title: 'Status',
                content: safeText(details?.statusLabel),
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _infoBox(
                context,
                title: 'Last Login',
                content: formatDateLabel(details?.lastLoginAt ?? ''),
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _infoBox(
                context,
                title: 'Created',
                content: formatDateLabel(details?.joinedAt ?? ''),
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        detailsCard(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: bodyFontSize + 3,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          username.startsWith('@') ? username : '@$username',
                          style: GoogleFonts.inter(
                            fontSize: bodyFontSize,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    radius: 20,
                    child: Text(_initials(displayName)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                websiteOrLocation,
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize - 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Address',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              infoRow(
                context,
                'Line',
                safeText(details?.address),
                bodyFontSize,
              ),
              const SizedBox(height: 8),
              infoRow(context, 'City', safeText(details?.city), bodyFontSize),
              const SizedBox(height: 8),
              infoRow(context, 'State', safeText(details?.state), bodyFontSize),
              const SizedBox(height: 8),
              infoRow(
                context,
                'Postal',
                safeText(details?.pincode),
                bodyFontSize,
              ),
              const SizedBox(height: 8),
              infoRow(
                context,
                'Country',
                safeText(details?.country),
                bodyFontSize,
              ),
              const SizedBox(height: 24),
              Text(
                'Contacts',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                safeText(details?.email),
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                safeText(details?.fullPhone),
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                websiteOrLocation,
                style: GoogleFonts.inter(
                  fontSize: bodyFontSize,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBox(
    BuildContext context, {
    required String title,
    required String content,
    required ColorScheme colorScheme,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            style: GoogleFonts.inter(
              fontSize: bodyFontSize - 1,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: bodyFontSize + 2,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
