import 'dart:async';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/router/route_names.dart';

import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_team_list_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 10;

  Timer? _searchDebounce;


  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTeams();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      updateLocalUiState(this, () {});
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadTeams();
    });
  }

  void _showLoadErrorOnce(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTeams() async {
    await ref.read(adminTeamListControllerProvider.notifier).loadTeams(
          search: _searchController.text.trim(),
          page: 1,
          limit: 50,
        );
  }

  List<AdminTeamListItem> _applyLocalFilters(List<AdminTeamListItem> source) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminTeamListItem item) {
      if (selectedTab == 'All') return true;
      final expected = selectedTab.toLowerCase();
      final actual = item.statusLabel.toLowerCase();
      return expected == actual;
    }

    bool queryMatch(AdminTeamListItem item) {
      if (query.isEmpty) return true;

      final fields = [
        item.fullName,
        item.username,
        item.email,
        item.fullPhone,
        item.statusLabel,
        item.joinedAt,
      ];

      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((t) => tabMatch(t) && queryMatch(t)).toList();
  }

  Future<void> _toggleTeamActive(AdminTeamListItem team, bool nextValue) async {
    final teamId = team.id.trim();
    if (teamId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team member ID is missing.')),
      );
      return;
    }

    final ok = await ref
        .read(adminTeamListControllerProvider.notifier)
        .updateStatus(team, nextValue);
    if (!mounted || ok) return;
    final message = ref.read(adminTeamListControllerProvider).errorMessage ??
        "Couldn't update team status.";
    _showLoadErrorOnce(message);
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
    return '${parsed.toLocal().day}/${parsed.toLocal().month}/${parsed.toLocal().year}';
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

    final listState = ref.watch(adminTeamListControllerProvider);
    final allTeams = listState.items;
    var filteredTeams = _applyLocalFilters(allTeams);
    if (filteredTeams.length > _pageSize) {
      filteredTeams = filteredTeams.take(_pageSize).toList();
    }
    final isLoading = listState.isLoading;
    final showError = listState.errorMessage != null;
    final showNoData = !isLoading && filteredTeams.isEmpty;

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
                    border: Border.all(color: colorScheme.surfaceContainerHighest),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Team",
                            style: AppFonts.roboto(
                              fontSize: fsSection,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final created = await context.push(AppRoutePaths.adminTeamsAdd);
                              if (created == true && mounted) {
                                _loadTeams();
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
                            hintText: "Search name, email, status...",
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
                                      value: "Inactive",
                                      child: Text('Inactive'),
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
                                    PopupMenuItem(
                                      value: 10,
                                      child: Text('10'),
                                    ),
                                    PopupMenuItem(
                                      value: 25,
                                      child: Text('25'),
                                    ),
                                    PopupMenuItem(
                                      value: 50,
                                      child: Text('50'),
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
                                  onTap: _loadTeams,
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
                                    showError
                                        ? (listState.errorMessage ?? "Couldn't load team members.")
                                        : "No team members found",
                                    style: AppFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (showError)
                                  TextButton(
                                    onPressed: _loadTeams,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (isLoading)
                        ...List<Widget>.generate(
                          3,
                          (index) => _buildTeamSkeletonCard(
                            padding: padding,
                            spacing: spacing,
                            cardPadding: cardPadding,
                            screenWidth: screenWidth,
                            bodyFs: fsMain,
                            smallFs: fsMeta,
                          ),
                        ),
                      if (!showNoData && !isLoading)
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTeams.length,
                          itemBuilder: (context, index) {
                            final team = filteredTeams[index];
                            return _buildTeamCard(
                              team,
                              colorScheme,
                              padding,
                              spacing,
                              fsMain,
                              fsSecondary,
                              fsMeta,
                              iconSize,
                              cardPadding,
                              screenWidth,
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
              title: 'Team',
              leadingIcon: Icons.groups,
              onClose: () => context.go(AppRoutePaths.adminHome),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSkeletonCard({
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

  Widget _buildTeamCard(
    AdminTeamListItem team,
    ColorScheme colorScheme,
    double padding,
    double spacing,
    double fsMain,
    double fsSecondary,
    double fsMeta,
    double iconSize,
    double cardPadding,
    double screenWidth,
  ) {
    final name = _safe(team.fullName);
    final email = _safe(team.email);
    final phone = _safe(team.fullPhone);
    final username = _safe(team.username);
    final joined = _formatDateOnly(team.joinedAt);
    final initials = team.initials;
    final teamId = team.id.trim();
    final isUpdating = ref.watch(adminTeamListControllerProvider.select((s) => s.updatingIds.contains(teamId))); 

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
          onTap: teamId.isEmpty
              ? null
              : () => context.push(AppRoutePaths.adminTeamsDetails(teamId)),
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
                                  name,
                                  style: AppFonts.roboto(
                                    fontSize: fsMain,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: team.isActive,
                                  onChanged: isUpdating
                                      ? null
                                      : (v) => _toggleTeamActive(team, v),
                                  activeThumbColor: colorScheme.onPrimary,
                                  activeTrackColor: colorScheme.primary,
                                  inactiveThumbColor: colorScheme.onPrimary,
                                  inactiveTrackColor:
                                      colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                            ],
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
                                  style: AppFonts.roboto(
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
                SizedBox(height: spacing * 1.5),
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
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: teamId.isEmpty
                      ? null
                      : () => context.push(AppRoutePaths.adminTeamsDetails(teamId)),
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
                          "View",
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


