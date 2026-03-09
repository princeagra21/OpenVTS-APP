import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/admin_transactions_summary.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_transactions_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/transactions (query: search, status, page, limit, from, to)
  //   Response keys used: data.data.items | data.items | items
  // - GET /admin/transactions/analytics
  //   Response keys used: data.data (totalTransactions, totalsByCurrency, statusBreakdown)

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();

  late final List<String> _tabs;
  late final List<GlobalKey> _tabKeys;

  List<AdminTransactionItem>? _items;
  AdminTransactionsSummary? _summary;
  double? _derivedProcessed30DaysAmount;

  bool _loading = false;
  bool _errorShown = false;
  bool _detailsApiUnavailableShown = false;
  bool _receiptApiUnavailableShown = false;

  CancelToken? _loadToken;
  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminTransactionsRepository? _repo;

  AdminTransactionsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminTransactionsRepository(api: _apiClient!);
    return _repo!;
  }

  void _showDebugUnavailableOnce({
    required String message,
    required bool alreadyShown,
    required void Function() markShown,
  }) {
    if (!kDebugMode || alreadyShown || !mounted) return;
    markShown();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _tabs = ['All', 'Success', 'Pending', 'Failed', 'Refunded'];
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());

    _searchController.addListener(_onSearchChanged);
    _loadTransactions();
  }

  @override
  void dispose() {
    _loadToken?.cancel('TransactionScreen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadTransactions();
    });
  }

  String? _statusQueryForTab(String tab) {
    final normalized = AdminTransactionItem.normalizeStatus(tab);
    if (normalized.isEmpty || normalized == 'all') return null;
    return normalized;
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

  Future<void> _loadTransactions() async {
    _loadToken?.cancel('Reload transactions');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final repo = _repoOrCreate();

      final listRes = await repo.getTransactions(
        search: _searchController.text.trim(),
        status: _statusQueryForTab(selectedTab),
        page: 1,
        limit: 100,
        cancelToken: token,
      );

      final summaryRes = await repo.getTransactionsSummary(cancelToken: token);

      if (!mounted) return;

      List<AdminTransactionItem> items = const <AdminTransactionItem>[];
      AdminTransactionsSummary? summary;
      Object? firstError;

      listRes.when(
        success: (data) {
          items = data;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      summaryRes.when(
        success: (data) {
          summary = data;
        },
        failure: (err) {
          firstError ??= err;
        },
      );

      final derived = _computeProcessed30DaysAmount(items);

      setState(() {
        _items = items;
        _summary = summary;
        _derivedProcessed30DaysAmount = derived;
        _loading = false;
        if (firstError == null) {
          _errorShown = false;
        }
      });

      if (firstError != null && !_isCancelled(firstError!)) {
        _showLoadErrorOnce("Couldn't load transactions.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const <AdminTransactionItem>[];
        _summary = null;
        _derivedProcessed30DaysAmount = null;
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load transactions.");
    }
  }

  double? _computeProcessed30DaysAmount(List<AdminTransactionItem> items) {
    if (items.isEmpty) return 0;

    final now = DateTime.now();
    var sum = 0.0;
    var found = false;

    for (final t in items) {
      if (t.normalizedStatus != 'success') continue;
      final amount = t.amount;
      if (amount == null) continue;

      final date = _tryParseDate(t.createdAt);
      if (date == null) continue;

      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff <= 30) {
        sum += amount;
        found = true;
      }
    }

    return found ? sum : 0;
  }

  List<AdminTransactionItem> _applyLocalFilters(
    List<AdminTransactionItem> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminTransactionItem item) {
      if (selectedTab == 'All') return true;
      final expected = AdminTransactionItem.normalizeStatus(selectedTab);
      final actual = item.normalizedStatus;
      return expected == actual;
    }

    bool queryMatch(AdminTransactionItem item) {
      if (query.isEmpty) return true;

      final fields = [
        item.invoiceNumber,
        item.reference,
        item.description,
        item.method,
        item.statusLabel,
        item.createdAt,
      ];

      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((item) => tabMatch(item) && queryMatch(item)).toList()
      ..sort((a, b) {
        final db =
            _tryParseDate(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final da =
            _tryParseDate(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
  }

  DateTime? _tryParseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso;

    final datePart = value.split(',').first.trim();
    final slash = datePart.split('/');
    if (slash.length == 3) {
      final d = int.tryParse(slash[0]);
      final m = int.tryParse(slash[1]);
      final y = int.tryParse(slash[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }

    return null;
  }

  String _displayDate(String raw) {
    final date = _tryParseDate(raw);
    if (date == null) return '—';

    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');

    return '$dd/$mm/$yyyy, $hh:$min:$ss';
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }

  String _formatCurrency(num value, {String currency = 'INR'}) {
    final symbol = currency.toUpperCase() == 'INR' ? '₹' : '$currency ';
    final sign = value < 0 ? '-' : '';
    final absValue = value.abs();

    final fixed = absValue.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final fracPart = parts[1];

    final withCommas = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );

    return '$sign$symbol$withCommas.$fracPart';
  }

  String _formatCredits(int? value) {
    if (value == null) return '—';
    if (value > 0) return '+$value';
    return value.toString();
  }

  Color _statusColor(String normalized) {
    if (normalized == 'success') return Colors.green;
    if (normalized == 'pending') return Colors.orange;
    if (normalized == 'failed' || normalized == 'refunded') return Colors.red;
    return Colors.grey;
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

    final allItems = _items ?? const <AdminTransactionItem>[];
    final filteredTransactions = _applyLocalFilters(allItems);

    final availableCredits = _summary?.availableCredits;

    final processedAmount =
        _summary?.processed30DaysAmount ??
        _summary?.amountFromTotalsByCurrency ??
        _derivedProcessed30DaysAmount;

    final availableCreditsText = availableCredits != null
        ? availableCredits.toString()
        : '—';
    final processedText = processedAmount != null
        ? _formatCurrency(
            processedAmount,
            currency: _summary?.currency ?? 'INR',
          )
        : '—';

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Transactions',
      actionIcons: const [],
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
                  hintText: 'Search invoice, description, method...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.onSurface.withOpacity(0.7),
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

            Container(
              padding: EdgeInsets.symmetric(vertical: hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBox(
                    'Available Credits',
                    availableCreditsText,
                    '',
                    bodyFs,
                    smallFs,
                    colorScheme,
                    spacing,
                    loading: _loading,
                  ),
                  _statBox(
                    'Processed (30 days)',
                    processedText,
                    '',
                    bodyFs,
                    smallFs,
                    colorScheme,
                    spacing,
                    loading: _loading,
                  ),
                ],
              ),
            ),
            SizedBox(height: hp),

            SizedBox(
              height: hp * 3,
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
                                if (selectedTab == tab) return;

                                setState(() => selectedTab = tab);
                                _loadTransactions();

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  final ctx = _tabKeys[index].currentContext;
                                  if (ctx != null) {
                                    Scrollable.ensureVisible(
                                      ctx,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
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

            SizedBox(height: hp),

            Text(
              'Showing ${filteredTransactions.length} of ${allItems.length} transactions',
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            SizedBox(height: spacing * 1.5),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _loading
                  ? 3
                  : (filteredTransactions.isEmpty
                        ? 1
                        : filteredTransactions.length),
              itemBuilder: (context, index) {
                if (_loading) {
                  return _buildShimmerCard(
                    colorScheme,
                    width,
                    hp,
                    spacing,
                    cardPadding,
                  );
                }

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyStateCard(
                    colorScheme: colorScheme,
                    hp: hp,
                    bodyFs: bodyFs,
                    smallFs: smallFs,
                    cardPadding: cardPadding,
                  );
                }

                return _buildTransactionCard(
                  tran: filteredTransactions[index],
                  colorScheme: colorScheme,
                  width: width,
                  hp: hp,
                  spacing: spacing,
                  bodyFs: bodyFs,
                  smallFs: smallFs,
                  iconSize: iconSize,
                  cardPadding: cardPadding,
                );
              },
            ),

            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
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
        child: Row(
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
                      AppShimmer(width: 130, height: 12, radius: 6),
                      Spacer(),
                      AppShimmer(width: 88, height: 22, radius: 11),
                    ],
                  ),
                  SizedBox(height: 8),
                  AppShimmer(width: 210, height: 16, radius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 140, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 220, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 110, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 190, height: 14, radius: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required ColorScheme colorScheme,
    required double hp,
    required double bodyFs,
    required double smallFs,
    required double cardPadding,
  }) {
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
            Text(
              'No transactions found',
              style: GoogleFonts.inter(
                fontSize: bodyFs + 1,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting search.',
              style: GoogleFonts.inter(
                fontSize: smallFs + 1,
                color: colorScheme.onSurface.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required AdminTransactionItem? tran,
    required ColorScheme colorScheme,
    required double width,
    required double hp,
    required double spacing,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
  }) {
    final isPlaceholder = tran == null;

    final date = _safe(_displayDate(tran?.createdAt ?? ''));
    final statusLabel = _safe(tran?.statusLabel ?? '');
    final normalizedStatus = tran?.normalizedStatus ?? '';
    final statusColor = _statusColor(normalizedStatus);

    final invoice = _safe(tran?.invoiceNumber ?? '');
    final fsId = _safe(tran?.reference ?? '');
    final description = _safe(tran?.description ?? '');
    final method = _safe(tran?.method ?? '');
    final credits = _formatCredits(tran?.credits);
    final amount = tran?.amount != null
        ? _formatCurrency(tran!.amount!, currency: tran.currency)
        : '—';

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
                          color: colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.money_dollar_circle,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  date,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: smallFs,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
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
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: smallFs,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Text(
                            invoice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: bodyFs + 2,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fsId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.doc_on_clipboard,
                                  size: iconSize - 4,
                                  color: colorScheme.primary,
                                ),
                                onPressed: isPlaceholder || fsId == '—'
                                    ? null
                                    : () {
                                        Clipboard.setData(
                                          ClipboardData(text: fsId),
                                        );
                                      },
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: bodyFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: spacing / 2),
                          Text(
                            method,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: bodyFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Credits: $credits',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs - 1,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  'Amount: $amount',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: bodyFs - 1,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                      onSelected: (String value) {
                        if (isPlaceholder) return;

                        if (value == 'details') {
                          _showDebugUnavailableOnce(
                            message: 'Details API not available yet',
                            alreadyShown: _detailsApiUnavailableShown,
                            markShown: () => _detailsApiUnavailableShown = true,
                          );

                          final id = tran.id.trim();
                          if (id.isNotEmpty) {
                            context.push(
                              '/admin/transactions/details/$id',
                              extra: tran.raw,
                            );
                          }
                        } else if (value == 'receipt') {
                          _showDebugUnavailableOnce(
                            message: 'Receipt API not available yet',
                            alreadyShown: _receiptApiUnavailableShown,
                            markShown: () => _receiptApiUnavailableShown = true,
                          );
                        } else if (value == 'copy') {
                          if (fsId != '—') {
                            Clipboard.setData(ClipboardData(text: fsId));
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'details',
                              child: ListTile(
                                leading: Icon(
                                  Icons.visibility,
                                  color: colorScheme.primary,
                                ),
                                title: const Text('View details'),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'receipt',
                              child: ListTile(
                                leading: Icon(
                                  Icons.receipt,
                                  color: colorScheme.primary,
                                ),
                                title: const Text('Receipt'),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'copy',
                              child: ListTile(
                                leading: Icon(
                                  Icons.content_copy,
                                  color: colorScheme.primary,
                                ),
                                title: const Text('Copy reference'),
                              ),
                            ),
                          ],
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

  Widget _statBox(
    String title,
    String value,
    String subtitle,
    double bodyFs,
    double smallFs,
    ColorScheme colorScheme,
    double spacing, {
    required bool loading,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: Column(
          children: [
            loading
                ? const AppShimmer(width: 120, height: 12, radius: 6)
                : Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: smallFs,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
            const SizedBox(height: 6),
            loading
                ? const AppShimmer(width: 110, height: 16, radius: 8)
                : Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: bodyFs,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: smallFs - 1,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
