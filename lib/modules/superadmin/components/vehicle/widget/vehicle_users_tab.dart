import 'package:fleet_stack/core/models/vehicle_user_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleUsersTab extends StatelessWidget {
  final List<VehicleUserItem>? users;

  const VehicleUsersTab({super.key, this.users});

  String _safe(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    return trimmed;
  }

  String _displayRole(VehicleUserItem user) {
    final role = _safe(user.role);
    if (role.isEmpty) return 'User';
    return role.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUsers = users ?? const <VehicleUserItem>[];
    final cs = Theme.of(context).colorScheme;

    if (resolvedUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No linked users',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This vehicle has no linked primary user, creator, or driver in the current API response.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: resolvedUsers
          .map((user) => _buildUserCard(context, user, cs))
          .toList(),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    VehicleUserItem user,
    ColorScheme cs,
  ) {
    final String displayName = _safe(user.name).isNotEmpty
        ? user.name
        : 'Unknown';
    final String displayUsername = _safe(user.username);
    final String displayEmail = _safe(user.email);
    final String displayPhone = _safe(user.phone);
    final String displayLastSeen = _safe(user.lastSeen);
    final String initials = _getInitials(displayName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _displayRole(user),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (displayUsername.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$displayUsername',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                if (displayEmail.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    displayEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                if (displayPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displayPhone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                if (displayLastSeen.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last seen: $displayLastSeen',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
