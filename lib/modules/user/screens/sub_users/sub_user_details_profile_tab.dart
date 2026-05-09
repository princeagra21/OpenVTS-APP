part of 'sub_user_details_screen.dart';

extension _SubUserDetailsProfileTab on _SubUserDetailsScreenState {
  Widget _buildProfileTab(BuildContext context) {
    if (_loading) {
      return const AppShimmer(width: double.infinity, height: 360, radius: 12);
    }

    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final scale = (screenWidth / 420).clamp(0.9, 1.0);
    final fs = 14 * scale;

    final details = _details ?? widget.initialSubUser;
    final limitedAccess = _isLimitedAccess(details);
    final displayName = _safe(details?.name);
    final username = _safe(details?.username);
    final email = _safe(details?.email);
    final phone = _formatPhone(
      _safe(details?.mobilePrefix),
      _safe(details?.mobileNumber),
    );
    final status = details?.isActive == true ? 'Active' : 'Disabled';
    final created = _formatDateTime(_safe(details?.createdAtLabel ?? ''));
    final updated = _formatDateTime(
      _safe(details?.raw['updatedAt']?.toString() ?? ''),
    );
    final vehiclesCount = _vehicles.length.toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (limitedAccess) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.error.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: cs.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Limited access\n\nYou can view this sub-user, but editing is restricted because it was created by admin.',
                      style: AppFonts.roboto(
                        fontSize: 12 * (fs / 14),
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: padding),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sub-user Overview',
                style: AppFonts.roboto(
                  fontSize: 18 * (fs / 14),
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              ElevatedButton.icon(
                onPressed: limitedAccess
                    ? null
                    : () async {
                        final result = await context.push(
                          AppRoutePaths.userSubUsersEdit(widget.userId),
                          extra: details,
                        );
                        if (result == true) {
                          _loadDetails();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16 * (fs / 14),
                  color: cs.onPrimary,
                ),
                label: Text(
                  'Edit Profile',
                  style: AppFonts.roboto(
                    fontSize: 13 * (fs / 14),
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccountCard(
            context,
            name: displayName,
            username: username,
            email: email,
            phone: phone,
            status: status,
            fs: fs,
            colorScheme: cs,
          ),
          SizedBox(height: padding),
          _buildMetaGrid(
            context,
            fs: fs,
            colorScheme: cs,
            vehiclesCount: vehiclesCount,
            status: status,
            created: created,
            updated: updated,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    required _DatePair created,
    required _DatePair updated,
  }) {
    final equalizedCreated = created.time.isEmpty
        ? _DatePair(created.date, ' ')
        : created;
    final equalizedUpdated = updated.time.isEmpty
        ? _DatePair(updated.date, ' ')
        : updated;
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
                title: 'Vehicles',
                pair: _DatePair(vehiclesCount, ' '),
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: 'Status',
                pair: _DatePair(status, ' '),
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: 'Updated',
                pair: equalizedUpdated,
                fs: fs,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: 'Created',
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
    IconData titleIcon(String t) {
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
