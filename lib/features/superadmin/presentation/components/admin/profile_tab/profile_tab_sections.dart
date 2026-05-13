part of 'profile_tab.dart';

extension _ProfileTabSections on _ProfileTabState {
  Widget _buildOverviewCard(
    BuildContext context, {
    required double padding,
    required double fs,
    required ColorScheme colorScheme,
    required bool loading,
  }) {
    final double scale = fs / 14;
    final double fsSection = 18 * scale;
    final double fsAction = 14 * scale;
    final double fsActionIcon = 16 * scale;
    final p = _profile;
    final displayName = _display(p?.fullName, fallback: _display(p?.username));
    final username = _usernameLabel(_display(p?.username));
    final email = _display(p?.email);
    final phone = _display(p?.phone);
    final isVerified = p?.isVerified == true;
    final companyName = _display(p?.companyName);
    final socialLinks = _companySocialLinks(p);
    final websiteUrl = _valueFromKeys(p, const [
      'websiteUrl',
      'website',
      'siteUrl',
    ]);
    final customDomain = _valueFromKeys(p, const [
      'customDomain',
      'custom_domain',
      'domain',
      'website',
      'websiteUrl',
    ]);
    final primaryColor = _valueFromKeys(p, const [
      'primaryColor',
      'primary_color',
      'brandColor',
      'brand_color',
    ]);
    final favicon = _valueFromKeys(p, const [
      'favicon',
      'faviconUrl',
      'favicon_url',
    ]);
    final logoLight = _valueFromKeys(p, const [
      'logoLight',
      'logo_light',
      'logoLightUrl',
      'logo_light_url',
    ]);
    final logoDark = _valueFromKeys(p, const [
      'logoDark',
      'logo_dark',
      'logoDarkUrl',
      'logo_dark_url',
    ]);
    final company = _display(p?.companyName);
    final address = _buildAddress(p);
    final updatedRaw = _firstNonEmpty([
      p?.data['updatedAt']?.toString(),
      p?.data['updated_at']?.toString(),
    ]);
    final createdRaw = _firstNonEmpty([
      p?.createdAt,
      p?.data['createdAt']?.toString(),
      p?.data['created_at']?.toString(),
    ]);
    final updated = _formatDateTime(updatedRaw);
    final created = _formatDateTime(createdRaw);
    final vehiclesCount = p?.vehiclesCount ?? 0;
    final credits = p?.credits ?? 0;
    final lastLogin = _formatDateTime(p?.lastLogin ?? '');

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Admin Overview",
                    style: AppFonts.roboto(
                      fontSize: fsSection,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditAdminProfileScreen(adminId: widget.adminId),
                        ),
                      ).then((updated) {
                        if (updated == true) {
                          _loadProfile();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.edit,
                      size: fsActionIcon,
                      color: colorScheme.onPrimary,
                    ),
                    label: Text(
                      "Edit",
                      style: AppFonts.roboto(
                        fontSize: fsAction,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _statusSubmitting ? null : _toggleActive,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _isActive ? Icons.toggle_on : Icons.toggle_off,
                      size: fsActionIcon,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      _isActive ? "Set Inactive" : "Set Active",
                      style: AppFonts.roboto(
                        fontSize: fsAction,
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
                              UpdatePasswordScreen(adminId: widget.adminId),
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
                      size: fsActionIcon,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      "Password",
                      style: AppFonts.roboto(
                        fontSize: fsAction,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
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
            isVerified: isVerified,
            loading: loading,
            fs: fs,
            colorScheme: colorScheme,
          ),
          SizedBox(height: padding),
          _buildAdminMetaGrid(
            context,
            fs: fs,
            colorScheme: colorScheme,
            loading: loading,
            vehiclesCount: vehiclesCount.toString(),
            credits: credits.toString(),
            lastLogin: lastLogin,
            created: created,
          ),
          SizedBox(height: padding),
          _buildCompanyCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            companyName: companyName,
            websiteUrl: websiteUrl,
            customDomain: customDomain,
            primaryColor: primaryColor,
            favicon: favicon,
            logoLight: logoLight,
            logoDark: logoDark,
            socialLinks: socialLinks,
            loading: loading,
          ),
          SizedBox(height: padding),
          _buildAddressCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            address: address,
            city: _resolvedAddressPart(
              primary: _addressValue(p, const ['cityId', 'city', 'cityName']),
              fullAddress: address,
              fallbackIndexFromEnd: 4,
            ),
            state: _resolvedAddressPart(
              primary: _addressValue(p, const [
                'state',
                'stateName',
                'stateCode',
              ]),
              fullAddress: address,
              fallbackIndexFromEnd: 3,
            ),
            country: _resolvedAddressPart(
              primary: _addressValue(p, const [
                'country',
                'countryName',
                'countryCode',
              ]),
              fullAddress: address,
              fallbackIndexFromEnd: 2,
            ),
            loading: loading,
          ),
        ],
      ),
    );
  }

  String _resolvedAddressPart({
    required String primary,
    required String fullAddress,
    required int fallbackIndexFromEnd,
  }) {
    final value = primary.trim();
    final looksLikeCode = RegExp(r'^[A-Z]{2,3}$').hasMatch(value);
    if (value.isNotEmpty && value != '-' && !looksLikeCode) return value;

    final parts = fullAddress
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final idx = parts.length - fallbackIndexFromEnd;
    if (idx >= 0 && idx < parts.length) return parts[idx];
    return value.isEmpty ? '-' : value;
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String name,
    required String username,
    required String email,
    required String phone,
    required bool isVerified,
    required bool loading,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double avatarSize = 40 * scale;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double subtitleFs = 12 * scale;
    final double statusFs = 11 * scale;
    final double statusIcon = 12 * scale;
    final double rowIcon = 14 * scale;
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
                child: loading
                    ? const AppShimmer(width: 24, height: 24, radius: 12)
                    : Text(
                        name.isNotEmpty ? name.trim()[0].toUpperCase() : 'A',
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
                          child: loading
                              ? const AppShimmer(
                                  width: 120,
                                  height: 18,
                                  radius: 8,
                                )
                              : Text(
                                  name,
                                  style: AppFonts.roboto(
                                    fontSize: titleFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        loading
                            ? const AppShimmer(
                                width: 90,
                                height: 18,
                                radius: 999,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? colorScheme.surfaceContainerHighest
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _isActive ? "Active" : "Inactive",
                                  style: AppFonts.roboto(
                                    fontSize: statusFs,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(width: 120, height: 14, radius: 8)
                        : Text(
                            username,
                            style: AppFonts.roboto(
                              fontSize: subtitleFs,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                    const SizedBox(height: 6),
                    loading
                        ? const AppShimmer(width: 140, height: 14, radius: 8)
                        : Text(
                            phone,
                            style: AppFonts.roboto(
                              fontSize: subtitleFs,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                    const SizedBox(height: 6),
                    loading
                        ? const AppShimmer(width: 160, height: 14, radius: 8)
                        : Text(
                            email,
                            style: AppFonts.roboto(
                              fontSize: subtitleFs,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildAdminMetaGrid(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required bool loading,
    required String vehiclesCount,
    required String credits,
    required _DatePair lastLogin,
    required _DatePair created,
  }) {
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
                pair: _DatePair(vehiclesCount, ''),
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Credits",
                pair: _DatePair(credits, ''),
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Last Login",
                pair: lastLogin,
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Created",
                pair: created,
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
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
    required bool loading,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
    final double subValueFs = 12 * scale;
    IconData titleIcon(String t) {
      final l = t.toLowerCase();
      if (l.contains('vehicle')) return Icons.directions_car_outlined;
      if (l.contains('credit')) return Icons.account_balance_wallet_outlined;
      if (l.contains('login')) return Icons.schedule;
      if (l.contains('created')) return Icons.event;
      return Icons.info_outline;
    }

    final hasSub = pair.time.trim().isNotEmpty;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: labelFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              Icon(
                titleIcon(title),
                size: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          loading
              ? const AppShimmer(width: 120, height: 18, radius: 8)
              : Text(
                  pair.date,
                  style: AppFonts.roboto(
                    fontSize: valueFs + 2,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
          if (hasSub) ...[
            const SizedBox(height: 6),
            loading
                ? const AppShimmer(width: 90, height: 14, radius: 8)
                : Text(
                    pair.time,
                    style: AppFonts.roboto(
                      fontSize: subValueFs,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
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

  Widget _buildCompanyCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String companyName,
    required String websiteUrl,
    required String customDomain,
    required String primaryColor,
    required String favicon,
    required String logoLight,
    required String logoDark,
    required List<_CompanyLink> socialLinks,
    required bool loading,
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
                      ? colorScheme.surfaceContainerHighest
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
                      style: AppFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.roboto(
                        fontSize: titleFs,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (websiteUrl != '-') ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openExternalLink(websiteUrl),
                        child: Text(
                          websiteUrl,
                          style: AppFonts.roboto(
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
          if (socialLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: socialLinks
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.surfaceContainerHighest
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Text(
                            link.label,
                            style: AppFonts.roboto(
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

  Widget _buildAddressCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String address,
    required String city,
    required String state,
    required String country,
    required bool loading,
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
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_outlined,
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
                      "Address",
                      style: AppFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
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
                              color: colorScheme.onSurface,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _keyValueColumn("City", city, fs, colorScheme, loading),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _keyValueColumn(
                  "State",
                  state,
                  fs,
                  colorScheme,
                  loading,
                  align: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _keyValueColumn(
                  "Country",
                  country,
                  fs,
                  colorScheme,
                  loading,
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
    String title,
    String value,
    double fs,
    ColorScheme colorScheme,
    bool loading, {
    TextAlign align = TextAlign.left,
  }) {
    final labelFs = fs * (12 / 14);
    final valueFs = fs * (13 / 14);
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: align,
          style: AppFonts.roboto(
            fontSize: labelFs,
            height: 16 / 12,
            color: colorScheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        if (loading)
          const AppShimmer(width: 56, height: 14, radius: 7)
        else
          Text(
            value.isEmpty ? '-' : value,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.roboto(
              fontSize: valueFs,
              height: 18 / 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}
