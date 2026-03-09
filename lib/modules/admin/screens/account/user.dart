import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/adaptive_utils.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // Endpoint truth (FleetStack-API-Reference.md + Postman):
  // - GET /admin/users (query: search, status, page, limit where supported)
  // - GET /admin/users/:id
  // - PATCH /admin/users/:id (status toggle key used: isActive)
  // Users list extraction supports: userslist | users | data.userslist | data.users | items.

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AdminUserListItem>? _users;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;
  final Map<String, bool> _updatingUser = <String, bool>{};
  final Map<String, CancelToken> _toggleTokens = <String, CancelToken>{};

  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminUsersRepository? _repo;

  AdminUsersRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminUsersRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Users screen disposed');
    for (final token in _toggleTokens.values) {
      token.cancel('Users screen disposed');
    }
    _toggleTokens.clear();
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadUsers();
    });
  }

  String? _statusQueryForTab(String tab) {
    switch (tab) {
      case 'Active':
        return 'active';
      case 'Disabled':
        return 'disabled';
      case 'Pending':
        return 'pending';
      default:
        return null;
    }
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

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadUsers() async {
    _loadToken?.cancel('Reload users');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getUsers(
        search: _searchController.text.trim(),
        status: _statusQueryForTab(selectedTab),
        page: 1,
        limit: 50,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (items) {
          setState(() {
            _users = items;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          setState(() {
            _users = const [];
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load users.'
              : "Couldn't load users.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = const [];
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load users.");
    }
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

    if (_updatingUser[userId] == true) return;

    final previousValue = user.isActive;
    _setUserActiveOptimistic(userId, nextValue);

    setState(() {
      _updatingUser[userId] = true;
    });

    _toggleTokens[userId]?.cancel('Replace status toggle request');
    final token = CancelToken();
    _toggleTokens[userId] = token;

    try {
      final result = await _repoOrCreate().updateUserStatus(
        userId,
        nextValue,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          setState(() {
            _updatingUser.remove(userId);
            _toggleTokens.remove(userId);
          });
        },
        failure: (err) {
          setState(() {
            _setUserActiveOptimistic(userId, previousValue);
            _updatingUser.remove(userId);
            _toggleTokens.remove(userId);
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update user status.'
              : "Couldn't update user status.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setUserActiveOptimistic(userId, previousValue);
        _updatingUser.remove(userId);
        _toggleTokens.remove(userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update user status.")),
      );
    }
  }

  void _setUserActiveOptimistic(String userId, bool isActive) {
    final list = _users;
    if (list == null) return;

    final updated = list.map((user) {
      if (user.id != userId) return user;
      final raw = Map<String, dynamic>.from(user.raw);
      raw['isActive'] = isActive;
      raw['active'] = isActive;
      if (!isActive) {
        raw['status'] = 'Disabled';
      } else if (user.statusLabel.toLowerCase() == 'disabled') {
        raw['status'] = 'Verified';
      }
      return AdminUserListItem.fromRaw(raw);
    }).toList();

    _users = updated;
  }

  Future<void> _makePhoneCall(String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.trim().isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open dialer for $rawPhone')),
    );
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    return trimmed;
  }

  Color _statusBgColor(String status, ColorScheme colorScheme) {
    final s = status.toLowerCase();
    if (s.contains('verify')) return Colors.green.withOpacity(0.2);
    if (s.contains('pending')) return Colors.orange.withOpacity(0.2);
    if (s.contains('disable') || s.contains('inactive')) {
      return Colors.red.withOpacity(0.2);
    }
    return colorScheme.primary.withOpacity(0.15);
  }

  Color _statusTextColor(String status, ColorScheme colorScheme) {
    final s = status.toLowerCase();
    if (s.contains('verify')) return Colors.green;
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('disable') || s.contains('inactive')) return Colors.red;
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth);
    final bodyFs = titleFs - 1;
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4;

    final allUsers = _users ?? const <AdminUserListItem>[];
    final filteredUsers = _applyLocalFilters(allUsers);

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'User Management',
      showLeftAvatar: false,
      actionIcons: const [],
      onActionTaps: [],
      leftAvatarText: 'US',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: padding * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search name, email, role, department...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.primary,
                  ),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: padding,
                  ),
                ),
              ),
            ),
            SizedBox(height: padding),

            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ['All', 'Active', 'Disabled', 'Pending'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () {
                    if (selectedTab == tab) return;
                    setState(() => selectedTab = tab);
                    _loadUsers();
                  },
                );
              }).toList(),
            ),

            SizedBox(height: padding),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredUsers.length} of ${allUsers.length} users',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loading
                  ? 3
                  : (filteredUsers.isEmpty ? 1 : filteredUsers.length),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _buildShimmerCard(
                    colorScheme,
                    padding,
                    spacing,
                    cardPadding,
                    screenWidth,
                  );
                }

                if (filteredUsers.isEmpty) {
                  return _buildPlaceholderCard(
                    colorScheme,
                    padding,
                    bodyFs,
                    cardPadding,
                  );
                }

                final user = filteredUsers[index];
                return _buildUserCard(
                  user,
                  colorScheme,
                  padding,
                  spacing,
                  bodyFs,
                  smallFs,
                  iconSize,
                  cardPadding,
                  screenWidth,
                  isDark,
                );
              },
            ),

            SizedBox(height: padding * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double padding,
    double spacing,
    double cardPadding,
    double screenWidth,
  ) {
    final avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);

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
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppShimmer(
                    width: avatarSize,
                    height: avatarSize,
                    radius: avatarSize / 2,
                  ),
                  SizedBox(width: spacing * 2),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmer(width: 180, height: 16, radius: 8),
                        SizedBox(height: 10),
                        AppShimmer(width: 220, height: 14, radius: 8),
                        SizedBox(height: 8),
                        AppShimmer(width: 200, height: 14, radius: 8),
                        SizedBox(height: 8),
                        AppShimmer(width: 140, height: 14, radius: 8),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 2),
              const AppShimmer(width: 80, height: 20, radius: 10),
              SizedBox(height: spacing),
              const AppShimmer(width: double.infinity, height: 14, radius: 8),
              SizedBox(height: spacing),
              const Divider(),
              SizedBox(height: spacing),
              Row(
                children: const [
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: 12,
                      radius: 8,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: 12,
                      radius: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(
    ColorScheme colorScheme,
    double padding,
    double bodyFs,
    double cardPadding,
  ) {
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
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Text(
            'No users found',
            style: GoogleFonts.inter(
              fontSize: bodyFs + 1,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
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
    double bodyFs,
    double smallFs,
    double iconSize,
    double cardPadding,
    double screenWidth,
    bool isDark,
  ) {
    return _buildUserCardBody(
      user: user,
      colorScheme: colorScheme,
      padding: padding,
      spacing: spacing,
      bodyFs: bodyFs,
      smallFs: smallFs,
      iconSize: iconSize,
      cardPadding: cardPadding,
      screenWidth: screenWidth,
      isDark: isDark,
    );
  }

  Widget _buildUserCardBody({
    required AdminUserListItem? user,
    required ColorScheme colorScheme,
    required double padding,
    required double spacing,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
    required double screenWidth,
    required bool isDark,
  }) {
    final isPlaceholder = user == null;
    final userId = user?.id ?? 'placeholder';
    final isUpdating = _updatingUser[userId] == true;

    final name = _safe(user?.fullName ?? '');
    final status = _safe(user?.statusLabel ?? '');
    final phone = _safe(user?.fullPhone ?? '');
    final email = _safe(user?.email ?? '');
    final vehicles = user?.vehiclesCount ?? 0;
    final location = _safe(user?.location ?? '');
    final joined = _safe(user?.joinedAt ?? '');
    final role = _safe(user?.roleLabel ?? '');
    final initials = _safe(user?.initials ?? '--');

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
          onTap: isPlaceholder
              ? null
              : () {
                  final id = user.id.trim();
                  if (id.isEmpty) return;
                  context.push('/admin/users/details/$id');
                },
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          color: colorScheme.onPrimary,
                          fontSize: AdaptiveUtils.getFsAvatarFontSize(
                            screenWidth,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing * 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: bodyFs,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: spacing),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: spacing + 2,
                                        vertical: spacing - 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusBgColor(
                                          status,
                                          colorScheme,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        status,
                                        style: GoogleFonts.inter(
                                          fontSize: smallFs,
                                          fontWeight: FontWeight.w600,
                                          color: _statusTextColor(
                                            status,
                                            colorScheme,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isPlaceholder)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: padding + 4,
                                    vertical: spacing - 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(
                                        0.5,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs + 1,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: spacing),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.phone,
                                size: iconSize,
                                color: colorScheme.primary.withOpacity(0.87),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (!isPlaceholder)
                                IconButton(
                                  tooltip: 'Call $name',
                                  onPressed: () => _makePhoneCall(phone),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth: 48,
                                    minHeight: iconSize,
                                  ),
                                  icon: Icon(
                                    Icons.call,
                                    size: iconSize,
                                    color: isDark
                                        ? colorScheme.primary
                                        : Colors.green,
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
                                color: colorScheme.primary.withOpacity(0.87),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car_filled_outlined,
                                size: iconSize,
                                color: colorScheme.primary.withOpacity(0.87),
                              ),
                              SizedBox(width: spacing),
                              Text(
                                isPlaceholder
                                    ? '— Vehicles'
                                    : '$vehicles Vehicles',
                                style: GoogleFonts.inter(
                                  fontSize: bodyFs,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: smallFs + 1,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: isPlaceholder ? false : user.isActive,
                        onChanged: (isPlaceholder || isUpdating)
                            ? null
                            : (v) => _toggleUserActive(user, v),
                        activeColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveThumbColor: colorScheme.onPrimary,
                        inactiveTrackColor: colorScheme.primary.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      size: iconSize,
                      color: colorScheme.primary.withOpacity(0.87),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Divider(color: colorScheme.onSurface.withOpacity(0.1)),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Joined: $joined',
                        style: GoogleFonts.inter(
                          fontSize: smallFs,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        role,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: smallFs - 1,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
