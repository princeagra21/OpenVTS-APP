import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_subuser_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_subusers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SubUserScreen extends StatefulWidget {
  final bool embedded;

  const SubUserScreen({super.key, this.embedded = false});

  @override
  State<SubUserScreen> createState() => _SubUserScreenState();
}

class _SubUserScreenState extends State<SubUserScreen> {
  // FleetStack-API-Reference.md + Postman confirmed:
  // - GET /user/subusers
  // - POST /user/subusers
  // - GET /user/subusers/:id
  // - PATCH /user/subusers/:id
  // - DELETE /user/subusers/:id
  //
  // This slice wires the existing list screen to GET /user/subusers only.
  String selectedTab = "All";
  int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();

  ApiClient? _apiClient;
  UserSubUsersRepository? _repo;
  CancelToken? _token;

  List<UserSubUserItem> _subUsers = <UserSubUserItem>[];
  bool _loading = false;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadSubUsers();
  }

  @override
  void dispose() {
    _token?.cancel('Sub users disposed');
    _searchController.dispose();
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

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadSubUsers() async {
    _token?.cancel('Reload sub users');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getSubUsers(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (items) {
        setState(() {
          _subUsers = items;
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
            : "Couldn't load sub-users.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _makePhoneCall(String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer for $rawPhone')),
      );
    }
  }

  String _getInitials(String name) {
    final safeName = name.trim().isEmpty ? 'SU' : name.trim();
    final parts = safeName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final int take = safeName.length >= 2 ? 2 : safeName.length;
    return safeName.substring(0, take).toUpperCase();
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
    double cardPadding,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: hp),
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
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppShimmer(width: 48, height: 48, radius: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppShimmer(
                          width: double.infinity,
                          height: 18,
                          radius: 8,
                        ),
                      ),
                      SizedBox(width: 12),
                      AppShimmer(width: 70, height: 24, radius: 12),
                    ],
                  ),
                  SizedBox(height: 10),
                  AppShimmer(width: 160, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 220, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 240, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 110, height: 14, radius: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ColorScheme colorScheme, double hp, double bodyFs) {
    return Container(
      margin: EdgeInsets.only(bottom: hp),
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
      child: Padding(
        padding: EdgeInsets.all(hp + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No sub-users found',
              style: GoogleFonts.roboto(
                fontSize: bodyFs + 1,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a sub-user from the web console to manage delegated access.',
              style: GoogleFonts.roboto(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 390).clamp(0.9, 1.05);
    final fsSection = 18 * scale;
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final double iconSize = 18.0;
    final double cardPadding = hp + 4;

    final searchQuery = _searchController.text.toLowerCase().trim();

    var filteredSubUsers = _subUsers.where((u) {
      final matchesSearch =
          searchQuery.isEmpty ||
          u.name.toLowerCase().contains(searchQuery) ||
          u.username.toLowerCase().contains(searchQuery) ||
          u.fullPhone.toLowerCase().contains(searchQuery) ||
          u.email.toLowerCase().contains(searchQuery) ||
          u.permissionsLabel.toLowerCase().contains(searchQuery);

      final matchesTab =
          selectedTab == "All" ||
          (selectedTab == "Active" && u.isActive) ||
          (selectedTab == "Disabled" && !u.isActive);

      return matchesSearch && matchesTab;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    if (filteredSubUsers.length > _pageSize) {
      filteredSubUsers = filteredSubUsers.take(_pageSize).toList();
    }

    Color getStatusColor(String status) {
      return status == "Active" ? Colors.green : Colors.red;
    }

    final showNoData = !_loading && filteredSubUsers.isEmpty;
    final topPadding = MediaQuery.of(context).padding.top;

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.surfaceVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sub-users',
                    style: GoogleFonts.roboto(
                      fontSize: fsSection,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final result = await context.push('/user/sub-users/add');
                      if (result == true) {
                        _loadSubUsers();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: hp * 1.2,
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
                            'New',
                            style: GoogleFonts.roboto(
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
              SizedBox(height: hp),
              Container(
                height: hp * 3.5,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.roboto(
                    fontSize: fsMain,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search name, username, mobile, email...',
                    hintStyle: GoogleFonts.roboto(
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
                      horizontal: hp,
                      vertical: hp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: hp),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double gap = spacing;
                  final double cellWidth = (constraints.maxWidth - gap * 2) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: cellWidth,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (selectedTab == value) return;
                            setState(() => selectedTab = value);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'All', child: Text('All')),
                            PopupMenuItem(value: 'Active', child: Text('Active')),
                            PopupMenuItem(
                              value: 'Disabled',
                              child: Text('Disabled'),
                            ),
                          ],
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: hp,
                              vertical: spacing,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: iconSize,
                                  color: colorScheme.onSurface,
                                ),
                                SizedBox(width: spacing / 2),
                                Text(
                                  'Filter',
                                  style: GoogleFonts.roboto(
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
                            setState(() => _pageSize = value);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 10, child: Text('10')),
                            PopupMenuItem(value: 25, child: Text('25')),
                            PopupMenuItem(value: 50, child: Text('50')),
                          ],
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: hp,
                              vertical: spacing,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Records',
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMain - 3,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(width: spacing / 2),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: iconSize,
                                  color: colorScheme.onSurface,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: cellWidth,
                        child: InkWell(
                          onTap: _loadSubUsers,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: hp,
                              vertical: spacing,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: iconSize,
                                  color: colorScheme.onSurface,
                                ),
                                SizedBox(width: spacing / 2),
                                Text(
                                  'Refresh',
                                  style: GoogleFonts.roboto(
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
              SizedBox(height: hp),
              if (showNoData)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No sub-users found',
                        style: GoogleFonts.roboto(
                          fontSize: fsMain + 2,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: spacing / 2),
                      Text(
                        'Create a sub-user to get started.',
                        style: GoogleFonts.roboto(
                          fontSize: fsSecondary,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_loading)
                ...List<Widget>.generate(
                  3,
                  (index) => _buildShimmerCard(
                    colorScheme,
                    width,
                    hp,
                    spacing,
                    cardPadding,
                  ),
                ),
              if (!showNoData && !_loading)
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSubUsers.length,
                  itemBuilder: (context, index) {
                    final subUser = filteredSubUsers[index];
                    return _buildSubUserCard(
                      subUser: subUser,
                      colorScheme: colorScheme,
                      padding: hp,
                      spacing: spacing,
                      fsMain: fsMain,
                      fsSecondary: fsSecondary,
                      fsMeta: fsMeta,
                      iconSize: iconSize,
                      cardPadding: cardPadding,
                      screenWidth: width,
                    );
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: hp * 2),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              hp,
              topPadding + AppUtils.appBarHeightCustom + 28,
              hp,
              84,
            ),
            child: body,
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: UserHomeAppBar(
              title: 'Sub-users',
              leadingIcon: Icons.person_outline,
              onClose: () => context.go('/user/home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubUserCard({
    required UserSubUserItem subUser,
    required ColorScheme colorScheme,
    required double padding,
    required double spacing,
    required double fsMain,
    required double fsSecondary,
    required double fsMeta,
    required double iconSize,
    required double cardPadding,
    required double screenWidth,
  }) {
    final statusColor = subUser.statusLabel.toLowerCase() == 'active'
        ? Colors.green
        : Colors.red;
    final initials = _getInitials(subUser.name);
    final phone = subUser.fullPhone.trim().isEmpty ? '-' : subUser.fullPhone;
    final username =
        subUser.username.trim().isEmpty ? '-' : subUser.username;
    final email = subUser.email.trim().isEmpty ? '-' : subUser.email;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: padding),
      child: Container(
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
            onTap: () => context.push(
              '/user/sub-users/details/${subUser.id}',
              extra: subUser,
            ),
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
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface,
                              fontSize:
                                  AdaptiveUtils.getFsAvatarFontSize(screenWidth),
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
                                    subUser.name.isEmpty ? '-' : subUser.name,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMain,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    subUser.statusLabel,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMeta,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
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
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
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
                                  CupertinoIcons.person,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
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
                                  CupertinoIcons.mail,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  InkWell(
                    onTap: () => context.push(
                      '/user/sub-users/details/${subUser.id}',
                      extra: subUser,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                            Icons.chevron_right,
                            size: iconSize,
                            color: colorScheme.onPrimary,
                          ),
                          SizedBox(width: spacing),
                          Text(
                            'View',
                            style: GoogleFonts.roboto(
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
      ),
    );
  }
}
