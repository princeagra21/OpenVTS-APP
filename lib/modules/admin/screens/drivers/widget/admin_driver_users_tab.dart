import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_drivers_repository.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDriverUsersTab extends StatefulWidget {
  final List<AdminUserListItem> items;
  final bool loading;
  final double bodyFontSize;
  final double smallFontSize;
  final String driverId;
  final AdminDriversRepository repository;
  final Future<void> Function() onRefreshLinkedUsers;

  const AdminDriverUsersTab({
    super.key,
    required this.items,
    required this.loading,
    required this.bodyFontSize,
    required this.smallFontSize,
    required this.driverId,
    required this.repository,
    required this.onRefreshLinkedUsers,
  });

  @override
  State<AdminDriverUsersTab> createState() => _AdminDriverUsersTabState();
}

class _AdminDriverUsersTabState extends State<AdminDriverUsersTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _unassigning = false;
  String _unassigningUserId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final titleFs = 14 * scale;
    final subtitleFs = 12 * scale;
    final statusFs = 11 * scale;
    final iconSize = subtitleFs + 2;
    final cardPadding = hp + 4;

    if (widget.loading) {
      return listShimmer(context, count: 3, height: 108);
    }

    final query = _searchController.text.trim().toLowerCase();
    final filteredUsers = widget.items.where((user) {
      final username = user.username.toLowerCase();
      return query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.fullPhone.toLowerCase().contains(query) ||
          username.contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.surfaceVariant),
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
                    child: Text(
                      'Browse Users',
                      style: GoogleFonts.roboto(
                        fontSize: 18 * scale,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _unassigning ? null : _openAssignUserSheet,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      disabledBackgroundColor: cs.onSurface.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      'Assign User',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Container(
                height: hp * 3.5,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.roboto(
                    fontSize: widget.bodyFontSize,
                    height: 20 / 14,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    hintStyle: GoogleFonts.roboto(
                      color: cs.onSurface.withOpacity(0.5),
                      fontSize: widget.smallFontSize,
                      height: 16 / 12,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      size: iconSize,
                      color: cs.onSurface,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: hp,
                      vertical: hp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              if (filteredUsers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      widget.items.isEmpty
                          ? 'No users linked to this driver'
                          : 'No users found',
                      style: GoogleFonts.roboto(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              else
                ...filteredUsers.map((user) {
                  final name = safeText(user.fullName);
                  final email = safeText(user.email);
                  final phone = safeText(user.fullPhone);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: detailsCard(
                      context,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.surface,
                            radius: AdaptiveUtils.getAvatarSize(width) / 2,
                            foregroundColor: cs.onSurface,
                            child: Container(
                              width: AdaptiveUtils.getAvatarSize(width),
                              height: AdaptiveUtils.getAvatarSize(width),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.12),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                user.initials,
                                style: GoogleFonts.roboto(
                                  color: cs.onSurface,
                                  fontSize: AdaptiveUtils.getFsAvatarFontSize(
                                    width,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spacing * 2),
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
                                          color: cs.onSurface,
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
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? cs.surfaceVariant
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        safeText(user.statusLabel),
                                        style: GoogleFonts.roboto(
                                          fontSize: statusFs,
                                          height: 14 / 11,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing / 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _infoRow(
                                            Icons.mail_outline,
                                            email.isEmpty ? 'No email' : email,
                                            iconSize,
                                            subtitleFs,
                                            cs,
                                            email.isEmpty,
                                          ),
                                          SizedBox(height: spacing / 2),
                                          _infoRow(
                                            Icons.phone_outlined,
                                            phone.isEmpty ? 'No phone' : phone,
                                            iconSize,
                                            subtitleFs,
                                            cs,
                                            phone.isEmpty,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed:
                                          (_unassigning &&
                                                  _unassigningUserId == user.id)
                                              ? null
                                              : () => _onUnassignUser(user),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 24),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: const VisualDensity(
                                          horizontal: -4,
                                          vertical: -4,
                                        ),
                                      ),
                                      child:
                                          (_unassigning &&
                                                  _unassigningUserId == user.id)
                                              ? SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: cs.error,
                                                  ),
                                                )
                                              : Text(
                                                  'Unassign',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: subtitleFs - 1,
                                                    fontWeight: FontWeight.w700,
                                                    color: cs.error,
                                                  ),
                                                ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAssignUserSheet() async {
    final cs = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    final users = <AdminUserListItem>[];
    var loading = true;
    var submittingUserId = '';
    var query = '';
    var initialized = false;
    late void Function(VoidCallback fn) setSheetState;

    Future<void> loadAvailableUsers() async {
      setSheetState(() => loading = true);
      final result = await widget.repository.getUnlinkedUsers(widget.driverId);
      if (!mounted) return;
      result.when(
        success: (items) {
          setSheetState(() {
            users
              ..clear()
              ..addAll(items);
            loading = false;
          });
        },
        failure: (_) {
          setSheetState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load available users.")),
          );
        },
      );
    }

    Future<void> assign(AdminUserListItem user) async {
      final userId = int.tryParse(user.id.trim());
      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid user id.')));
        return;
      }
      setSheetState(() => submittingUserId = user.id);
      final result = await widget.repository.assignUserToDriver(
        widget.driverId,
        userId: userId,
      );
      if (!mounted) return;
      result.when(
        success: (_) async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User assigned successfully.')),
          );
          Navigator.of(context).pop();
          await widget.onRefreshLinkedUsers();
        },
        failure: (err) {
          setSheetState(() => submittingUserId = '');
          final message = err is ApiException && err.message.trim().isNotEmpty
              ? err.message
              : "Couldn't assign user.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, localSetState) {
            setSheetState = localSetState;
            if (!initialized) {
              initialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) loadAvailableUsers();
              });
            }
            final filtered = users.where((user) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return user.fullName.toLowerCase().contains(q) ||
                  user.email.toLowerCase().contains(q) ||
                  user.fullPhone.toLowerCase().contains(q) ||
                  user.username.toLowerCase().contains(q);
            }).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Assign User',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select an available user to link to this driver.',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: (v) => localSetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No available users found',
                                style: GoogleFonts.roboto(
                                  color: cs.onSurface.withOpacity(0.65),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemBuilder: (_, index) {
                                final user = filtered[index];
                                final phone = user.fullPhone.trim();
                                final email = user.email.trim();
                                final subtitle = email.isNotEmpty
                                    ? email
                                    : (user.username.trim().isNotEmpty
                                          ? user.username.trim()
                                          : 'No email');
                                final trailingBusy = submittingUserId == user.id;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    user.fullName.trim().isEmpty
                                        ? 'Unknown user'
                                        : user.fullName.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '$subtitle${phone.isNotEmpty ? ' • $phone' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: trailingBusy
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : null,
                                  onTap: submittingUserId.isEmpty
                                      ? () => assign(user)
                                      : null,
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemCount: filtered.length,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  Future<void> _onUnassignUser(AdminUserListItem user) async {
    if (_unassigning) return;
    final userId = int.tryParse(user.id.trim());
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid user id.')));
      return;
    }
    setState(() {
      _unassigning = true;
      _unassigningUserId = user.id;
    });
    final result = await widget.repository.unassignUserFromDriver(
      widget.driverId,
      userId: userId,
    );
    if (!mounted) return;
    result.when(
      success: (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unassigned successfully.')),
        );
        await widget.onRefreshLinkedUsers();
      },
      failure: (err) {
        final message = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : "Couldn't unassign user.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
    if (!mounted) return;
    setState(() {
      _unassigning = false;
      _unassigningUserId = '';
    });
  }

  Widget _infoRow(
    IconData icon,
    String text,
    double iconSize,
    double fs,
    ColorScheme cs,
    bool isEmpty,
  ) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: cs.onSurface.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: fs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: isEmpty
                  ? cs.onSurface.withOpacity(0.4)
                  : cs.onSurface.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
