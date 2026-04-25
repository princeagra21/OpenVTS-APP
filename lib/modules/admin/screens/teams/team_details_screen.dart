import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_team_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_teams_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/screens/teams/edit_team_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String id;

  const TeamDetailsScreen({super.key, required this.id});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  static const List<String> _tabs = <String>['Profile'];

  String _selectedTab = 'Profile';

  AdminTeamListItem? _details;
  bool _loading = false;
  bool _errorShown = false;
  bool _statusSubmitting = false;
  bool? _activeOverride;
  CancelToken? _token;
  CancelToken? _statusToken;
  ApiClient? _apiClient;
  AdminTeamsRepository? _repo;

  AdminTeamsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminTeamsRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _token?.cancel('Team details disposed');
    _statusToken?.cancel('Team status disposed');
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  String _safe(String? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  _DatePair _formatDateTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return const _DatePair('—', '');
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return _DatePair(text, '');
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    final date = '${local.month}/${local.day}/${local.year}';
    final time = '$hour:$minute:$second $suffix';
    return _DatePair(date, time);
  }

  String _initials(String source) {
    final clean = source.trim();
    if (clean.isEmpty || clean == '—') return '--';
    final parts = clean
        .split(RegExp(r'\\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Future<void> _loadDetails() async {
    _token?.cancel('Reload team details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getTeamDetails(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (details) {
          setState(() {
            _details = details;
            _activeOverride = null;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          setState(() {
            _details = null;
            _loading = false;
          });
          if (_isCancelled(err)) return;
          if (_errorShown) return;
          _errorShown = true;
          final message =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load team details.'
                  : "Couldn't load team details.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = null;
        _loading = false;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load team details.")),
      );
    }
  }

  void _selectTab(String tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
  }

  Future<void> _toggleActive(bool current) async {
    if (_statusSubmitting) return;
    final teamId = widget.id.trim();
    if (teamId.isEmpty) return;

    setState(() => _statusSubmitting = true);
    _statusToken?.cancel('Team status update');
    final token = CancelToken();
    _statusToken = token;

    try {
      final res = await _repoOrCreate().updateTeamStatus(
        teamId,
        !current,
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (_) {
          setState(() {
            _statusSubmitting = false;
            _activeOverride = !current;
            if (_details != null) {
              final raw = Map<String, dynamic>.from(_details!.raw);
              raw['isActive'] = !current;
              _details = AdminTeamListItem.fromRaw(raw);
            }
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _statusSubmitting = false);
          final msg = err is ApiException
              ? (err.message.isNotEmpty
                  ? err.message
                  : "Couldn't update team status.")
              : "Couldn't update team status.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update team status.")),
      );
    }
  }

  Future<void> _openPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Password'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          final confirm = confirmController.text.trim();
                          if (password.isEmpty || confirm.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fill both password fields.'),
                              ),
                            );
                            return;
                          }
                          if (password != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match.'),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => submitting = true);
                          final res = await _repoOrCreate().updateTeamPassword(
                            widget.id,
                            password,
                          );
                          if (!mounted) return;
                          res.when(
                            success: (_) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password updated'),
                                ),
                              );
                            },
                            failure: (err) {
                              setDialogState(() => submitting = false);
                              final msg = err is ApiException &&
                                      err.message.trim().isNotEmpty
                                  ? err.message
                                  : "Couldn't update password.";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            },
                          );
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
  }

  Future<void> _openEditScreen() async {
    final details = _details;
    if (details == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTeamScreen(team: details),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      await _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final details = _details;
    final active = _activeOverride ?? details?.isActive ?? false;

    final name = _safe(
      details?.fullName,
      fallback: _safe(details?.username),
    );
    final username = _safe(details?.username);
    final email = _safe(details?.email);
    final phone = _safe(details?.fullPhone);
    final status = active ? 'Active' : 'Inactive';
    final updated = _formatDateTime(_safe(details?.updatedAt, fallback: ''));
    final created = _formatDateTime(_safe(details?.createdAt, fallback: ''));

    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;
    final uiScale = (screenWidth / 420).clamp(0.9, 1.0);
    final fs = 14 * uiScale;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigateBox(
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'Team mobile screens',
                  subtitle: 'Switch between the team screens below.',
                  onTabSelected: _selectTab,
                ),
                const SizedBox(height: 4),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: AppShimmer(
                      width: double.infinity,
                      height: 360,
                      radius: 16,
                    ),
                  )
                else
                _buildTabContent(
                  cs: cs,
                  active: active,
                  name: name,
                  username: username,
                  email: email,
                  phone: phone,
                  status: status,
                  updated: updated,
                  created: created,
                  fs: fs,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Team Details',
              leadingIcon: Symbols.groups,
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({
    required ColorScheme cs,
    required bool active,
    required String name,
    required String username,
    required String email,
    required String phone,
    required String status,
    required _DatePair updated,
    required _DatePair created,
    required double fs,
  }) {
    switch (_selectedTab) {
      case 'Profile':
      default:
        final scale = fs / 14;
        final sectionFs = 18 * scale;
        final cardPadding = AdaptiveUtils.getHorizontalPadding(
          MediaQuery.of(context).size.width,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Overview',
                    style: GoogleFonts.roboto(
                      fontSize: sectionFs,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
            _ActionRow(
              isActive: active,
              submitting: _statusSubmitting,
              onToggle: () => _toggleActive(active),
              onPassword: _openPasswordDialog,
              onEdit: _openEditScreen,
              scale: scale,
            ),
                  SizedBox(height: cardPadding),
                  _ProfileCard(
                    initials: _initials(name),
                    name: name,
                    username: username,
                    email: email,
                    phone: phone,
                    status: status,
                    colorScheme: cs,
                    scale: scale,
                  ),
                  SizedBox(height: cardPadding),
            _MetricsGrid(
              colorScheme: cs,
              fs: fs,
              updated: updated,
              created: created,
            ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _ActionRow extends StatelessWidget {
  final bool isActive;
  final bool submitting;
  final VoidCallback onToggle;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final double scale;

  const _ActionRow({
    required this.isActive,
    required this.submitting,
    required this.onToggle,
    required this.onPassword,
    required this.onEdit,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double titleFs = 13 * scale;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: submitting ? null : onToggle,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            icon: submitting
                ? SizedBox(
                    width: 14 * scale,
                    height: 14 * scale,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : Icon(
                    isActive ? Icons.toggle_on : Icons.toggle_off,
                    size: 18 * scale,
                    color: cs.primary,
                  ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isActive ? 'Set Inactive' : 'Set Active',
                style: GoogleFonts.roboto(
                  fontSize: titleFs,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPassword,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            icon: Icon(
              Icons.lock_outline,
              size: 18 * scale,
              color: cs.primary,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Password',
                style: GoogleFonts.roboto(
                  fontSize: titleFs,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            icon: Icon(
              Icons.edit_outlined,
              size: 18 * scale,
              color: cs.onPrimary,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Edit',
                style: GoogleFonts.roboto(
                  fontSize: titleFs,
                  height: 20 / 14,
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

class _ProfileCard extends StatelessWidget {
  final String initials;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String status;
  final ColorScheme colorScheme;
  final double scale;

  const _ProfileCard({
    required this.initials,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.status,
    required this.colorScheme,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final titleFs = 14 * scale;
    final subtitleFs = 12 * scale;
    final statusFs = 11 * scale;
    final avatarSize = 40 * scale;
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
              initials,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: titleFs,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: subtitleFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
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
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final ColorScheme colorScheme;
  final double fs;
  final _DatePair updated;
  final _DatePair created;

  const _MetricsGrid({
    required this.colorScheme,
    required this.fs,
    required this.updated,
    required this.created,
  });

  @override
  Widget build(BuildContext context) {
    final gap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cellWidth,
              child: _MetricCard(
                title: 'UPDATED',
                value: updated.date,
                subValue: updated.time,
                icon: Icons.update_outlined,
                colorScheme: colorScheme,
                fs: fs,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _MetricCard(
                title: 'CREATED',
                value: created.date,
                subValue: created.time,
                icon: Icons.event_outlined,
                colorScheme: colorScheme,
                fs: fs,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;
  final ColorScheme colorScheme;
  final double fs;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.colorScheme,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = fs / 14;
    final labelFs = 11 * scale;
    final valueFs = 14 * scale;
    final subValueFs = 12 * scale;
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
                icon,
                size: 14 * scale,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (subValue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
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
}

class _DatePair {
  final String date;
  final String time;

  const _DatePair(this.date, this.time);
}
