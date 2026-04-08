import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/pricing_plan.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_pricing_plans_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  late final List<String> _tabs;
  late final List<GlobalKey> _tabKeys;

  final CancelToken _token = CancelToken();
  ApiClient? _apiClient;
  AdminPricingPlansRepository? _repo;

  bool _loading = false;
  bool _errorShown = false;
  List<PricingPlan> _plans = const <PricingPlan>[];

  AdminPricingPlansRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminPricingPlansRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _tabs = ['All', 'Active', 'Inactive'];
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
    _loadPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabScrollController.dispose();
    _token.cancel('PlansScreen disposed');
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  bool _isActive(PricingPlan plan) {
    final raw = plan.raw['isActive'] ??
        plan.raw['active'] ??
        plan.raw['enabled'] ??
        plan.status;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final s = raw.toString().toLowerCase().trim();
    if (s.isEmpty) return false;
    if (s == 'true' || s == 'active' || s == 'enabled') return true;
    return false;
  }

  String _priceText(PricingPlan plan) {
    final raw = plan.raw['price'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    final price = plan.price;
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toString();
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getPlans(cancelToken: _token);

    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _plans = items;
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (err) {
        setState(() {
          _plans = const <PricingPlan>[];
          _loading = false;
        });
        if (_isCancelled(err)) return;
        if (_errorShown) return;
        _errorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't load plans.";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsMain = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double fsMeta = 11 * scale;
    final double iconSize = 16 * scale;
    final double cardPadding = hp + 4;

    final searchQuery = _searchController.text.toLowerCase();

    bool matchesTab(PricingPlan plan) {
      if (selectedTab == 'All') return true;
      final active = _isActive(plan);
      if (selectedTab == 'Active') return active;
      if (selectedTab == 'Inactive') return !active;
      return true;
    }

    bool matchesSearch(PricingPlan plan) {
      if (searchQuery.isEmpty) return true;
      final fields = [
        plan.name,
        plan.currency,
        plan.durationDays.toString(),
        _priceText(plan),
      ];
      return fields.any((v) => v.toLowerCase().contains(searchQuery));
    }

    final filteredPlans = _plans
        .where((plan) => matchesTab(plan) && matchesSearch(plan))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Plans',
      showAppBar: false,
      customTopBar: AdminHomeAppBar(
        title: 'Plans',
        leadingIcon: Icons.widgets,
        onClose: () => context.go('/admin/home'),
      ),
      actionIcons: const [],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SUMMARY HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: hp * 0.9,
                vertical: hp * 0.7,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
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
                    'All Plans',
                    style: GoogleFonts.roboto(
                      fontSize: fsSection,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _plans.isEmpty
                        ? 'No plans registered.'
                        : '${_plans.length} plan(s) registered',
                    style: GoogleFonts.roboto(
                      fontSize: fsSecondary,
                      height: 16 / 12,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing * 1.5),

            // BROWSE PLANS
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colorScheme.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Browse Plans',
                        style: GoogleFonts.roboto(
                          fontSize: fsSection,
                          height: 24 / 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
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
                        hintText: 'Search plan name, price, duration...',
                        hintStyle: GoogleFonts.roboto(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontSize: fsSecondary,
                          height: 16 / 12,
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          size: iconSize,
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
                  SizedBox(height: spacing),
                  SizedBox(
                    height: hp * 2.8,
                    child: Scrollbar(
                      controller: _tabScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 1,
                      radius: const Radius.circular(8),
                      child: SingleChildScrollView(
                        controller: _tabScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: spacing),
                        child: Row(
                          children: List.generate(_tabs.length, (index) {
                            final tab = _tabs[index];
                            return Padding(
                              padding: EdgeInsets.only(right: spacing),
                              child: KeyedSubtree(
                                key: _tabKeys[index],
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: SmallTab(
                                    label: tab,
                                    selected: selectedTab == tab,
                                    onTap: () {
                                      setState(() => selectedTab = tab);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        final ctx =
                                            _tabKeys[index].currentContext;
                                        if (ctx != null) {
                                          Scrollable.ensureVisible(
                                            ctx,
                                            duration:
                                                const Duration(milliseconds: 300),
                                            alignment: 0.5,
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${filteredPlans.length} of ${_plans.length} plans',
                        style: GoogleFonts.roboto(
                          fontSize: fsSecondary,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final res = await context.push('/admin/plans/add');
                          if (res == true && mounted) {
                            _loadPlans();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: hp * 1.5,
                            vertical: spacing,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Add Plan',
                            style: GoogleFonts.roboto(
                              fontSize: fsMeta,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing * 1.5),
                  if (_loading)
                    ...List.generate(
                      2,
                      (_) => Container(
                        margin: EdgeInsets.only(bottom: hp),
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
                            AppShimmer(
                              width: AdaptiveUtils.getAvatarSize(width),
                              height: AdaptiveUtils.getAvatarSize(width),
                              radius: AdaptiveUtils.getAvatarSize(width) / 2,
                            ),
                            SizedBox(width: spacing * 1.5),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppShimmer(
                                    width: 180,
                                    height: 14,
                                    radius: 7,
                                  ),
                                  SizedBox(height: 8),
                                  AppShimmer(
                                    width: double.infinity,
                                    height: 13,
                                    radius: 7,
                                  ),
                                  SizedBox(height: 8),
                                  AppShimmer(
                                    width: 120,
                                    height: 13,
                                    radius: 7,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredPlans.isEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: hp),
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
                          Icon(
                            CupertinoIcons.doc_text,
                            size: AdaptiveUtils.getFsAvatarFontSize(width),
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Text(
                              'No plans found',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: fsSecondary,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredPlans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      final active = _isActive(plan);
                      final statusLabel = active ? 'Active' : 'Inactive';
                      final statusColor = active ? Colors.green : Colors.red;
                      final currency = plan.currency.isNotEmpty
                          ? plan.currency
                          : (plan.raw['currency']?.toString() ?? '');
                      final priceText = _priceText(plan);
                      final durationText = plan.durationDays > 0
                          ? '${plan.durationDays} days'
                          : '—';

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
                                    Container(
                                      width: 40 * (fsMain / 14),
                                      height: 40 * (fsMain / 14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? colorScheme.surfaceVariant
                                            : Colors.grey.shade50,
                                        border: Border.all(
                                          color:
                                              colorScheme.outline.withOpacity(0.3),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        CupertinoIcons.doc_text,
                                        size: 18 * (fsMain / 14),
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: spacing * 1.5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  plan.name.isNotEmpty
                                                      ? plan.name
                                                      : 'Plan',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: fsMain,
                                                    height: 20 / 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  CupertinoIcons.ellipsis_vertical,
                                                  color: colorScheme.primary
                                                      .withOpacity(0.6),
                                                ),
                                                onSelected:
                                                    (String value) async {
                                                  if (value == 'edit') {
                                                    final res = await context.push(
                                                      '/admin/plans/edit/${plan.id}',
                                                      extra: plan.raw,
                                                    );
                                                    if (res == true &&
                                                        mounted) {
                                                      _loadPlans();
                                                    }
                                                  }
                                                },
                                                itemBuilder:
                                                    (BuildContext context) =>
                                                        <PopupMenuEntry<String>>[
                                                  const PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: ListTile(
                                                      leading:
                                                          Icon(Icons.edit_outlined),
                                                      title: Text('Edit'),
                                                    ),
                                                  ),
                                                ],
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
                                                  ? statusColor.withOpacity(0.15)
                                                  : Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: GoogleFonts.roboto(
                                                fontSize: fsMeta,
                                                height: 14 / 11,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? statusColor
                                                    : colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: false,
                                            ),
                                          ),
                                          SizedBox(height: spacing * 0.4),
                                          Text(
                                            'Price: ${currency.isNotEmpty ? '$currency ' : ''}$priceText',
                                            style: GoogleFonts.roboto(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          SizedBox(height: spacing * 0.4),
                                          Text(
                                            'Duration: $durationText',
                                            style: GoogleFonts.roboto(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
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
                    }).toList(),
                ],
              ),
            ),
            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }
}
