part of 'superadmin_settings_screen.dart';

class _ProfileOverviewHeader extends StatelessWidget {
  final String profileId;
  final String name;
  final String username;
  final bool verified;
  final String imageUrl;
  final bool loading;
  final bool emailOtpLoading;
  final bool whatsappOtpLoading;
  final VoidCallback onRequestEmailOtp;
  final VoidCallback onRequestWhatsappOtp;
  final String email;
  final String phone;
  final String whatsapp;
  final String companyName;
  final String companyWebsite;
  final String companyId;
  final String primaryColor;
  final String customDomain;
  final List<String> socialLabels;
  final Map<String, dynamic> socialLinks;
  final String address;
  final List<String> createdParts;
  final List<String> updatedParts;

  const _ProfileOverviewHeader({
    required this.profileId,
    required this.name,
    required this.username,
    required this.verified,
    required this.imageUrl,
    required this.loading,
    required this.emailOtpLoading,
    required this.whatsappOtpLoading,
    required this.onRequestEmailOtp,
    required this.onRequestWhatsappOtp,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.companyName,
    required this.companyWebsite,
    required this.companyId,
    required this.primaryColor,
    required this.customDomain,
    required this.socialLabels,
    required this.socialLinks,
    required this.address,
    required this.createdParts,
    required this.updatedParts,
  });

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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.1)),
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer(width: 90, height: 16, radius: 6),
                      const SizedBox(height: 6),
                      AppShimmer(width: 60, height: 12, radius: 6),
                    ],
                  ),
                ),
                AppShimmer(width: 72, height: 32, radius: 10),
                const SizedBox(width: 8),
                AppShimmer(width: 88, height: 32, radius: 10),
              ],
            ),
            const SizedBox(height: 16),
            const _ProfileOverviewSkeleton(),
          ],
        ),
      );
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
                  : cs.onSurface.withOpacity(0.12),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: AppUtils.headlineSmallBase.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profile',
                        style: AppUtils.bodySmallBase.copyWith(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  primary: true,
                  onTap: () {
                    if (profileId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditAdminProfileScreen(adminId: profileId),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                actionButton(
                  icon: Icons.lock_outline,
                  label: 'Password',
                  onTap: () {
                    if (profileId.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UpdatePasswordScreen(adminId: profileId),
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(height: 16),
          _ProfileAccountCard(
            name: name,
            username: username,
            verified: verified,
            imageUrl: imageUrl,
            loading: loading,
          ),
          const SizedBox(height: 12),
          _ProfileDatesGrid(
            loading: loading,
            createdDate: createdParts.isNotEmpty ? createdParts[0] : '—',
            createdTime: createdParts.length > 1 ? createdParts[1] : '—',
            updatedDate: updatedParts.isNotEmpty ? updatedParts[0] : '—',
            updatedTime: updatedParts.length > 1 ? updatedParts[1] : '—',
          ),
          const SizedBox(height: 12),
      _ProfileEmailCard(
        email: email,
        verified: verified,
        loading: loading,
        otpLoading: emailOtpLoading,
        onRequestOtp: onRequestEmailOtp,
      ),
      const SizedBox(height: 12),
      _ProfilePhoneCard(
        phone: phone,
        verified: verified,
        loading: loading,
        otpLoading: whatsappOtpLoading,
        onRequestOtp: onRequestWhatsappOtp,
      ),
      if (!loading &&
          whatsapp.trim().isNotEmpty &&
          whatsapp.trim() != '-' &&
          whatsapp.trim() != phone.trim()) ...[
        const SizedBox(height: 12),
        _ProfileWhatsappCard(
          phone: whatsapp,
          loading: loading,
        ),
      ],
      const SizedBox(height: 12),
      _ProfileCompanyCard(
        companyName: companyName,
        companyWebsite: companyWebsite,
        companyId: companyId,
        primaryColor: primaryColor,
        customDomain: customDomain,
        socialLabels: socialLabels,
        socialLinks: socialLinks,
        loading: loading,
      ),
      const SizedBox(height: 12),
      _ProfileAddressCard(
        address: address,
        loading: loading,
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
    final cs = Theme.of(context).colorScheme;
    Widget block({double height = 16, double width = double.infinity, double radius = 8}) {
      return AppShimmer(width: width, height: height, radius: radius);
    }

    Widget cardSkeleton() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withOpacity(0.12)),
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

class _ProfileAddressCard extends StatelessWidget {
  final String address;
  final bool loading;

  const _ProfileAddressCard({
    required this.address,
    required this.loading,
  });

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
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
              border: Border.all(
                color: cs.onSurface.withOpacity(0.12),
              ),
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
                    color: cs.onSurface.withOpacity(0.7),
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

class _ProfileDatesGrid extends StatelessWidget {
  final bool loading;
  final String createdDate;
  final String createdTime;
  final String updatedDate;
  final String updatedTime;

  const _ProfileDatesGrid({
    required this.loading,
    required this.createdDate,
    required this.createdTime,
    required this.updatedDate,
    required this.updatedTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = 13 * scale;
    final double timeSize = 12 * scale;

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
          border: Border.all(
            color: cs.onSurface.withOpacity(0.12),
          ),
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
                color: cs.onSurface.withOpacity(0.6),
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
                color: cs.onSurface.withOpacity(0.7),
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
  final String email;
  final bool verified;
  final bool loading;
  final bool otpLoading;
  final VoidCallback onRequestOtp;

  const _ProfileEmailCard({
    required this.email,
    required this.verified,
    required this.loading,
    required this.otpLoading,
    required this.onRequestOtp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
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
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : email,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
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
                const SizedBox(height: 8),
                InkWell(
                  onTap: otpLoading ? null : onRequestOtp,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 96),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: otpLoading
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
            ),
        ],
      ),
    );
  }
}

class _ProfilePhoneCard extends StatelessWidget {
  final String phone;
  final bool verified;
  final bool loading;
  final bool otpLoading;
  final VoidCallback onRequestOtp;

  const _ProfilePhoneCard({
    required this.phone,
    required this.verified,
    required this.loading,
    required this.otpLoading,
    required this.onRequestOtp,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
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
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
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
                const SizedBox(height: 8),
                InkWell(
                  onTap: otpLoading ? null : onRequestOtp,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 96),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: otpLoading
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
            ),
        ],
      ),
    );
  }
}

class _ProfileWhatsappCard extends StatelessWidget {
  final String phone;
  final bool loading;

  const _ProfileWhatsappCard({
    required this.phone,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
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
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.bodySmallBase.copyWith(
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
  final String companyName;
  final String companyWebsite;
  final String companyId;
  final String primaryColor;
  final String customDomain;
  final List<String> socialLabels;
  final Map<String, dynamic> socialLinks;
  final bool loading;
  final VoidCallback? onEditCompany;

  const _ProfileCompanyCard({
    required this.companyName,
    required this.companyWebsite,
    required this.companyId,
    required this.primaryColor,
    required this.customDomain,
    required this.socialLabels,
    required this.socialLinks,
    required this.loading,
    this.onEditCompany,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final double scale = fs / 14;
    final double labelSize = 11 * scale;
    final double titleSize = 14 * scale;
    final double iconBox = 40 * scale;
    final double iconSize = 18 * scale;

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
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
                    color: cs.onSurface.withOpacity(0.12),
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
                        fontSize: labelSize,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(
                            width: 180,
                            height: 18,
                            radius: 8,
                          )
                        : Text(
                            companyName,
                            style: AppFonts.roboto(
                              fontSize: titleSize,
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
                            fontSize: labelSize,
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
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primary.withOpacity(0.14),
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
                          color: cs.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppFonts.roboto(
                          fontSize: labelSize,
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

class _PushDiagnosticsCard extends StatelessWidget {
  final PushDeviceState? state;
  final bool loading;
  final VoidCallback onConfirmAction;
  final VoidCallback onSendTest;

  const _PushDiagnosticsCard({
    required this.state,
    required this.loading,
    required this.onConfirmAction,
    required this.onSendTest,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double headingFs = 18 * scale;
    final double subtitleFs = 12 * scale;
    final double alertFs = 12 * scale;

    if (loading || state == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer(width: 132, height: 18, radius: 6),
            const SizedBox(height: 4),
            AppShimmer(width: 176, height: 12, radius: 6),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final double gap = 10;
                final double cellWidth = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: cellWidth,
                      child: AppShimmer(
                        width: double.infinity,
                        height: 64,
                        radius: 12,
                      ),
                    ),
                    SizedBox(
                      width: cellWidth,
                      child: AppShimmer(
                        width: double.infinity,
                        height: 64,
                        radius: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            AppShimmer(width: double.infinity, height: 48, radius: 12),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: AppShimmer(width: double.infinity, height: 44, radius: 12)),
                const SizedBox(width: 10),
                Expanded(child: AppShimmer(width: double.infinity, height: 44, radius: 12)),
              ],
            ),
          ],
        ),
      );
    }

    final permissionLabel = state == null
        ? 'Checking...'
        : (!state!.supported
            ? 'Unsupported'
            : (state!.registered
                ? 'Allowed'
                : (state!.askedOnce ? 'Blocked' : 'Not requested')));
    final tokenLabel = state == null
        ? '—'
        : (state!.token?.isNotEmpty == true ? 'Registered' : 'None');
    final showPermissionWarning =
        state != null && state!.supported && !state!.enabledByUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Push Diagnostics",
            style: AppFonts.roboto(
              fontSize: headingFs,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Notification permission and push state",
            style: AppFonts.roboto(
              fontSize: subtitleFs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double gap = 10;
              final double cellWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Permission",
                      value: permissionLabel,
                      scale: scale,
                      width: width,
                      colorScheme: cs,
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Server Tokens",
                      value: tokenLabel,
                      scale: scale,
                      width: width,
                      colorScheme: cs,
                    ),
                  ),
                ],
              );
            },
          ),
          if (showPermissionWarning) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16 * scale,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Notifications are blocked. Open your device settings and allow notifications, then click 'Re-register push'.",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.roboto(
                        fontSize: alertFs,
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onConfirmAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    (state?.registered ?? false)
                        ? Icons.notifications_off
                        : Icons.refresh,
                    size: 16 * scale,
                    color: cs.onPrimary,
                  ),
                  label: Text(
                    (state?.registered ?? false)
                        ? "Unregister"
                        : "Re-register",
                    style: AppFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onSendTest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: cs.onSurface.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.send,
                    size: 16 * scale,
                    color: cs.onSurface,
                  ),
                  label: Text(
                    "Send push test",
                    style: AppFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pushInfoBox({
    required String title,
    required String value,
    required double scale,
    required double width,
    required ColorScheme colorScheme,
  }) {
    final double labelFs = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueFs = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PushSettingsDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _PushSettingsDialog({
    this.title = 'Enable push notifications?',
    this.message =
        'Enable push notifications to get important updates and alerts on this device.',
    this.confirmLabel = 'Enable',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: AppFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        message,
        style: AppFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: AppFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PushRegisterDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _PushRegisterDialog({
    this.title = 'Enable push notifications?',
    this.message =
        'Enable push notifications to get important updates and alerts on this device.',
    this.confirmLabel = 'Enable',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: AppFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        message,
        style: AppFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: AppFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PushUnregisterDialog extends StatelessWidget {
  const _PushUnregisterDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Unregister push?',
        style: AppFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        'This device will stop receiving push notifications.',
        style: AppFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Unregister',
            style: AppFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PushTestDialog extends StatelessWidget {
  const _PushTestDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Send test push?',
        style: AppFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        'We will send a test notification to this device.',
        style: AppFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Send',
            style: AppFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _ProfileAccountCard extends StatelessWidget {
  final String name;
  final String username;
  final bool verified;
  final String imageUrl;
  final bool loading;

  const _ProfileAccountCard({
    required this.name,
    required this.username,
    required this.verified,
    required this.imageUrl,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double avatarSize = 44 * scale;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width) + 1;
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_outline,
                        size: 22 * scale,
                        color: cs.onSurface,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      size: 22 * scale,
                      color: cs.onSurface,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loading ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.headlineSmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
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
