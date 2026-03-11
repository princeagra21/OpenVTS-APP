import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/user_share_track_link_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_share_track_links_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
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
      success: (updated) {
        final index = _tracks.indexWhere((element) => element.id == item.id);
        if (index < 0) return;
        setState(() {
          _tracks[index] = updated;
          _togglingIds.remove(item.id);
        });
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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth);
    final bodyFs = titleFs - 1;
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4;
    final searchQuery = _searchController.text.toLowerCase().trim();

    final filteredTracks =
        _tracks.where((track) {
          final matchesSearch =
              searchQuery.isEmpty ||
              track.displayName.toLowerCase().contains(searchQuery) ||
              track.statusLabel.toLowerCase().contains(searchQuery) ||
              track.finalUrl.toLowerCase().contains(searchQuery) ||
              _vehiclesDisplay(track).toLowerCase().contains(searchQuery);

          final matchesTab =
              selectedTab == 'All' ||
              (selectedTab == 'Active' && track.statusLabel == 'Active') ||
              (selectedTab == 'Expires Today' && _isExpiringToday(track));

          return matchesSearch && matchesTab;
        }).toList()..sort((a, b) {
          final ad = a.expiryDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.expiryDate ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

    return AppLayout(
      title: 'USER',
      subtitle: 'Share Track',
      showLeftAvatar: false,
      actionIcons: const [],
      onActionTaps: const [],
      leftAvatarText: 'ST',
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
                  hintText: 'Search name, link, status...',
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
              children: ['All', 'Active', 'Expires Today'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: padding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredTracks.length} of ${_tracks.length} tracks',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await context.push('/user/share-track/add');
                    if (result == true) {
                      _loadLinks();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      'Add Track',
                      style: GoogleFonts.inter(
                        fontSize: bodyFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            if (_loading)
              ...List.generate(
                3,
                (_) => _buildShimmerCard(
                  context,
                  colorScheme,
                  padding,
                  spacing,
                  bodyFs,
                ),
              )
            else if (filteredTracks.isEmpty)
              _buildEmptyCard(
                context,
                colorScheme,
                padding,
                bodyFs,
                'No track links found',
                'Create a link to share live tracking.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTracks.length,
                itemBuilder: (context, index) {
                  final track = filteredTracks[index];
                  final vehiclesDisplay = _vehiclesDisplay(track);
                  final statusColor = _statusColor(colorScheme, track);
                  final isBusy =
                      _togglingIds.contains(track.id) ||
                      _deletingIds.contains(track.id);

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
                        onTap: track.finalUrl.trim().isEmpty
                            ? null
                            : () => _openLink(track.finalUrl),
                        borderRadius: BorderRadius.circular(25),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      track.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing + 2,
                                      vertical: spacing - 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      track.statusLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: smallFs,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing),
                              GestureDetector(
                                onTap: track.finalUrl.trim().isEmpty
                                    ? null
                                    : () => _openLink(track.finalUrl),
                                child: Text(
                                  '${track.vehiclesCount} vehicles • ${track.finalUrl}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs,
                                    color: colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing / 2),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.calendar,
                                        size: iconSize * 0.8,
                                        color: colorScheme.primary.withOpacity(
                                          0.87,
                                        ),
                                      ),
                                      SizedBox(width: spacing / 2),
                                      Text(
                                        'Expires: ${_formatDate(track.expiryDate)}',
                                        style: GoogleFonts.inter(
                                          fontSize: bodyFs,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: spacing + 5),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: iconSize * 0.8,
                                        color: colorScheme.primary.withOpacity(
                                          0.87,
                                        ),
                                      ),
                                      SizedBox(width: spacing / 2),
                                      Text(
                                        'Views: ${track.views}',
                                        style: GoogleFonts.inter(
                                          fontSize: bodyFs,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (track.lastOpenedDate != null) ...[
                                SizedBox(height: spacing / 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: iconSize * 0.8,
                                      color: colorScheme.primary.withOpacity(
                                        0.87,
                                      ),
                                    ),
                                    SizedBox(width: spacing / 2),
                                    Expanded(
                                      child: Text(
                                        'Last opened: ${_formatDate(track.lastOpenedDate)}',
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
                              SizedBox(height: spacing),
                              if (vehiclesDisplay.isNotEmpty)
                                Text(
                                  vehiclesDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              SizedBox(height: spacing * 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    tooltip: 'Copy Link',
                                    icon: Icon(
                                      Icons.content_copy,
                                      size: iconSize,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: isBusy
                                        ? null
                                        : () => _copyLink(track),
                                  ),
                                  IconButton(
                                    tooltip: 'QR Code',
                                    icon: Icon(
                                      Icons.qr_code,
                                      size: iconSize,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: isBusy
                                        ? null
                                        : _showUnavailableQr,
                                  ),
                                  _togglingIds.contains(track.id)
                                      ? AppShimmer(
                                          width: iconSize,
                                          height: iconSize,
                                          radius: iconSize / 2,
                                        )
                                      : IconButton(
                                          tooltip: track.isActive
                                              ? 'Pause'
                                              : 'Resume',
                                          icon: Icon(
                                            track.isActive
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                            size: iconSize,
                                            color: colorScheme.primary,
                                          ),
                                          onPressed: isBusy
                                              ? null
                                              : () => _toggleLink(track),
                                        ),
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: Icon(
                                      Icons.edit,
                                      size: iconSize,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: isBusy
                                        ? null
                                        : _showUnavailableEdit,
                                  ),
                                  _deletingIds.contains(track.id)
                                      ? AppShimmer(
                                          width: iconSize,
                                          height: iconSize,
                                          radius: iconSize / 2,
                                        )
                                      : IconButton(
                                          tooltip: 'Delete',
                                          icon: Icon(
                                            Icons.delete,
                                            size: iconSize,
                                            color: Colors.red,
                                          ),
                                          onPressed: isBusy
                                              ? null
                                              : () => _deleteLink(track),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            SizedBox(height: padding * 2),
          ],
        ),
      ),
    );
  }
}
