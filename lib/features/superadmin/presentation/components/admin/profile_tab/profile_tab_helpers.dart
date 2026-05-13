part of 'profile_tab.dart';

extension _ProfileTabHelpers on _ProfileTabState {
  List<_CompanyLink> _companySocialLinks(AdminProfile? profile) {
    final data = profile?.data;
    if (data == null) return const [];
    Map<String, dynamic>? company;
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      company = Map<String, dynamic>.from(companies.first as Map);
    }
    company ??= data['company'] is Map
        ? Map<String, dynamic>.from(data['company'] as Map)
        : null;
    final links = <_CompanyLink>[];

    void addLink(String label, Object? value) {
      final v = (value?.toString() ?? '').trim();
      if (v.isEmpty || v == '-') return;
      if (links.any((e) => e.url == v)) return;
      links.add(_CompanyLink(label: label, url: v));
    }

    final social = company?['socialLinks'] ?? _deepFindKey(data, 'socialLinks');
    if (social is Map) {
      social.forEach((key, value) {
        addLink(_titleCaseKey(key.toString()), value);
      });
    }

    // Fallbacks when API returns social links outside company.socialLinks.
    addLink(
      'Custom Domain',
      _deepFindAnyKey(data, const ['customDomain', 'domain', 'custom_domain']),
    );
    addLink('Facebook', _deepFindAnyKey(data, const ['facebook']));
    addLink('Instagram', _deepFindAnyKey(data, const ['instagram']));
    addLink('Linkedin', _deepFindAnyKey(data, const ['linkedin']));
    addLink('Twitter', _deepFindAnyKey(data, const ['twitter', 'x']));

    return links;
  }

  String _titleCaseKey(String key) {
    final cleaned = key.replaceAll(RegExp(r'[_\\-]+'), ' ').trim();
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              part.substring(0, 1).toUpperCase() +
              part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Widget _buildPushDiagnosticsCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double headingFs = 18 * scale;
    final double subtitleFs = 12 * scale;
    final double alertFs = 12 * scale;
    final state = _pushState;
    final permissionLabel = state == null
        ? 'Checking...'
        : (!state.supported
              ? 'Unsupported'
              : (state.registered
                    ? 'Allowed'
                    : (state.askedOnce ? 'Blocked' : 'Not requested')));
    final tokenLabel = state == null
        ? '—'
        : (state.token?.isNotEmpty == true ? 'Registered' : 'None');
    final showPermissionWarning =
        state != null && state.supported && !state.enabledByUser;

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
            "Push Diagnostics",
            style: AppFonts.roboto(
              fontSize: headingFs,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Notification permission and push state",
            style: AppFonts.roboto(
              fontSize: subtitleFs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
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
                      fs: fs,
                      colorScheme: colorScheme,
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Server Tokens",
                      value: tokenLabel,
                      fs: fs,
                      colorScheme: colorScheme,
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
                      style: AppFonts.roboto(
                        fontSize: alertFs,
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
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
                  onPressed: _pushActionLoading ? null : _confirmPushAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    (_pushState?.registered ?? false)
                        ? Icons.notifications_off
                        : Icons.refresh,
                    size: 16 * scale,
                    color: colorScheme.onPrimary,
                  ),
                  label: Text(
                    (_pushState?.registered ?? false)
                        ? "Unregister push"
                        : "Re-register push",
                    style: AppFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pushActionLoading ? null : _handlePushTest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.send,
                    size: 16 * scale,
                    color: colorScheme.onSurface,
                  ),
                  label: Text(
                    "Send push test",
                    style: AppFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
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
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
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

  Widget _keyValueRow(
    String label,
    String value,
    double fs,
    ColorScheme colorScheme,
    bool loading,
  ) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 12 * scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
            fontSize: labelFs,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Flexible(
          child: loading
              ? const Align(
                  alignment: Alignment.centerRight,
                  child: AppShimmer(width: 120, height: 14, radius: 8),
                )
              : Text(
                  value,
                  style: AppFonts.roboto(
                    fontSize: valueFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
        ),
      ],
    );
  }

  String _buildAddress(AdminProfile? p) {
    if (p == null) return '-';
    final fullAddress = _valueFromKeys(p, const [
      'fulladdress',
      'fullAddress',
      'addressFull',
      'address_full',
    ]);
    if (fullAddress != '-') return fullAddress;
    final addressMap = p.data['address'];
    if (addressMap is Map) {
      final nested =
          addressMap['fullAddress'] ??
          addressMap['fulladdress'] ??
          addressMap['addressFull'] ??
          addressMap['address_full'];
      if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString().trim();
      }
    }
    final parts = <String>[
      _display(p.addressLine),
      _display(p.city),
      _display(p.state),
      _display(p.pincode),
      _display(p.country),
    ].where((e) => e != '-').toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v == null) continue;
      final t = v.trim();
      if (t.isNotEmpty) return t;
    }
    return '-';
  }

  String _valueFromKeys(AdminProfile? p, List<String> keys) {
    if (p == null) return '-';
    for (final key in keys) {
      final v = p.data[key];
      if (v == null) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty) return t;
    }
    final company = p.data['company'];
    if (company is Map) {
      final map = Map<String, dynamic>.from(company.cast());
      for (final key in keys) {
        final v = map[key];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
    }
    final deep = _deepFindAnyKey(p.data, keys);
    if (deep != null) {
      final t = deep.toString().trim();
      if (t.isNotEmpty) return t;
    }
    return '-';
  }

  Object? _deepFindAnyKey(Map<String, dynamic> root, List<String> keys) {
    for (final key in keys) {
      final found = _deepFindKey(root, key);
      if (found != null && found.toString().trim().isNotEmpty) return found;
    }
    return null;
  }

  Object? _deepFindKey(Map<String, dynamic> root, String key) {
    if (root.containsKey(key)) return root[key];
    for (final value in root.values) {
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value.cast());
        final found = _deepFindKey(nested, key);
        if (found != null) return found;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final nested = Map<String, dynamic>.from(item.cast());
            final found = _deepFindKey(nested, key);
            if (found != null) return found;
          }
        }
      }
    }
    return null;
  }

  String _addressValue(AdminProfile? p, List<String> keys) {
    if (p == null) return '-';
    final addressMap = p.data['address'];
    if (addressMap is Map) {
      for (final key in keys) {
        final v = addressMap[key];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
    }
    return _valueFromKeys(p, keys);
  }

  _DatePair _formatDateTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '-') {
      return const _DatePair('-', '-');
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return _DatePair(text, '-');
    }
    final local = parsed.toLocal();
    final date = '${local.month}/${local.day}/${local.year}';
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String minute = local.minute.toString().padLeft(2, '0');
    final String ampm = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour12:$minute $ampm';
    return _DatePair(date, time);
  }

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _usernameLabel(String username) {
    if (username == '-') return '-';
    return username.startsWith('@') ? username : '@$username';
  }

  String _initials(String name, String username) {
    final source = name == '-' ? username : name;
    if (source == '-') return '--';
    final clean = source.replaceAll('@', ' ').trim();
    final parts = clean
        .split(RegExp(r'\\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    final out = parts.take(2).map((e) => e[0]).join();
    return out.toUpperCase();
  }
}

class _DatePair {
  final String date;
  final String time;

  const _DatePair(this.date, this.time);
}

class _CompanyLink {
  final String label;
  final String url;

  const _CompanyLink({required this.label, required this.url});
}
