import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/router/route_names.dart';

import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_account_error_presenter.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_user_list_controller.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class UserScreen extends ConsumerStatefulWidget {
  const UserScreen({super.key});

  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends ConsumerState<UserScreen> {
  // Endpoint truth (API reference documentation + Postman):
  // - GET /admin/users (query: search, status, page, limit where supported)
  // - GET /admin/users/:id
  // - PATCH /admin/users/:id (status toggle key used: isActive)
  // Users list extraction supports: userslist | users | data.userslist | data.users | items.

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 10;

  ProviderSubscription<AdminUserListState>? _userListErrorSubscription;


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _userListErrorSubscription = ref.listenManual<AdminUserListState>(
      adminUserListControllerProvider,
      (previous, next) {
        final error = next.error;
        if (error == null || previous?.error == error || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminAccountErrorMessage(error).isNotEmpty ? adminAccountErrorMessage(error) : 'Request failed.')),
        );
      },
    );
    _loadUsers();
  }

  @override
  void dispose() {
    _userListErrorSubscription?.close();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadUsers();
  }

  String normalizeStatus(String? raw, {bool? isActive}) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      if (isActive == true) return 'active';
      if (isActive == false) return 'disabled';
      return '';
    }

    if (value == 'enabled' || value == 'enable' || value == 'verified') {
      return 'active';
    }
    if (value == 'inactive' || value == 'disable' || value == 'disabled') {
      return 'disabled';
    }
    if (value == 'pending') return 'pending';

    if (value.contains('pend')) return 'pending';
    if (value.contains('disable') || value.contains('inactiv')) {
      return 'disabled';
    }
    if (value.contains('enable') ||
        value.contains('active') ||
        value.contains('verify')) {
      return 'active';
    }

    return value;
  }

  Future<void> _loadUsers() async {
    await ref.read(adminUserListControllerProvider.notifier).load(
          search: _searchController.text.trim(),
          status: null,
          page: 1,
          limit: 50,
        );
  }

  List<AdminUserListItem> _applyLocalFilters(List<AdminUserListItem> source) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminUserListItem user) {
      if (selectedTab == 'All') return true;
      final expectedStatus = normalizeStatus(selectedTab);
      final actualStatus = normalizeStatus(
        user.statusLabel,
        isActive: user.isActive,
      );
      return expectedStatus == actualStatus;
    }

    bool queryMatch(AdminUserListItem user) {
      if (query.isEmpty) return true;

      final fields = [
        user.fullName,
        user.fullPhone,
        user.username,
        user.email,
        normalizeStatus(user.statusLabel, isActive: user.isActive),
        user.vehiclesCount.toString(),
        user.location,
        user.joinedAt,
        user.roleLabel,
      ];

      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((u) => tabMatch(u) && queryMatch(u)).toList();
  }

  Future<void> _toggleUserActive(AdminUserListItem user, bool nextValue) async {
    final userId = user.id.trim();
    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID is missing.')));
      return;
    }

    final ok = await ref
        .read(adminUserListControllerProvider.notifier)
        .updateStatus(user, nextValue);
    if (ok || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't update user status.")),
    );
  }

  Future<void> _loginAsUser(AdminUserListItem user) async {
    final userId = user.id.trim();
    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID is missing.')));
      return;
    }

    final newToken = await ref
        .read(adminUserListControllerProvider.notifier)
        .loginAsUser(userId);
    if (newToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed.')));
      return;
    }

    await ref.read(adminAccountCommandControllerProvider).startImpersonation(newToken);
    if (!mounted) return;
    context.go(AppRoutePaths.userHome);
  }

  Future<void> _confirmLoginAsUser(AdminUserListItem user) async {
    final name = _safe(user.fullName);
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (_) => _UserLoginConfirmDialog(userName: name),
    );
    if (shouldLogin != true) return;
    await _loginAsUser(user);
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    return trimmed;
  }

  String _formatDateOnly(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return '—';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final scale = (screenWidth / 390).clamp(0.9, 1.05);
    final fsSection = 18 * scale;
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final iconSize = 18.0;
    final cardPadding = padding + 4;

    final userListState = ref.watch(adminUserListControllerProvider);
    final allUsers = userListState.items;
    final loading = userListState.isLoading;
    var filteredUsers = _applyLocalFilters(allUsers);

    if (filteredUsers.length > _pageSize) {
      filteredUsers = filteredUsers.take(_pageSize).toList();
    }

    final showNoData = !loading && filteredUsers.isEmpty;

    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              padding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              padding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Users",
                            style: AppFonts.roboto(
                              fontSize: fsSection,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final created = await context.push<bool>(
                                AppRoutePaths.adminUsersAdd,
                              );
                              if (created == true) {
                                _loadUsers();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 1.2,
                                vertical: spacing,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: iconSize,
                                    color: colorScheme.surface,
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    "New",
                                    style: AppFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: padding),
                      Container(
                        height: padding * 3.5,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppFonts.roboto(
                            fontSize: fsMain,
                            height: 20 / 14,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search name, email, role, department...",
                            hintStyle: AppFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: fsSecondary,
                              height: 16 / 12,
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: iconSize + 2,
                              color: colorScheme.onSurface,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: padding,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: padding),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double gap = spacing;
                          final double cellWidth =
                              (constraints.maxWidth - gap * 2) / 3;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: cellWidth,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (selectedTab == value) return;
                                    updateLocalUiState(this, () => selectedTab = value);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: "All",
                                      child: Text('All'),
                                    ),
                                    PopupMenuItem(
                                      value: "Active",
                                      child: Text('Active'),
                                    ),
                                    PopupMenuItem(
                                      value: "Disabled",
                                      child: Text('Disabled'),
                                    ),
                                    PopupMenuItem(
                                      value: "Pending",
                                      child: Text('Pending'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: iconSize,
                                          color: colorScheme.onSurface,
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Text(
                                          "Filter",
                                          style: AppFonts.roboto(
                                            fontSize: fsMain - 3,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: PopupMenuButton<int>(
                                  onSelected: (value) {
                                    if (_pageSize == value) return;
                                    updateLocalUiState(this, () => _pageSize = value);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 10, child: Text('10')),
                                    PopupMenuItem(value: 25, child: Text('25')),
                                    PopupMenuItem(value: 50, child: Text('50')),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Records",
                                              style: AppFonts.roboto(
                                                fontSize: fsMain - 3,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(width: spacing / 2),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              size: iconSize,
                                              color: colorScheme.onSurface,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: InkWell(
                                  onTap: _loadUsers,
                                  borderRadius: BorderRadius.circular(12),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          size: iconSize,
                                          color: colorScheme.onSurface,
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Text(
                                          "Refresh",
                                          style: AppFonts.roboto(
                                            fontSize: fsMain - 3,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: padding),
                      if (showNoData)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: padding),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(cardPadding),
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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userListState.error != null
                                        ? "Couldn't load users."
                                        : "No users found",
                                    style: AppFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.8,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (userListState.error != null)
                                  TextButton(
                                    onPressed: _loadUsers,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (loading)
                        ...List<Widget>.generate(
                          3,
                          (index) => _buildUserSkeletonCard(
                            padding: padding,
                            spacing: spacing,
                            cardPadding: cardPadding,
                            screenWidth: screenWidth,
                            bodyFs: fsMain,
                            smallFs: fsMeta,
                          ),
                        ),
                      if (!showNoData && !loading)
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildUserCard(
                              user,
                              colorScheme,
                              padding,
                              spacing,
                              fsMain,
                              fsSecondary,
                              fsMeta,
                              iconSize,
                              cardPadding,
                              screenWidth,
                              userListState.updatingIds,
                              userListState.loggingInIds,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: padding * 2),
              ],
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Users',
              leadingIcon: Icons.group,
              onClose: () => context.go(AppRoutePaths.adminHome),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSkeletonCard({
    required double padding,
    required double spacing,
    required double cardPadding,
    required double screenWidth,
    required double bodyFs,
    required double smallFs,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(
                    width: AdaptiveUtils.getAvatarSize(screenWidth),
                    height: AdaptiveUtils.getAvatarSize(screenWidth),
                    radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                  ),
                  SizedBox(width: spacing * 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppShimmer(
                                width: double.infinity,
                                height: bodyFs + 8,
                                radius: 8,
                              ),
                            ),
                            SizedBox(width: spacing),
                            AppShimmer(
                              width: 70,
                              height: smallFs + 10,
                              radius: 999,
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: screenWidth * 0.35,
                          height: bodyFs + 8,
                          radius: 8,
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: screenWidth * 0.45,
                          height: bodyFs + 6,
                          radius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 2),
              Row(
                children: [
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: bodyFs + 18,
                      radius: 12,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: bodyFs + 18,
                      radius: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 2),
              AppShimmer(
                width: screenWidth * 0.4,
                height: smallFs + 10,
                radius: 8,
              ),
              SizedBox(height: spacing),
              AppShimmer(
                width: double.infinity,
                height: smallFs + 10,
                radius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    AdminUserListItem user,
    ColorScheme colorScheme,
    double padding,
    double spacing,
    double fsMain,
    double fsSecondary,
    double fsMeta,
    double iconSize,
    double cardPadding,
    double screenWidth,
    Set<String> updatingIds,
    Set<String> loggingInIds,
  ) {
    final raw = user.raw;
    final name = _safe(user.fullName);
    final email = _safe(user.email);
    final phone = _safe(user.fullPhone);
    final username = _safe(user.username);
    final addressMap = raw['address'] is Map
        ? Map<String, Object?>.from((raw['address'] as Map).cast())
        : const <String, Object?>{};
    final address = _safe(
      addressMap.isNotEmpty
          ? (addressMap['addressLine'] ?? addressMap['fullAddress'] ?? addressMap['line1'])?.toString() ?? ''
          : (raw['addressLine'] ?? raw['fullAddress'] ?? raw['address'])?.toString() ?? '',
    );
    final location = _safe(user.location);
    final joined = _formatDateOnly(user.joinedAt);
    final initials = _safe(user.initials);
    final userId = user.id.trim();
    final isUpdating = updatingIds.contains(userId);
    final isLoggingIn = loggingInIds.contains(userId);

    return Container(
      margin: EdgeInsets.only(bottom: padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: userId.isEmpty
              ? null
              : () => context.push(AppRoutePaths.adminUsersDetails(userId)),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.surface,
                      radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                      foregroundColor: colorScheme.onSurface,
                      child: Container(
                        width: AdaptiveUtils.getAvatarSize(screenWidth),
                        height: AdaptiveUtils.getAvatarSize(screenWidth),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: AppFonts.roboto(
                            color: colorScheme.onSurface,
                            fontSize: AdaptiveUtils.getFsAvatarFontSize(
                              screenWidth,
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
                          InkWell(
                            onTap: userId.isEmpty
                                ? null
                                : () => context.push(
                                    AppRoutePaths.adminUsersDetails(userId),
                                  ),
                            child: Text(
                              name,
                              style: AppFonts.roboto(
                                fontSize: fsMain,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 3,
                              softWrap: true,
                            ),
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: iconSize,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  username,
                                  style: AppFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  maxLines: 3,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.mail,
                                size: iconSize,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  email,
                                  style: AppFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  maxLines: 3,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.phone,
                                size: iconSize,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: AppFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: iconSize,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  address,
                                  style: AppFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  maxLines: 3,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing),
                    Align(
                      alignment: Alignment.topRight,
                      child: Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: user.isActive,
                          onChanged: isUpdating
                              ? null
                              : (v) => _toggleUserActive(user, v),
                          activeThumbColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(
                            0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 1.5),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: spacing,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location",
                        style: AppFonts.roboto(
                          fontSize: fsMeta,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: spacing / 2),
                      Text(
                        location,
                        maxLines: 6,
                        softWrap: true,
                        style: AppFonts.roboto(
                          fontSize: fsSecondary,
                          height: 16 / 12,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: spacing - 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: iconSize,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Text(
                              "Joined",
                              style: AppFonts.roboto(
                                fontSize: fsMeta,
                                height: 14 / 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Text(
                        joined,
                        style: AppFonts.roboto(
                          fontSize: fsMain,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                GestureDetector(
                  onTap: isLoggingIn ? null : () => _confirmLoginAsUser(user),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: spacing * 1.6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login,
                          size: iconSize,
                          color: colorScheme.onPrimary,
                        ),
                        SizedBox(width: spacing),
                        isLoggingIn
                            ? const AppShimmer(width: 16, height: 16, radius: 8)
                            : Text(
                                "Login as User",
                                style: AppFonts.roboto(
                                  fontSize: fsMain,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserLoginConfirmDialog extends StatelessWidget {
  final String userName;

  const _UserLoginConfirmDialog({required this.userName});

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
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.login,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Login as user?',
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
              'You are about to enter the user module as $userName. You can return to admin at any time.',
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
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Login',
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
