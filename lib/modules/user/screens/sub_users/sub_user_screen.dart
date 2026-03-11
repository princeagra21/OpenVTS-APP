import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_subuser_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_subusers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SubUserScreen extends StatefulWidget {
  const SubUserScreen({super.key});

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
              style: GoogleFonts.inter(
                fontSize: bodyFs + 1,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a sub-user from the web console to manage delegated access.',
              style: GoogleFonts.inter(
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
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchQuery = _searchController.text.toLowerCase().trim();

    final filteredSubUsers = _subUsers.where((u) {
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

    Color getStatusColor(String status) {
      return status == "Active" ? Colors.green : Colors.red;
    }

    return AppLayout(
      title: "USER",
      subtitle: "Sub-users",
      actionIcons: const [CupertinoIcons.add],
      onActionTaps: [
        () async {
          final result = await context.push('/user/sub-users/add');
          if (result == true) {
            _loadSubUsers();
          }
        },
      ],
      showLeftAvatar: false,
      leftAvatarText: 'SU',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: hp * 3.5,
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
                  hintText: "Search name, username, mobile, email...",
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp,
                  ),
                ),
              ),
            ),
            SizedBox(height: hp),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Active", "Disabled"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: hp),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredSubUsers.length} of ${_subUsers.length} sub-users",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),
            if (_loading)
              ...List.generate(
                3,
                (_) => _buildShimmerCard(
                  colorScheme,
                  width,
                  hp,
                  spacing,
                  cardPadding,
                ),
              )
            else if (filteredSubUsers.isEmpty)
              _buildEmptyCard(colorScheme, hp, bodyFs)
            else
              ...filteredSubUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final subUser = entry.value;
                final statusColor = getStatusColor(subUser.statusLabel);
                final initials = _getInitials(subUser.name);

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + index * 50),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(bottom: hp),
                  child: Container(
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
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {},
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: AdaptiveUtils.getAvatarSize(width) / 2,
                                backgroundColor: colorScheme.primary,
                                child: Text(
                                  initials,
                                  style: GoogleFonts.inter(
                                    fontSize: AdaptiveUtils.getFsAvatarFontSize(
                                      width,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing * 1.5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subUser.name.isEmpty
                                                ? '—'
                                                : subUser.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs + 2,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: spacing + 4,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            subUser.statusLabel,
                                            style: GoogleFonts.inter(
                                              fontSize: smallFs + 1,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.person_crop_circle,
                                          size: iconSize,
                                          color: colorScheme.primary
                                              .withOpacity(0.87),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            subUser.username.isEmpty
                                                ? '—'
                                                : subUser.username,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
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
                                          CupertinoIcons.phone,
                                          size: iconSize,
                                          color: colorScheme.primary
                                              .withOpacity(0.87),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _makePhoneCall(
                                              subUser.fullPhone,
                                            ),
                                            child: Text(
                                              subUser.fullPhone.isEmpty
                                                  ? '—'
                                                  : subUser.fullPhone,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs,
                                                color: colorScheme.primary,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.call,
                                            size: iconSize,
                                            color: isDark
                                                ? colorScheme.primary
                                                : Colors.green,
                                          ),
                                          onPressed: () =>
                                              _makePhoneCall(subUser.fullPhone),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing / 2),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.mail,
                                          size: iconSize,
                                          color: colorScheme.primary
                                              .withOpacity(0.87),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            subUser.email.isEmpty
                                                ? '—'
                                                : subUser.email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
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
                                          CupertinoIcons.shield,
                                          size: iconSize,
                                          color: colorScheme.primary
                                              .withOpacity(0.87),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            subUser.permissionsLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              color: colorScheme.onSurface,
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
                      ),
                    ),
                  ),
                );
              }),
            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }
}
