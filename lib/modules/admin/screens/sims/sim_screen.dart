import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_sim_card_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_simcards_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SimScreen extends StatefulWidget {
  const SimScreen({super.key});

  @override
  State<SimScreen> createState() => _SimScreenState();
}

class _SimScreenState extends State<SimScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/simcards (query: search, status, page, limit)
  // - PATCH /admin/simcards/:id (toggle, key: isActive)
  // - POST /admin/simcards (add flow handled in AddSimScreen)

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AdminSimCardItem>? _items;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;
  final Map<String, bool> _updating = <String, bool>{};
  final Map<String, CancelToken> _toggleTokens = <String, CancelToken>{};

  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminSimCardsRepository? _repo;

  AdminSimCardsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminSimCardsRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSimCards();
  }

  @override
  void dispose() {
    _loadToken?.cancel('SimScreen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    for (final token in _toggleTokens.values) {
      token.cancel('SimScreen disposed');
    }
    _toggleTokens.clear();

    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadSimCards();
    });
  }

  String normalizeStatus(String? raw, {bool? isActive}) {
    return AdminSimCardItem.normalizeStatus(raw, isActive: isActive);
  }

  String? _statusQueryForTab(String tab) {
    switch (tab.toLowerCase()) {
      case 'active':
        return 'active';
      case 'inactive':
        return 'inactive';
      case 'suspended':
        return 'suspended';
      default:
        return null;
    }
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

  Future<void> _loadSimCards() async {
    _loadToken?.cancel('Reload sim cards');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getSimCards(
        search: _searchController.text.trim(),
        status: _statusQueryForTab(selectedTab),
        page: 1,
        limit: 100,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (items) {
          if (!mounted) return;
          setState(() {
            _items = items;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _items = const <AdminSimCardItem>[];
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load SIM cards.'
              : "Couldn't load SIM cards.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const <AdminSimCardItem>[];
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load SIM cards.");
    }
  }

  List<AdminSimCardItem> _applyLocalFilters(List<AdminSimCardItem> source) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminSimCardItem item) {
      if (selectedTab == 'All') return true;
      final expected = normalizeStatus(selectedTab);
      final actual = normalizeStatus(item.rawStatus, isActive: item.isActive);
      return expected == actual;
    }

    bool queryMatch(AdminSimCardItem item) {
      if (query.isEmpty) return true;

      final fields = [
        item.phoneNumber,
        item.provider,
        item.imei,
        item.iccid,
        item.statusLabel,
        item.expiryDate,
      ];

      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((s) => tabMatch(s) && queryMatch(s)).toList()..sort(
      (a, b) => _safeParseDateTime(
        b.expiryDate,
      ).compareTo(_safeParseDateTime(a.expiryDate)),
    );
  }

  DateTime _safeParseDateTime(String dateStr) {
    final text = dateStr.trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    final parts = text.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _safe(String? value, {String fallback = '—'}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return fallback;
    return trimmed;
  }

  Future<void> _openAddSimCard() async {
    final result = await context.push('/admin/sims/add');
    if (!mounted) return;
    if (result == true) {
      _loadSimCards();
    }
  }

  Future<void> _toggleSimActive(AdminSimCardItem item, bool nextValue) async {
    final simId = item.id.trim();
    if (simId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SIM ID is missing.')));
      return;
    }

    if (_updating[simId] == true) return;

    final previousValue = item.isActive;
    _setSimActiveOptimistic(simId, nextValue);

    if (mounted) {
      setState(() {
        _updating[simId] = true;
      });
    }

    _toggleTokens[simId]?.cancel('Replace sim status request');
    final token = CancelToken();
    _toggleTokens[simId] = token;

    try {
      final result = await _repoOrCreate().updateSimCardStatus(
        simId,
        <String, dynamic>{'isActive': nextValue},
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _updating.remove(simId);
            _toggleTokens.remove(simId);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _setSimActiveOptimistic(simId, previousValue);
            _updating.remove(simId);
            _toggleTokens.remove(simId);
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update SIM status.'
              : "Couldn't update SIM status.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setSimActiveOptimistic(simId, previousValue);
        _updating.remove(simId);
        _toggleTokens.remove(simId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update SIM status.")),
      );
    }
  }

  void _setSimActiveOptimistic(String simId, bool isActive) {
    final list = _items;
    if (list == null) return;

    final updated = list.map((item) {
      if (item.id != simId) return item;

      final raw = Map<String, dynamic>.from(item.raw);
      raw['isActive'] = isActive;
      raw['active'] = isActive;
      raw['enabled'] = isActive;
      raw['status'] = isActive ? 'Active' : 'Inactive';
      return AdminSimCardItem.fromRaw(raw);
    }).toList();

    _items = updated;
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active')) return Colors.green.withOpacity(0.15);
    if (s.contains('suspend')) return Colors.orange.withOpacity(0.15);
    return Colors.red.withOpacity(0.15);
  }

  Color _statusTextColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('active')) return Colors.green;
    if (s.contains('suspend')) return Colors.orange;
    return Colors.red;
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

    final allItems = _items ?? const <AdminSimCardItem>[];
    final filteredSims = _applyLocalFilters(allItems);

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'SIM Cards Management',
      actionIcons: const [CupertinoIcons.add],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search phone, provider, IMEI, ICCID...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.primary.withOpacity(0.7),
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
              children: ['All', 'Active', 'Inactive', 'Suspended'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () {
                    if (selectedTab == tab) return;
                    setState(() => selectedTab = tab);
                    _loadSimCards();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: hp),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredSims.length} of ${allItems.length} SIM cards',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                GestureDetector(
                  onTap: _openAddSimCard,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hp * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary, width: 1),
                    ),
                    child: Text(
                      'Add SIM Card',
                      style: GoogleFonts.inter(
                        fontSize: bodyFs - 3,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),

            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loading
                  ? 3
                  : (filteredSims.isEmpty ? 1 : filteredSims.length),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _buildShimmerCard(
                    colorScheme,
                    width,
                    hp,
                    spacing,
                    bodyFs,
                    iconSize,
                    cardPadding,
                  );
                }

                if (filteredSims.isEmpty) {
                  return _buildEmptyStateCard(
                    colorScheme: colorScheme,
                    bodyFs: bodyFs,
                    smallFs: smallFs,
                    cardPadding: cardPadding,
                    hp: hp,
                  );
                }

                return _buildSimCardBody(
                  sim: filteredSims[index],
                  colorScheme: colorScheme,
                  width: width,
                  spacing: spacing,
                  bodyFs: bodyFs,
                  smallFs: smallFs,
                  iconSize: iconSize,
                  cardPadding: cardPadding,
                  hp: hp,
                );
              },
            ),

            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required ColorScheme colorScheme,
    required double bodyFs,
    required double smallFs,
    required double cardPadding,
    required double hp,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
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
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No SIM cards found',
                  style: GoogleFonts.inter(
                    fontSize: bodyFs + 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a SIM card or ask superadmin to assign one.',
                  style: GoogleFonts.inter(
                    fontSize: smallFs + 1,
                    color: colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
    double bodyFs,
    double iconSize,
    double cardPadding,
  ) {
    final avatarSize = AdaptiveUtils.getAvatarSize(width);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(
                  width: avatarSize,
                  height: avatarSize,
                  radius: avatarSize / 2,
                ),
                SizedBox(width: spacing * 1.5),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppShimmer(
                              width: 140,
                              height: 16,
                              radius: 8,
                            ),
                          ),
                          SizedBox(width: 8),
                          AppShimmer(width: 92, height: 22, radius: 11),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(width: 120, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 220, height: 14, radius: 7),
                      SizedBox(height: 8),
                      AppShimmer(width: 220, height: 14, radius: 7),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                AppShimmer(width: 140, height: 12, radius: 6),
                AppShimmer(width: 42, height: 22, radius: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimCardBody({
    required AdminSimCardItem? sim,
    required ColorScheme colorScheme,
    required double width,
    required double spacing,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
    required double hp,
  }) {
    final isPlaceholder = sim == null;
    final simId = sim?.id.trim() ?? '';
    final isUpdating = _updating[simId] == true;

    final phone = _safe(sim?.phoneNumber);
    final provider = _safe(sim?.provider);
    final imei = _safe(sim?.imei);
    final iccid = _safe(sim?.iccid);
    final status = _safe(sim?.statusLabel);
    final expiry = _safe(sim?.expiryDate);
    final enabled = sim?.isActive ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AdaptiveUtils.getAvatarSize(width),
                        height: AdaptiveUtils.getAvatarSize(width),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.sim_card,
                          size: AdaptiveUtils.getFsAvatarFontSize(width),
                          color: colorScheme.primary,
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
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs + 2,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(status),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: _statusTextColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.globe,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    provider,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
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
                                  CupertinoIcons.device_laptop,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    'IMEI: $imei',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
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
                                  CupertinoIcons.tag,
                                  size: iconSize,
                                  color: colorScheme.primary.withOpacity(0.6),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    'ICCID: $iccid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.w500,
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
                  SizedBox(height: spacing * 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Expiry: $expiry',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: smallFs + 1,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: IgnorePointer(
                          ignoring: isPlaceholder || isUpdating,
                          child: Switch(
                            value: enabled,
                            activeColor: colorScheme.onPrimary,
                            activeTrackColor: colorScheme.primary,
                            inactiveThumbColor: colorScheme.onSurfaceVariant,
                            inactiveTrackColor: colorScheme.surfaceVariant,
                            onChanged: isPlaceholder
                                ? null
                                : (v) => _toggleSimActive(sim, v),
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
      ),
    );
  }
}
