import 'package:dio/dio.dart';
import 'package:open_vts/core/models/user_subuser_item.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/user_subusers_repository.dart';
import 'package:open_vts/core/repositories/user_vehicles_repository.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/app/router/app_route_paths.dart';

part 'sub_user_details_helpers.dart';
part 'sub_user_details_profile_tab.dart';
part 'sub_user_details_vehicles_tab.dart';

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
    _apiClient ??= AppContainer.instance.apiClient;
    _repo ??= UserSubUsersRepository(api: _apiClient!);
    return _repo!;
  }

  UserVehiclesRepository _vehiclesRepo() {
    _apiClient ??= AppContainer.instance.apiClient;
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

  Future<void> _unassignVehicleFromSubUser(
    Map<String, dynamic> vehicle,
    BuildContext context,
  ) async {
    final id = vehicle['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _assigning = true);
    final vehicleId = int.tryParse(id);
    final result = await _repoOrCreate().unassignVehicle(
      widget.userId,
      vehicleId == null ? <int>[] : [vehicleId],
    );
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (error) {
        String msg = 'Failed to unassign vehicle.';
        if (error is ApiException) {
          if (error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          final details = error.details;
          if (details is Map) {
            final detailMsg = details['message'] ?? details['error'];
            if (detailMsg is String && detailMsg.trim().isNotEmpty) {
              msg = detailMsg;
            }
          }
          // Debug log to surface server payload.
          AppLogger.debug('Unassign error details: ${error.details}');
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
    await _loadVehicles();
    if (mounted) {
      setState(() => _assigning = false);
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
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
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
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

  Future<void> _assignSelectedVehicles(List<String> vehicleIds) async {
    if (vehicleIds.isEmpty) return;
    setState(() => _assigning = true);
    for (final id in vehicleIds) {
      final vehicleId = int.tryParse(id);
      if (vehicleId == null) continue;
      final result = await _repoOrCreate().assignVehicle(widget.userId, [
        vehicleId,
      ]);
      if (!mounted) return;
      result.when(
        success: (_) {},
        failure: (error) {
          final msg = error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : 'Failed to assign vehicle.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
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
    final limitedAccess = _isLimitedAccess(_details ?? widget.initialSubUser);

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
            style: AppFonts.roboto(
              fontSize: fsMain + 2,
              fontWeight: FontWeight.w600,
              color: dangerColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            limitedAccess
                ? 'This sub-user was created by admin. Deletion is restricted.'
                : 'This action cannot be undone. It will permanently delete the sub-user and remove all associated data.',
            style: AppFonts.roboto(fontSize: fsMain, color: dangerColor),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: (_deleting || limitedAccess)
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
                      limitedAccess ? 'Locked' : 'Delete',
                      style: AppFonts.roboto(
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
                    style: AppFonts.roboto(
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
              style: AppFonts.roboto(
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
                      style: AppFonts.roboto(fontWeight: FontWeight.w600),
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
                      style: AppFonts.roboto(fontWeight: FontWeight.w700),
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
            style: AppFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.roboto(
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
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppFonts.inter(
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
