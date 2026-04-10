import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_subuser_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_subusers_repository.dart';
import 'package:fleet_stack/core/repositories/user_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubUserDetailsScreen extends StatefulWidget {
  final String userId;
  final UserSubUserItem? initialSubUser;

  const SubUserDetailsScreen({
    super.key,
    required this.userId,
    this.initialSubUser,
  });

  @override
  State<SubUserDetailsScreen> createState() => _SubUserDetailsScreenState();
}

class _SubUserDetailsScreenState extends State<SubUserDetailsScreen> {
  final List<String> _tabs = const ['Profile', 'Vehicles', 'Delete'];
  String _selectedTab = 'Profile';

  ApiClient? _apiClient;
  UserSubUsersRepository? _repo;
  CancelToken? _token;

  UserSubUserItem? _details;
  List<Map<String, dynamic>> _vehicles = const [];
  List<Map<String, dynamic>> _allVehicles = const [];
  bool _loading = false;
  bool _loadingVehicles = false;
  bool _errorShown = false;
  bool _deleting = false;
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadVehicles();
  }

  @override
  void dispose() {
    _token?.cancel('Sub user details disposed');
    super.dispose();
  }

  UserSubUsersRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserSubUsersRepository(api: _apiClient!);
    return _repo!;
  }

  UserVehiclesRepository _vehiclesRepo() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return UserVehiclesRepository(api: _apiClient!);
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadDetails() async {
    _token?.cancel('Reload sub user details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getSubUserDetails(
      widget.userId,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (details) {
        setState(() {
          _details = details;
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (error) {
        setState(() => _loading = false);
        if (_isCancelled(error) || _errorShown) return;
        _errorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load sub-user details.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _loadVehicles() async {
    if (!mounted) return;
    setState(() => _loadingVehicles = true);

    final result = await _repoOrCreate().getSubUserVehicles(widget.userId);
    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _vehicles = items;
          _loadingVehicles = false;
        });
      },
      failure: (_) {
        setState(() => _loadingVehicles = false);
      },
    );
  }

  Future<void> _loadAllVehicles() async {
    final result = await _vehiclesRepo().getVehicles(limit: 200);
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          _allVehicles = items.map((e) => e.raw).toList();
        });
      },
      failure: (_) {},
    );
  }

  String _safe(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '—';
    return text;
  }

  String _formatPhone(String prefix, String number) {
    final p = prefix.trim();
    final n = number.trim();
    if (p.isEmpty && n.isEmpty) return '—';
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p $n';
  }

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

  _DatePair _formatDateTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return const _DatePair('—', '');
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return _DatePair(text, '');
    final local = parsed.toLocal();
    final date = '${local.day}/${local.month}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return _DatePair(date, time);
  }

  Future<void> _deleteSubUser() async {
    if (_deleting) return;
    setState(() => _deleting = true);

    final result = await _repoOrCreate().deleteSubUser(widget.userId);
    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _deleting = false);
        Navigator.of(context).pop(true);
      },
      failure: (error) {
        setState(() => _deleting = false);
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : 'Failed to delete sub-user.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(w)
        ? 12.0
        : AdaptiveUtils.isSmallScreen(w)
            ? 14.0
            : 18.0;
    final topPadding = AdaptiveUtils.isVerySmallScreen(w)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(w)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 70,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NavigateBox(
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'Sub-user screens',
                  subtitle: 'Switch between sub-user sections below.',
                  onTabSelected: (tab) {
                    setState(() => _selectedTab = tab);
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedTab == 'Profile')
                  _buildProfileTab(context)
                else if (_selectedTab == 'Vehicles')
                  _buildVehiclesTab(context)
                else
                  _buildDeleteTab(context),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: UserHomeAppBar(
              title: 'Sub-user Details',
              leadingIcon: Icons.person_outline,
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
        border: Border.all(color: cs.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sub-user Overview',
            style: GoogleFonts.roboto(
              fontSize: 18 * (fs / 14),
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
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
                  ? colorScheme.surfaceVariant
                  : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
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
                        style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
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
    final equalizedCreated =
        created.time.isEmpty ? _DatePair(created.date, ' ') : created;
    final equalizedUpdated =
        updated.time.isEmpty ? _DatePair(updated.date, ' ') : updated;
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
    IconData _titleIcon(String t) {
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
                style: GoogleFonts.roboto(
                  fontSize: labelFs,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Icon(
                _titleIcon(title),
                size: 14 * scale,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pair.date,
            style: GoogleFonts.roboto(
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
              style: GoogleFonts.roboto(
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


  Widget _buildVehiclesTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final cardPadding = AdaptiveUtils.getHorizontalPadding(w) + 4;
    final scale = (w / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final iconSize = 18.0;

    if (_loadingVehicles) {
      return const AppShimmer(width: double.infinity, height: 180, radius: 12);
    }

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Vehicles',
                style: GoogleFonts.roboto(
                  fontSize: fsMain + 2,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              ElevatedButton(
                onPressed: _assigning
                    ? null
                    : () async {
                        await _loadAllVehicles();
                        if (!mounted) return;
                        _showAssignVehiclesSheet(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Assign Vehicles',
                  style: GoogleFonts.roboto(
                    fontSize: fsSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing / 2),
          Text(
            _vehicles.isEmpty
                ? 'No vehicles assigned to this sub-user.'
                : 'Vehicle list for this sub-user',
            style: GoogleFonts.roboto(
              fontSize: fsSecondary,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: spacing),
          if (_vehicles.isEmpty)
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
                    'No vehicles assigned',
                    style: GoogleFonts.roboto(
                      fontSize: fsMain + 2,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    'Assign vehicles to this sub-user to see them here.',
                    style: GoogleFonts.roboto(
                      fontSize: fsSecondary,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._vehicles.map((vehicle) {
              final name = _safe(vehicle['name']?.toString());
              final plate = _safe(vehicle['plateNumber']?.toString());
              final vin = _safe(vehicle['vin']?.toString());
              final imei = _safe(
                vehicle['imei']?.toString() ??
                    (vehicle['device'] is Map
                        ? (vehicle['device']['imei']?.toString() ?? '')
                        : ''),
              );
              final sim = _safe(
                vehicle['simNumber']?.toString() ??
                    (vehicle['device'] is Map
                        ? (vehicle['device']['sim']?.toString() ?? '')
                        : ''),
              );

              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: spacing),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40 * (fsMain / 14),
                            height: 40 * (fsMain / 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? cs.surfaceVariant
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: cs.outline.withOpacity(0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.directions_car_outlined,
                              size: 18 * (fsMain / 14),
                              color: cs.primary,
                            ),
                          ),
                          SizedBox(width: spacing * 1.5),
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
                                          fontSize: fsMain,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _assigning
                                          ? null
                                          : () async {
                                              final id =
                                                  vehicle['id']?.toString() ??
                                                      '';
                                              if (id.isEmpty) return;
                                              setState(
                                                () => _assigning = true,
                                              );
                                              final vehicleId =
                                                  int.tryParse(id);
                                              final result =
                                                  await _repoOrCreate()
                                                      .unassignVehicle(
                                                widget.userId,
                                                vehicleId == null
                                                    ? <int>[]
                                                    : [vehicleId],
                                              );
                                              if (!mounted) return;
                                              result.when(
                                                success: (_) {},
                                                failure: (error) {
                                                  String msg =
                                                      'Failed to unassign vehicle.';
                                                  if (error is ApiException) {
                                                    if (error.message
                                                        .trim()
                                                        .isNotEmpty) {
                                                      msg = error.message;
                                                    }
                                                    final details =
                                                        error.details;
                                                    if (details is Map) {
                                                      final detailMsg =
                                                          details['message'] ??
                                                              details['error'];
                                                      if (detailMsg
                                                              is String &&
                                                          detailMsg
                                                              .trim()
                                                              .isNotEmpty) {
                                                        msg = detailMsg;
                                                      }
                                                    }
                                                    // Debug log to surface server payload.
                                                    debugPrint(
                                                      'Unassign error details: ${error.details}',
                                                    );
                                                  }
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(msg),
                                                    ),
                                                  );
                                                },
                                              );
                                              await _loadVehicles();
                                              if (mounted) {
                                                setState(
                                                  () => _assigning = false,
                                                );
                                              }
                                            },
                                      style: TextButton.styleFrom(
                                        foregroundColor: cs.error,
                                      ),
                                      child: Text(
                                        'Unassign',
                                        style: GoogleFonts.roboto(
                                          fontSize: fsSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing * 0.4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? cs.surfaceVariant
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    plate,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMeta,
                                      height: 14 / 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: spacing * 0.4),
                                Text(
                                  vin,
                                  style: GoogleFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing * 1.2,
                                vertical: spacing - 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.memory_outlined,
                                        size: iconSize,
                                        color: cs.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'IMEI',
                                        style: GoogleFonts.roboto(
                                          fontSize: fsMeta,
                                          height: 14 / 11,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing),
                                  Text(
                                    imei,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: spacing / 2),
                                  Text(
                                    ' ',
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing * 1.2,
                                vertical: spacing - 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.memory_outlined,
                                        size: iconSize,
                                        color: cs.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'SIM',
                                        style: GoogleFonts.roboto(
                                          fontSize: fsMeta,
                                          height: 14 / 11,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: spacing + 2),
                                  Text(
                                    sim,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: spacing / 2),
                                  Text(
                                    ' ',
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _showAssignVehiclesSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assignedIds = _vehicles
        .map((v) => v['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final available = _allVehicles
        .where((v) => !assignedIds.contains(v['id']?.toString() ?? ''))
        .toList();

    final selected = <String>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Assign Vehicles',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: available.isEmpty
                            ? Center(
                                child: Text(
                                  'No available vehicles to assign.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: available.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final v = available[index];
                                  final id = v['id']?.toString() ?? '';
                                  final name = _safe(v['name']?.toString());
                                  final plate =
                                      _safe(v['plateNumber']?.toString());
                                  final checked = selected.contains(id);
                                  return CheckboxListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    title: Text(
                                      '$name • $plate',
                                      style: GoogleFonts.roboto(fontSize: 14),
                                    ),
                                    value: checked,
                                    onChanged: (bool? checked) {
                                      setState(() {
                                        if (checked == true) {
                                          selected.add(id);
                                        } else {
                                          selected.remove(id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selected.isEmpty
                                    ? null
                                    : () async {
                                        Navigator.pop(ctx);
                                        await _assignSelectedVehicles(
                                          selected.toList(),
                                        );
                                      },
                                child: const Text('Done'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignSelectedVehicles(List<String> vehicleIds) async {
    if (vehicleIds.isEmpty) return;
    setState(() => _assigning = true);
    for (final id in vehicleIds) {
      final vehicleId = int.tryParse(id);
      if (vehicleId == null) continue;
      final result =
          await _repoOrCreate().assignVehicle(widget.userId, [vehicleId]);
      if (!mounted) return;
      result.when(
        success: (_) {},
        failure: (error) {
          final msg = error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : 'Failed to assign vehicle.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    }
    await _loadVehicles();
    setState(() => _assigning = false);
  }

  Widget _buildDeleteTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w) + 4;
    final fsMain = 14 * ((w / 420).clamp(0.9, 1.0));
    final dangerColor = cs.error;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: dangerColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: GoogleFonts.roboto(
              fontSize: fsMain + 2,
              fontWeight: FontWeight.w600,
              color: dangerColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone. It will permanently delete the sub-user and remove all associated data.',
            style: GoogleFonts.roboto(
              fontSize: fsMain,
              color: dangerColor,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _deleting
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => _DeleteConfirmDialog(
                          title: 'Delete sub-user?',
                          message:
                              'This will permanently remove the sub-user. You can’t undo this action.',
                          dangerColor: dangerColor,
                        ),
                      );
                      if (confirmed == true) {
                        _deleteSubUser();
                      }
                    },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dangerColor, width: 2),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: padding * 2,
                  vertical: padding,
                ),
              ),
              child: _deleting
                  ? const AppShimmer(width: 18, height: 18, radius: 9)
                  : Text(
                      'Delete',
                      style: GoogleFonts.roboto(
                        fontSize: fsMain,
                        color: dangerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final Color dangerColor;

  const _DeleteConfirmDialog({
    required this.title,
    required this.message,
    required this.dangerColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: dangerColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: dangerColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: dangerColor,
                      foregroundColor: colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigateBox extends StatelessWidget {
  final String selectedTab;
  final List<String> tabs;
  final String title;
  final String subtitle;
  final ValueChanged<String> onTabSelected;

  const _NavigateBox({
    required this.selectedTab,
    required this.tabs,
    required this.title,
    required this.subtitle,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSubtitle = 12 * scale;
    final double fsTab = 13 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
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
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: fsSubtitle,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tabs.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SmallTab(
                      label: tab,
                      selected: selectedTab == tab,
                      fontSize: fsTab,
                      onTap: () => onTabSelected(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final double? fontSize;
  final VoidCallback? onTap;

  const _SmallTab({
    required this.label,
    this.selected = false,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double defaultFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 420 ? 10 : 14,
          vertical: screenWidth < 420 ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? defaultFontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DatePair {
  final String date;
  final String time;

  const _DatePair(this.date, this.time);
}
