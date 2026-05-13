import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_profile.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_user.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_vehicle.dart';
import 'package:open_vts/core/error/legacy_error_presenter.dart';
import 'package:open_vts/features/superadmin/presentation/components/profile/widget/profile_company_box.dart';
import 'package:open_vts/features/superadmin/presentation/components/profile/widget/profile_delete_box.dart';
import 'package:open_vts/features/superadmin/presentation/components/profile/widget/profile_info_boxes.dart';
import 'package:open_vts/features/superadmin/presentation/components/profile/widget/profile_recent_activity_box.dart';
import 'package:open_vts/features/superadmin/presentation/components/profile/widget/profile_setting_box.dart';
import 'package:open_vts/features/superadmin/presentation/layout/app_layout.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  SuperadminProfile? _profile;
  List<ProfileActivityEntry> _activities = const <ProfileActivityEntry>[];
  List<String> _socialLinks = const <String>[];
  String _roleLabel = '-';

  bool _loadingProfile = false;
  bool _loadingActivity = false;
  bool _errorShown = false;
  bool _loadFailed = false;

  AppCancellationHandle? _token;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _token?.cancel('ProfileScreen disposed');
    super.dispose();
  }

  void _ensureRepo() {
    if (_repo != null) return;
    _repo = ref.read(superadminRepositoryAdapterProvider);
  }

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _usernameLabel(String value) {
    final text = _display(value);
    if (text == '-') return '-';
    return text.startsWith('@') ? text : '@$text';
  }

  String _initials(String name, String username) {
    final source = name == '-' ? username : name;
    final clean = source.replaceAll('@', ' ').trim();
    if (clean.isEmpty || clean == '-') return '--';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  DateTime? _parseDate(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  String _formatDate(String? raw, {bool includeTime = false}) {
    final dt = _parseDate(raw);
    if (dt == null) return _display(raw);
    String two(int n) => n.toString().padLeft(2, '0');
    if (!includeTime) {
      return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
    }
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  List<ProfileActivityEntry> _buildActivities({
    required List<SuperadminRecentUser> users,
    required List<SuperadminRecentVehicle> vehicles,
  }) {
    final list = <Map<String, Object?>>[];

    for (final u in users) {
      final dt = _parseDate(u.time);
      final name = _display(u.name, fallback: 'User');
      final email = _display(u.email);
      list.add(<String, Object?>{
        'dt': dt,
        'entry': ProfileActivityEntry(
          title: 'User Created',
          time: _formatDate(u.time, includeTime: true),
          subtitle: '$name | $email',
        ),
      });
    }

    for (final v in vehicles) {
      final dt = _parseDate(v.time);
      final name = _display(v.name, fallback: 'Vehicle');
      final id = _display(v.id);
      list.add(<String, Object?>{
        'dt': dt,
        'entry': ProfileActivityEntry(
          title: 'Vehicle Added',
          time: _formatDate(v.time, includeTime: true),
          subtitle: '$name | $id',
        ),
      });
    }

    list.sort((a, b) {
      final ad = a['dt'] as DateTime?;
      final bd = b['dt'] as DateTime?;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return list
        .take(8)
        .map((it) => it['entry']! as ProfileActivityEntry)
        .toList(growable: false);
  }

  Future<String> _readRoleFromToken() async {
    final token = await ref.read(sessionServiceProvider).readAccessToken();
    if (token == null || token.trim().isEmpty) return '';
    return AuthRepository.extractRole(null, token: token)?.trim() ?? '';
  }

  Future<void> _loadProfile() async {
    _token?.cancel('Reload profile');
    final token = AppCancellationHandle();
    _token = token;

    if (!mounted) return;
    updateLocalUiState(this, () {
      _loadingProfile = true;
      _loadingActivity = true;
      _loadFailed = false;
    });

    try {
      _ensureRepo();

      final profileFuture = _repo!.getSuperadminProfile(cancelToken: token);
      final usersFuture = _repo!.getRecentUsers(cancelToken: token);
      final vehiclesFuture = _repo!.getRecentVehicles(cancelToken: token);
      final roleFuture = _readRoleFromToken();

      final profileRes = await profileFuture;
      final usersRes = await usersFuture;
      final vehiclesRes = await vehiclesFuture;
      final tokenRole = await roleFuture;

      if (!mounted) return;

      SuperadminProfile? nextProfile;
      final users = <SuperadminRecentUser>[];
      final vehicles = <SuperadminRecentVehicle>[];

      profileRes.when(
        success: (profile) => nextProfile = profile,
        failure: (err) {
          if (!_errorShown) {
            _errorShown = true;
            final msg =
                (LegacyErrorPresenter.isApiFailure(err) &&
                    (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403))
                ? 'Not authorized to view profile.'
                : "Couldn't load profile.";
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
      );

      usersRes.when(success: (rows) => users.addAll(rows), failure: (_) {});
      vehiclesRes.when(
        success: (rows) => vehicles.addAll(rows),
        failure: (_) {},
      );

      final roleFromProfile = _display(nextProfile?.roleName, fallback: '');
      final role = roleFromProfile.isNotEmpty && roleFromProfile != '-'
          ? roleFromProfile
          : _display(tokenRole, fallback: '-');

      updateLocalUiState(this, () {
        _loadingProfile = false;
        _loadingActivity = false;
        _errorShown = false;
        _loadFailed = nextProfile == null;
        _profile = nextProfile;
        _roleLabel = role;
        _socialLinks = nextProfile?.socialLabels ?? const <String>[];
        _activities = _buildActivities(users: users, vehicles: vehicles);
      });
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () {
        _loadingProfile = false;
        _loadingActivity = false;
        _loadFailed = true;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load profile.")));
    }
  }

  void _onDelete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Profile?'),
          content: const Text(
            'This action is permanent and cannot be undone. All your data will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: cs.onSurface)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete profile API not available yet'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    final profile = _profile;
    final displayName = _display(
      profile?.fullName,
      fallback: _display(profile?.username),
    );
    final username = _usernameLabel(_display(profile?.username));
    final profileId = _display(profile?.id, fallback: '');

    return AppLayout(
      title: 'Open VTS',
      subtitle: 'Profile',
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: [
            ProfileSettingBox(
              adminId: profileId,
              displayName: displayName,
              username: username,
              email: _display(profile?.email),
              roleLabel: _roleLabel,
              initials: _initials(displayName, username),
              isActive: profile?.isActive,
              isVerified: profile?.isVerified,
              loading: _loadingProfile,
              onProfileUpdated: _loadProfile,
            ),
            const SizedBox(height: 24),
            ProfileInfoBoxes(
              lastLogin: _formatDate(profile?.lastLogin, includeTime: true),
              createdAt: _formatDate(profile?.createdAt),
              loading: _loadingProfile,
            ),
            const SizedBox(height: 24),
            ProfileCompanyBox(
              profile: profile,
              socialLinks: _socialLinks,
              loading: _loadingProfile,
            ),
            const SizedBox(height: 24),
            ProfileRecentActivityBox(
              activities: _activities,
              loading: _loadingActivity,
            ),
            if (_loadFailed) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: _loadProfile, child: const Text('Retry')),
            ],
            const SizedBox(height: 24),
            ProfileDeleteBox(onDelete: _onDelete),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
