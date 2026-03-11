// screens/transactions/transaction_screen.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_transaction_item.dart';
import 'package:fleet_stack/core/models/user_transactions_page.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_transactions_repository.dart';
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

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // FleetStack-API-Reference.md confirmed:
  // - GET /user/transactions
  //
  // Query keys used:
  // - q
  // - status
  // - page
  // - limit
  //
  // No User transaction details/receipt endpoint is confirmed in MD/Postman.
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  late final List<String> _tabs;
  late final List<GlobalKey> _tabKeys;

  ApiClient? _apiClient;
  UserTransactionsRepository? _repo;
  CancelToken? _token;
  Timer? _debounce;

  UserTransactionsPage? _pageData;
  bool _loading = false;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _tabs = ["All", "Success", "Pending", "Failed", "Refunded"];
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
    _searchController.addListener(_scheduleReload);
    _loadTransactions();
  }

  @override
  void dispose() {
    _token?.cancel('User transactions disposed');
    _debounce?.cancel();
    _searchController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  UserTransactionsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserTransactionsRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _loadTransactions);
  }

  String _normalizeStatusTab(String tab) {
    final value = tab.trim().toLowerCase();
    if (value == 'all') return '';
    return value;
  }

  Future<void> _loadTransactions() async {
    _token?.cancel('Reload user transactions');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getTransactions(
      query: _searchController.text,
      status: _normalizeStatusTab(selectedTab),
      page: 1,
      limit: 100,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (page) {
        setState(() {
          _pageData = page;
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
            : "Couldn't load transactions.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Color _statusColor(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year}, '
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  }

  String _formatAmount(AdminTransactionItem item) {
    if (item.amount == null) return '—';
    final symbol = item.currency.toUpperCase() == 'INR'
        ? '₹'
        : '${item.currency} ';
    return '$symbol${_formatNumber(item.amount!)}';
  }

  String _formatCredits(AdminTransactionItem item) {
    if (item.credits == null) return '—';
    final value = item.credits!;
    if (value > 0) return '+$value';
    return value.toString();
  }

  int _availableCredits(List<AdminTransactionItem> items) {
    var total = 0;
    for (final item in items) {
      final credits = item.credits;
      if (credits == null) continue;
      if (item.normalizedStatus == 'success' ||
          item.normalizedStatus == 'refunded') {
        total += credits;
      }
    }
    return total;
  }

  double _processed30Days(List<AdminTransactionItem> items) {
    final now = DateTime.now();
    var total = 0.0;
    for (final item in items) {
      if (item.normalizedStatus != 'success') continue;
      final amount = item.amount;
      final parsedDate = DateTime.tryParse(item.createdAt);
      if (amount == null || parsedDate == null) continue;
      if (now.difference(parsedDate.toLocal()).inDays <= 30) {
        total += amount;
      }
    }
    return total;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatNumber(double value) {
    final negative = value < 0;
    final absolute = value.abs().toStringAsFixed(2);
    final parts = absolute.split('.');
    var whole = parts.first;
    final decimals = parts.last;

    if (whole.length > 3) {
      final lastThree = whole.substring(whole.length - 3);
      var prefix = whole.substring(0, whole.length - 3);
      final groups = <String>[];
      while (prefix.length > 2) {
        groups.insert(0, prefix.substring(prefix.length - 2));
        prefix = prefix.substring(0, prefix.length - 2);
      }
      if (prefix.isNotEmpty) {
        groups.insert(0, prefix);
      }
      whole = '${groups.join(',')},$lastThree';
    }

    return '${negative ? '-' : ''}$whole.$decimals';
  }

  Widget _buildShimmerStat(ColorScheme colorScheme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: const [
            AppShimmer(width: 110, height: 12, radius: 6),
            SizedBox(height: 8),
            AppShimmer(width: 70, height: 18, radius: 8),
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
    double iconSize,
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
                          height: 12,
                          radius: 6,
                        ),
                      ),
                      SizedBox(width: 12),
                      AppShimmer(width: 74, height: 24, radius: 12),
                    ],
                  ),
                  SizedBox(height: 10),
                  AppShimmer(width: 220, height: 18, radius: 8),
                  SizedBox(height: 10),
                  AppShimmer(width: 180, height: 14, radius: 7),
                  SizedBox(height: 10),
                  AppShimmer(width: double.infinity, height: 14, radius: 7),
                  SizedBox(height: 10),
                  AppShimmer(width: 120, height: 14, radius: 7),
                  SizedBox(height: 10),
                  AppShimmer(width: 170, height: 14, radius: 7),
                ],
              ),
            ),
            SizedBox(width: 12),
            AppShimmer(width: 28, height: 28, radius: 14),
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
              'No transactions found',
              style: GoogleFonts.inter(
                fontSize: bodyFs + 1,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions will appear here once payments are recorded.',
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

    final items = _pageData?.items ?? const <AdminTransactionItem>[];
    final totalTransactions = _pageData?.total ?? items.length;
    final availableCredits = _availableCredits(items);
    final processed30Days = _processed30Days(items);
    final processed30DaysLabel = '₹${_formatNumber(processed30Days)}';

    return AppLayout(
      title: "USER",
      subtitle: "Transactions",
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
                  hintText: "Search invoice, description, method...",
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
                children: _loading
                    ? [
                        _buildShimmerStat(colorScheme),
                        _buildShimmerStat(colorScheme),
                      ]
                    : [
                        _statBox(
                          "Available Credits",
                          availableCredits.toString(),
                          "",
                          bodyFs,
                          smallFs,
                          colorScheme,
                          spacing,
                        ),
                        _statBox(
                          "Processed (30 days)",
                          processed30DaysLabel,
                          "",
                          bodyFs,
                          smallFs,
                          colorScheme,
                          spacing,
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
              "Showing ${items.length} of $totalTransactions transactions",
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            SizedBox(height: spacing * 1.5),
            if (_loading)
              ...List.generate(
                4,
                (_) => _buildShimmerCard(
                  colorScheme,
                  width,
                  hp,
                  spacing,
                  iconSize,
                  cardPadding,
                ),
              )
            else if (items.isEmpty)
              _buildEmptyCard(colorScheme, hp, bodyFs)
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final tran = entry.value;

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
                        onTap: () => context.push(
                          "/user/transactions/details/${tran.id}",
                          extra: tran,
                        ),
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
                                        color: colorScheme.primary.withOpacity(
                                          0.6,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.money_dollar_circle,
                                      size: AdaptiveUtils.getFsAvatarFontSize(
                                        width,
                                      ),
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
                                                _formatDate(tran.createdAt),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: smallFs,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: spacing + 4,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  tran.normalizedStatus,
                                                ).withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                tran.statusLabel,
                                                style: GoogleFonts.inter(
                                                  fontSize: smallFs,
                                                  fontWeight: FontWeight.w600,
                                                  color: _statusColor(
                                                    tran.normalizedStatus,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          tran.invoiceNumber.isEmpty
                                              ? 'Invoice ${tran.id}'
                                              : tran.invoiceNumber,
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
                                                tran.reference.isEmpty
                                                    ? tran.id
                                                    : tran.reference,
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
                                              onPressed: () {
                                                final text =
                                                    tran.reference.isEmpty
                                                    ? tran.id
                                                    : tran.reference;
                                                Clipboard.setData(
                                                  ClipboardData(text: text),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          tran.description.isEmpty
                                              ? '—'
                                              : tran.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          tran.method.isEmpty
                                              ? '—'
                                              : tran.method,
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
                                                "Credits: ${_formatCredits(tran)}",
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
                                                "Amount: ${_formatAmount(tran)}",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                      color: colorScheme.primary.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                    onSelected: (String value) {
                                      if (value == 'details') {
                                        context.push(
                                          "/user/transactions/details/${tran.id}",
                                          extra: tran,
                                        );
                                      } else if (value == 'receipt') {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Receipt API not available yet',
                                            ),
                                          ),
                                        );
                                      } else if (value == 'copy') {
                                        final text = tran.reference.isEmpty
                                            ? tran.id
                                            : tran.reference;
                                        Clipboard.setData(
                                          ClipboardData(text: text),
                                        );
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
                                              title: const Text(
                                                'Copy reference',
                                              ),
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
                  ),
                );
              }),
            SizedBox(height: hp * 3),
          ],
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
    double spacing,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: smallFs,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: smallFs - 1,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
