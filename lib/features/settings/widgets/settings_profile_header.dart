import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/features/settings/settings_controller.dart';
import 'package:open_vts/features/settings/widgets/settings_account_section.dart';
import 'package:open_vts/features/settings/widgets/settings_security_section.dart';
import 'package:open_vts/features/settings/widgets/settings_section_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    super.key,
    required this.profile,
    required this.loading,
    required this.onEdit,
    required this.onPassword,
    this.onEmailVerify,
    this.onPhoneVerify,
    this.emailActionVisibleWhenVerified = false,
    this.phoneActionVisibleWhenVerified = false,
    this.emailActionLoading = false,
    this.phoneActionLoading = false,
  });

  final SettingsProfileData profile;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final Future<void> Function()? onEmailVerify;
  final Future<void> Function()? onPhoneVerify;
  final bool emailActionVisibleWhenVerified;
  final bool phoneActionVisibleWhenVerified;
  final bool emailActionLoading;
  final bool phoneActionLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width) + 2;
    final double subtitleSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double buttonFont = 12 * scale;
    final double iconSize = subtitleSize + 6;

    if (loading) {
      return const SettingsSectionCard(child: _ProfileOverviewSkeleton());
    }

    Widget actionButton({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool primary = false,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primary ? cs.primary : Colors.transparent,
            border: Border.all(
              color: primary
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: iconSize,
                color: primary ? cs.onPrimary : cs.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.roboto(
                  fontSize: buttonFont,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: primary ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SettingsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: AppFonts.roboto(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profile',
                      style: AppFonts.roboto(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              actionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                primary: true,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              actionButton(
                icon: Icons.lock_outline,
                label: 'Password',
                onTap: onPassword,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsAccountSection(
            child: _ProfileAccountCard(
              name: profile.name,
              username: profile.username,
              verified: profile.verified,
              imageUrl: profile.imageUrl,
              loading: loading,
            ),
          ),
          const SizedBox(height: 12),
          SettingsAccountSection(
            child: _ProfileDatesGrid(
              loading: loading,
              createdDate: profile.createdParts.isNotEmpty
                  ? profile.createdParts[0]
                  : '—',
              createdTime: profile.createdParts.length > 1
                  ? profile.createdParts[1]
                  : '—',
              updatedDate: profile.updatedParts.isNotEmpty
                  ? profile.updatedParts[0]
                  : '—',
              updatedTime: profile.updatedParts.length > 1
                  ? profile.updatedParts[1]
                  : '—',
            ),
          ),
          const SizedBox(height: 12),
          SettingsSecuritySection(
            child: _ProfileEmailCard(
              email: profile.email,
              verified: profile.emailVerified,
              loading: loading,
              onVerify: onEmailVerify,
              showActionWhenVerified: emailActionVisibleWhenVerified,
              actionLoading: emailActionLoading,
            ),
          ),
          const SizedBox(height: 12),
          SettingsSecuritySection(
            child: _ProfilePhoneCard(
              phone: profile.phone,
              verified: profile.phoneVerified,
              loading: loading,
              onVerify: onPhoneVerify,
              showActionWhenVerified: phoneActionVisibleWhenVerified,
              actionLoading: phoneActionLoading,
            ),
          ),
          if (!loading &&
              profile.whatsapp.trim().isNotEmpty &&
              profile.whatsapp.trim() != '-' &&
              profile.whatsapp.trim() != profile.phone.trim()) ...[
            const SizedBox(height: 12),
            SettingsAccountSection(
              child: _ProfileWhatsappCard(
                phone: profile.whatsapp,
                loading: loading,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SettingsAccountSection(
            child: _ProfileCompanyCard(
              companyName: profile.companyName,
              companyWebsite: profile.companyWebsite,
              companyId: profile.companyId,
              primaryColor: profile.primaryColor,
              customDomain: profile.customDomain,
              socialLabels: profile.socialLabels,
              socialLinks: profile.socialLinks,
              loading: loading,
              onEditCompany: onEdit,
            ),
          ),
          const SizedBox(height: 12),
          SettingsAccountSection(
            child: _ProfileAddressCard(
              address: profile.address,
              loading: loading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOverviewSkeleton extends StatelessWidget {
  const _ProfileOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block({
      double height = 16,
      double width = double.infinity,
      double radius = 8,
    }) {
      return AppShimmer(width: width, height: height, radius: radius);
    }

    Widget cardSkeleton() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            const AppShimmer(width: 36, height: 36, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(width: 96, height: 14),
                  const SizedBox(height: 6),
                  block(width: 140, height: 12),
                ],
              ),
            ),
            block(width: 72, height: 28, radius: 10),
          ],
        ),
      );
    }

    return Column(
      children: [
        cardSkeleton(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: cardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        cardSkeleton(),
        const SizedBox(height: 12),
        cardSkeleton(),
        const SizedBox(height: 12),
        cardSkeleton(),
      ],
    );
  }
}

class _ProfileDatesGrid extends StatelessWidget {
  const _ProfileDatesGrid({
    required this.loading,
    required this.createdDate,
    required this.createdTime,
    required this.updatedDate,
    required this.updatedTime,
  });

  final bool loading;
  final String createdDate;
  final String createdTime;
  final String updatedDate;
  final String updatedTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 4;
    final double timeSize = AdaptiveUtils.getSubtitleFontSize(width) - 3;

    Widget cell({
      required String label,
      required String date,
      required String time,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: labelSize,
                height: 14 / 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loading ? '—' : date,
              style: AppFonts.roboto(
                fontSize: valueSize,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loading ? '—' : time,
              style: AppFonts.roboto(
                fontSize: timeSize,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AdaptiveUtils.getLeftSectionSpacing(width) + 6;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: cell(
                label: 'Updated',
                date: updatedDate,
                time: updatedTime,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: cell(
                label: 'Created',
                date: createdDate,
                time: createdTime,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileEmailCard extends StatelessWidget {
  const _ProfileEmailCard({
    required this.email,
    required this.verified,
    required this.loading,
    required this.onVerify,
    required this.showActionWhenVerified,
    required this.actionLoading,
  });

  final String email;
  final bool verified;
  final bool loading;
  final Future<void> Function()? onVerify;
  final bool showActionWhenVerified;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.mail_outline,
              size: 18 * scale,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: AppFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : email,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: AppFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading)
            _VerifyPillWithAction(
              verified: verified,
              label: verified ? 'Verified' : 'Unverified',
              onSendOtp: (!verified && email.trim().isNotEmpty && email != '-')
                  ? onVerify
                  : (showActionWhenVerified ? onVerify : null),
              showActionWhenVerified: showActionWhenVerified,
              loading: actionLoading,
            ),
        ],
      ),
    );
  }
}

class _ProfilePhoneCard extends StatelessWidget {
  const _ProfilePhoneCard({
    required this.phone,
    required this.verified,
    required this.loading,
    required this.onVerify,
    required this.showActionWhenVerified,
    required this.actionLoading,
  });

  final String phone;
  final bool verified;
  final bool loading;
  final Future<void> Function()? onVerify;
  final bool showActionWhenVerified;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.phone_outlined,
              size: 18 * scale,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone',
                  style: AppFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : phone,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: AppFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading)
            _VerifyPillWithAction(
              verified: verified,
              label: verified ? 'Verified' : 'Unverified',
              onSendOtp: (!verified && phone.trim().isNotEmpty && phone != '-')
                  ? onVerify
                  : (showActionWhenVerified ? onVerify : null),
              showActionWhenVerified: showActionWhenVerified,
              loading: actionLoading,
            ),
        ],
      ),
    );
  }
}

class _VerifyPillWithAction extends StatefulWidget {
  const _VerifyPillWithAction({
    required this.verified,
    required this.label,
    required this.onSendOtp,
    required this.showActionWhenVerified,
    required this.loading,
  });

  final bool verified;
  final String label;
  final Future<void> Function()? onSendOtp;
  final bool showActionWhenVerified;
  final bool loading;

  @override
  State<_VerifyPillWithAction> createState() => _VerifyPillWithActionState();
}

class _VerifyPillWithActionState extends State<_VerifyPillWithAction> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerHighest
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.verified ? Icons.verified : Icons.error_outline,
            size: 14 * scale,
            color: widget.verified ? cs.primary : cs.error,
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: AppFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: widget.verified ? cs.primary : cs.error,
            ),
          ),
        ],
      ),
    );

    final shouldShowAction = widget.showActionWhenVerified || !widget.verified;
    if (!shouldShowAction || widget.onSendOtp == null) return pill;

    final isBusy = _sending || widget.loading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        pill,
        const SizedBox(height: 6),
        GestureDetector(
          onTap: isBusy
              ? null
              : () async {
                  setState(() => _sending = true);
                  try {
                    await widget.onSendOtp?.call();
                  } finally {
                    if (mounted) setState(() => _sending = false);
                  }
                },
          child: Container(
            constraints: const BoxConstraints(minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isBusy
                  ? const AppShimmer(width: 52, height: 12, radius: 6)
                  : Text(
                      'Verify',
                      style: AppFonts.roboto(
                        fontSize: 12 * scale,
                        height: 16 / 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileWhatsappCard extends StatelessWidget {
  const _ProfileWhatsappCard({required this.phone, required this.loading});

  final String phone;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.chat_bubble_outline,
              size: 18 * scale,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp',
                  style: AppFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : phone,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: AppFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompanyCard extends StatelessWidget {
  const _ProfileCompanyCard({
    required this.companyName,
    required this.companyWebsite,
    required this.companyId,
    required this.primaryColor,
    required this.customDomain,
    required this.socialLabels,
    required this.socialLinks,
    required this.loading,
    required this.onEditCompany,
  });

  final String companyName;
  final String companyWebsite;
  final String companyId;
  final String primaryColor;
  final String customDomain;
  final List<String> socialLabels;
  final Map<String, dynamic> socialLinks;
  final bool loading;
  final VoidCallback onEditCompany;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final double scale2 = fs / 14;
    final double labelFs = 11 * scale2;
    final double titleFs = 14 * scale2;
    final double iconBox = 40 * scale2;
    final double iconSize = 18 * scale2;

    String? socialUrl(String label) {
      final key = label.toLowerCase().replaceAll(' ', '');
      final byKey = socialLinks[key]?.toString();
      if (byKey != null && byKey.trim().isNotEmpty) return byKey;
      for (final entry in socialLinks.entries) {
        if (entry.key.toString().toLowerCase() == key) {
          final v = entry.value?.toString() ?? '';
          if (v.trim().isNotEmpty) return v;
        }
      }
      return null;
    }

    Future<void> openUrl(String url) async {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? cs.surfaceContainerHighest
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.apartment,
                  size: iconSize,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: AppFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(width: 180, height: 18, radius: 8)
                        : Text(
                            companyName,
                            style: AppFonts.roboto(
                              fontSize: titleFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                    if (!loading && companyWebsite != '-') ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => openUrl(companyWebsite),
                        child: Text(
                          companyWebsite,
                          style: AppFonts.roboto(
                            fontSize: labelFs,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            color: cs.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!loading) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onEditCompany,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!loading && socialLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socialLabels.map((label) {
                  final url = socialUrl(label);
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: url == null ? null : () => openUrl(url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surfaceContainerHighest
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppFonts.roboto(
                          fontSize: labelFs,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAccountCard extends StatelessWidget {
  const _ProfileAccountCard({
    required this.name,
    required this.username,
    required this.verified,
    required this.imageUrl,
    required this.loading,
  });

  final String name;
  final String username;
  final bool verified;
  final String imageUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double nameSize = AdaptiveUtils.getSubtitleFontSize(width) + 2;
    final double handleSize = AdaptiveUtils.getTitleFontSize(width) - 1;

    Widget initialsAvatar(String text) {
      final initials = text.trim().isEmpty || text.trim() == '-'
          ? '—'
          : text
                .split(RegExp(r'\s+'))
                .where((e) => e.isNotEmpty)
                .take(2)
                .map((e) => e[0])
                .join()
                .toUpperCase();
      return CircleAvatar(
        radius: 28 * scale,
        backgroundColor: cs.primary,
        child: Text(
          initials,
          style: AppFonts.roboto(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
            color: cs.onPrimary,
          ),
        ),
      );
    }

    Widget imageAvatar(String url) {
      return CircleAvatar(
        radius: 28 * scale,
        backgroundColor: cs.surfaceContainerHighest,
        backgroundImage: NetworkImage(url),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          if (loading)
            const AppShimmer(width: 56, height: 56, radius: 28)
          else if (imageUrl.trim().isNotEmpty)
            imageAvatar(imageUrl)
          else
            initialsAvatar(name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.roboto(
                    fontSize: nameSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.roboto(
                    fontSize: handleSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceContainerHighest
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    verified ? Icons.verified : Icons.error_outline,
                    size: 14 * scale,
                    color: verified ? cs.primary : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verified ? 'Verified' : 'Unverified',
                    style: AppFonts.roboto(
                      fontSize: 12 * scale,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: verified ? cs.primary : cs.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileAddressCard extends StatelessWidget {
  const _ProfileAddressCard({required this.address, required this.loading});

  final String address;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double iconBox = 40 * scale;
    final double iconSize = 18 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.location_on_outlined,
              size: iconSize,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address',
                  style: AppFonts.roboto(
                    fontSize: labelFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                loading
                    ? const AppShimmer(
                        width: double.infinity,
                        height: 16,
                        radius: 8,
                      )
                    : Text(
                        address,
                        style: AppFonts.roboto(
                          fontSize: titleFs,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
