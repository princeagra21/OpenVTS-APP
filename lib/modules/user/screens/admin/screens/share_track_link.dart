import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_share_track_link_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_share_track_links_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareTrackScreen extends StatefulWidget {
  const ShareTrackScreen({super.key});

  @override
  State<ShareTrackScreen> createState() => _ShareTrackScreenState();
}

class _ShareTrackScreenState extends State<ShareTrackScreen> {
  // FleetStack-API-Reference.md confirmed:
  // - GET    /user/sharetracklinks
  // - POST   /user/sharetracklinks
  // - GET    /user/sharetracklinks/:id
  // - PATCH  /user/sharetracklinks/:id
  // - DELETE /user/sharetracklinks/:id
  //
  // Postman mismatch:
  // - Create body shows single-vehicle shape: { vehicleId, expiresAt }
  // - MD shows array shape: { vehicleIds, expiryAt, isGeofence, isHistory }
  // The repository prefers MD and falls back to Postman shape when needed.
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 10;
  final Map<String, CancelToken> _toggleTokens = <String, CancelToken>{};
  final Map<String, CancelToken> _deleteTokens = <String, CancelToken>{};

  ApiClient? _apiClient;
  UserShareTrackLinksRepository? _repo;
  CancelToken? _loadToken;

  List<UserShareTrackLinkItem> _tracks = <UserShareTrackLinkItem>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _editUnavailableShown = false;
  bool _qrUnavailableShown = false;
  final Set<String> _togglingIds = <String>{};
  final Set<String> _deletingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadLinks();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Share track screen disposed');
    for (final token in _toggleTokens.values) {
      token.cancel('Share track screen disposed');
    }
    for (final token in _deleteTokens.values) {
      token.cancel('Share track screen disposed');
    }
    _searchController.dispose();
    super.dispose();
  }

  UserShareTrackLinksRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserShareTrackLinksRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadLinks() async {
    _loadToken?.cancel('Reload share track links');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getLinks(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (items) {
        setState(() {
          _tracks = items;
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
            : "Couldn't load share links.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  bool _isExpiringToday(UserShareTrackLinkItem item) {
    final expiry = item.expiryDate;
    if (expiry == null) return false;
    final now = DateTime.now();
    return expiry.year == now.year &&
        expiry.month == now.month &&
        expiry.day == now.day;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}, ${two(value.hour)}:${two(value.minute)}';
  }

  Color _statusColor(ColorScheme cs, UserShareTrackLinkItem item) {
    switch (item.statusLabel.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _vehiclesDisplay(UserShareTrackLinkItem item) {
    final labels = item.vehicles
        .map(
          (vehicle) =>
              (vehicle['plateNumber'] ??
                      vehicle['plate_number'] ??
                      vehicle['name'] ??
                      '')
                  .toString()
                  .trim(),
        )
        .where((value) => value.isNotEmpty)
        .toList();
    if (labels.length > 3) {
      return '${labels.take(3).join(' ')} +${labels.length - 3} more';
    }
    return labels.join(' ');
  }

  Future<void> _openLink(String rawUrl) async {
    final value = rawUrl.trim();
    if (value.isEmpty) return;
    final normalized =
        value.startsWith('http://') || value.startsWith('https://')
        ? value
        : 'https://$value';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _copyLink(UserShareTrackLinkItem item) {
    final value = item.finalUrl.trim();
    if (value.isEmpty) return;
    final normalized =
        value.startsWith('http://') || value.startsWith('https://')
        ? value
        : 'https://$value';
    Clipboard.setData(ClipboardData(text: normalized));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _showUnavailableQr() {
    if (_qrUnavailableShown) return;
    _qrUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Code UI not available yet')),
    );
  }

  void _showUnavailableEdit() {
    if (_editUnavailableShown) return;
    _editUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit API shape not confirmed yet')),
    );
  }

  Future<void> _toggleLink(UserShareTrackLinkItem item) async {
    if (_togglingIds.contains(item.id) || _deletingIds.contains(item.id)) {
      return;
    }

    final next = !item.isActive;
    final previousIndex = _tracks.indexWhere(
      (element) => element.id == item.id,
    );
    if (previousIndex < 0) return;

    final token = CancelToken();
    _toggleTokens[item.id]?.cancel('Restart share link toggle');
    _toggleTokens[item.id] = token;

    final optimisticRaw = Map<String, dynamic>.from(item.raw)
      ..['isActive'] = next;

    if (!mounted) return;
    setState(() {
      _togglingIds.add(item.id);
      _tracks[previousIndex] = item.copyWithRaw(optimisticRaw);
    });

    final result = await _repoOrCreate().setLinkActive(
      item.id,
      next,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() {
          _togglingIds.remove(item.id);
        });
        _loadLinks();
      },
      failure: (error) {
        final index = _tracks.indexWhere((element) => element.id == item.id);
        if (index < 0) return;
        setState(() {
          _tracks[index] = item;
          _togglingIds.remove(item.id);
        });
        if (_isCancelled(error)) return;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't update link status.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _deleteLink(UserShareTrackLinkItem item) async {
    if (_deletingIds.contains(item.id) || _togglingIds.contains(item.id)) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete share link?'),
            content: Text('This will revoke "${item.displayName}".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    final token = CancelToken();
    _deleteTokens[item.id]?.cancel('Restart share link delete');
    _deleteTokens[item.id] = token;

    if (!mounted) return;
    setState(() => _deletingIds.add(item.id));

    final result = await _repoOrCreate().deleteLink(
      item.id,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() {
          _deletingIds.remove(item.id);
          _tracks.removeWhere((element) => element.id == item.id);
        });
      },
      failure: (error) {
        setState(() => _deletingIds.remove(item.id));
        if (_isCancelled(error)) return;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't delete share link.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Widget _buildShimmerCard(
    BuildContext context,
    ColorScheme colorScheme,
    double padding,
    double spacing,
    double bodyFs,
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
          padding: EdgeInsets.all(padding + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    child: AppShimmer(
                      width: double.infinity,
                      height: 16,
                      radius: 8,
                    ),
                  ),
                  SizedBox(width: 12),
                  AppShimmer(width: 72, height: 24, radius: 12),
                ],
              ),
              SizedBox(height: spacing),
              const AppShimmer(width: 220, height: 14, radius: 8),
              SizedBox(height: spacing / 2),
              Row(
                children: const [
                  AppShimmer(width: 140, height: 14, radius: 8),
                  SizedBox(width: 12),
                  AppShimmer(width: 90, height: 14, radius: 8),
                ],
              ),
              SizedBox(height: spacing / 2),
              const AppShimmer(width: 180, height: 14, radius: 8),
              SizedBox(height: spacing),
              const AppShimmer(width: 240, height: 14, radius: 8),
              SizedBox(height: spacing * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (_) => AppShimmer(
                    width: bodyFs + 10,
                    height: bodyFs + 10,
                    radius: (bodyFs + 10) / 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context,
    ColorScheme colorScheme,
    double padding,
    double bodyFs,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: padding),
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
        padding: EdgeInsets.all(padding + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: bodyFs - 1,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final scale = (screenWidth / 390).clamp(0.9, 1.05);
    final fsSection = 18 * scale;
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final iconSize = 18.0;
    final cardPadding = padding + 4;

    var filteredTracks = _tracks.where((track) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          track.displayName.toLowerCase().contains(query) ||
          track.finalUrl.toLowerCase().contains(query) ||
          track.statusLabel.toLowerCase().contains(query);

      final matchesTab =
          selectedTab == 'All' ||
          (selectedTab == 'Active' && track.statusLabel == 'Active') ||
          (selectedTab == 'Expires Today' && _isExpiringToday(track));

      return matchesSearch && matchesTab;
    }).toList()
      ..sort((a, b) {
        final ad = a.expiryDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.expiryDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    if (filteredTracks.length > _pageSize) {
      filteredTracks = filteredTracks.take(_pageSize).toList();
    }

    final showNoData = !_loading && filteredTracks.isEmpty;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
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
                    border: Border.all(color: colorScheme.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Share Track",
                            style: GoogleFonts.roboto(
                              fontSize: fsSection,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final result =
                                  await context.push('/user/share-track/add');
                              if (result == true) {
                                _loadLinks();
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
                          style: GoogleFonts.roboto(
                            fontSize: fsMain,
                            height: 20 / 14,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search name, link, status...",
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
                                    setState(() => selectedTab = value);
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
                                      value: "Expires Today",
                                      child: Text('Expires Today'),
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: InkWell(
                                  onTap: _loadLinks,
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
                                    _errorShown
                                        ? "Couldn't load share links."
                                        : "No share links found",
                                    style: GoogleFonts.roboto(
                                      fontSize: fsSecondary,
                                      height: 16 / 12,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_errorShown)
                                  TextButton(
                                    onPressed: _loadLinks,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (_loading)
                        ...List<Widget>.generate(
                          3,
                          (index) => _buildTrackSkeletonCard(
                            padding: padding,
                            spacing: spacing,
                            cardPadding: cardPadding,
                            screenWidth: screenWidth,
                            bodyFs: fsMain,
                            smallFs: fsMeta,
                          ),
                        ),
                      if (!showNoData && !_loading)
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTracks.length,
                          itemBuilder: (context, index) {
                            final track = filteredTracks[index];
                            return _buildTrackCard(
                              track,
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
            child: UserHomeAppBar(
              title: 'Share Track',
              leadingIcon: Icons.share_outlined,
              onClose: () => context.go('/user/home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackSkeletonCard({
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
              SizedBox(height: spacing * 1.5),
              AppShimmer(
                width: double.infinity,
                height: bodyFs + 20,
                radius: 12,
              ),
              SizedBox(height: spacing),
              AppShimmer(
                width: double.infinity,
                height: bodyFs + 20,
                radius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(
    UserShareTrackLinkItem track,
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
    final name = _safe(track.displayName);
    final url = _safe(track.finalUrl);
    final vehicles = _safe(_vehiclesDisplay(track));
    final expiry = _safe(_formatDate(track.expiryDate));
    final initials = _initials(name);
    final isUpdating = _togglingIds.contains(track.id);

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
          onTap: url == '—' ? null : () => _openLink(track.finalUrl),
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
                                  name,
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
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: track.isActive,
                                  onChanged: isUpdating
                                      ? null
                                      : (_) => _toggleLink(track),
                                  activeColor: colorScheme.onPrimary,
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
                                Icons.link,
                                size: iconSize,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  url,
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
                              SizedBox(width: spacing),
                              InkWell(
                                onTap: url == '—'
                                    ? null
                                    : () => _copyLink(track),
                                borderRadius: BorderRadius.circular(999),
                                child: Icon(
                                  Icons.copy,
                                  size: iconSize,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: iconSize,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  vehicles,
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
                              "Expires",
                              style: GoogleFonts.roboto(
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
                        expiry,
                        style: GoogleFonts.roboto(
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
                Container(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    return trimmed;
  }

  String _initials(String name) {
    final clean = name.replaceAll('@', ' ').trim();
    if (clean.isEmpty) return '--';
    final parts =
        clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }
}
