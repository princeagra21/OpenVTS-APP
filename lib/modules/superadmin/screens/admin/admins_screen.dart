import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';
import '../../utils/app_utils.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 50;

  final List<Map<String, dynamic>> _admins = <Map<String, dynamic>>[];
  bool _loadingAdmins = false;
  bool _adminsErrorShown = false;
  bool _adminsLoadFailed = false;
  CancelToken? _adminsCancelToken;
  final Map<String, CancelToken> _statusTokensByAdminId = {};
  final Set<String> _statusSubmittingAdminIds = {};
  final Set<String> _loginSubmittingAdminIds = {};

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadAdmins();
  }

  @override
  void dispose() {
    _adminsCancelToken?.cancel('AdminScreen disposed');
    for (final t in _statusTokensByAdminId.values) {
      t.cancel('AdminScreen disposed');
    }
    _searchController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\\s+'));
    final out = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join();
    return out.isEmpty ? '—' : out.toUpperCase();
  }

  String _safeText(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _normalizeStatusLabel(String raw, bool isActive) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return isActive ? 'Active' : 'Disabled';
    if (t == 'true' || t == '1') return 'Active';
    if (t == 'false' || t == '0') return 'Disabled';
    if (t == 'verified') return 'Verified';
    if (t == 'pending') return 'Pending';
    if (t == 'inactive') return 'Disabled';
    return raw;
  }

  String _formatRecentLogin(String? value) {
    final raw = _safeText(value, fallback: '');
    if (raw.isEmpty || raw == '-') return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = parsed.toLocal();
    final m = months[local.month - 1];
    return '${local.year}, $m ${local.day}';
  }

  Map<String, dynamic> _mapAdmin(AdminListItem a) {
    final name = _safeText(a.name);
    final active = a.isActive;
    final status = _normalizeStatusLabel(a.status, active);
    final username = a.username.isNotEmpty
        ? (a.username.startsWith('@') ? a.username : '@${a.username}')
        : '-';

    return <String, dynamic>{
      "id": a.id.isNotEmpty ? a.id : '',
      "initials": _initials(name),
      "name": name,
      "phone": _safeText(a.phone),
      "username": username,
      "email": _safeText(a.email),
      "company": _safeText(
        a.raw['companyName'] ??
            a.raw['company_name'] ??
            a.raw['company'] ??
            a.raw['organization'] ??
            a.raw['orgName'],
      ),
      "status": status,
      "vehicles": a.vehiclesCount == 0 ? '' : a.vehiclesCount.toString(),
      "credits": a.credits == 0 ? '' : a.credits.toString(),
      "recentLogin": _formatRecentLogin(a.recentLogin),
      "active": active,
      "location": _safeText(a.location),
      "joined": _safeText(a.createdAt),
      "role": _safeText(a.role),
    };
  }

  Future<void> _loadAdmins() async {
    _adminsCancelToken?.cancel('Reload admins');
    final token = CancelToken();
    _adminsCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingAdmins = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdmins(
        page: 1,
        limit: _pageSize,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          if (!mounted) return;
          final mapped = items.map(_mapAdmin).toList();
          setState(() {
            _loadingAdmins = false;
            _adminsErrorShown = false;
            _adminsLoadFailed = false;
            _admins
              ..clear()
              ..addAll(mapped);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _loadingAdmins = false;
            _adminsLoadFailed = true;
            _admins.clear();
          });
          if (_adminsErrorShown) return;
          _adminsErrorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view admins.'
              : "Couldn't load admins.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _adminsErrorShown = false;
                  _loadAdmins();
                },
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAdmins = false;
        _adminsLoadFailed = true;
        _admins.clear();
      });
      if (_adminsErrorShown) return;
      _adminsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load admins."),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _adminsErrorShown = false;
              _loadAdmins();
            },
          ),
        ),
      );
    }
  }

  Future<void> _toggleAdminStatus({
    required Map<String, dynamic> admin,
    required bool isActive,
  }) async {
    final adminId = admin['id']?.toString() ?? '';
    if (adminId.isEmpty) return;
    if (_statusSubmittingAdminIds.contains(adminId)) return;

    final prev = admin['active'] == true;

    // Optimistic update.
    setState(() {
      admin['active'] = isActive;
      _statusSubmittingAdminIds.add(adminId);
    });

    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= SuperadminRepository(api: _api!);

    _statusTokensByAdminId[adminId]?.cancel('New toggle');
    final token = CancelToken();
    _statusTokensByAdminId[adminId] = token;

    try {
      final res = await _repo!.updateAdminStatus(
        adminId,
        isActive,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _statusSubmittingAdminIds.remove(adminId);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            admin['active'] = prev; // revert
            _statusSubmittingAdminIds.remove(adminId);
          });

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized.'
              : "Couldn't update status.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        admin['active'] = prev; // revert
        _statusSubmittingAdminIds.remove(adminId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't update status.")));
    }
  }

  Future<void> _loginAsAdmin(Map<String, dynamic> admin) async {
    final adminId = admin['id']?.toString() ?? '';
    if (adminId.isEmpty) return;
    if (_loginSubmittingAdminIds.contains(adminId)) return;

    _loginSubmittingAdminIds.add(adminId);
    setState(() {});

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.loginAsAdmin(adminId);
      if (!mounted) return;
      res.when(
        success: (token) async {
          await TokenStorage.defaultInstance().writeAccessToken(token);
          if (!mounted) return;
          context.go('/admin/home');
        },
        failure: (err) {
          final msg =
              err is ApiException
                  ? (err.message ?? 'Login failed.')
                  : 'Login failed.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed.')));
    } finally {
      _loginSubmittingAdminIds.remove(adminId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmLoginAsAdmin(Map<String, dynamic> admin) async {
    final name = _safeText(admin['name']?.toString(), fallback: 'this admin');
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (_) => _AdminLoginConfirmDialog(adminName: name),
    );
    if (shouldLogin != true) return;
    await _loginAsAdmin(admin);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // --- ADAPTIVE VALUES ---
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8-16
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6-10
    final scale =
        (screenWidth / 390).clamp(0.9, 1.05); // responsive but close to spec
    final fsHeader = 16 * scale;
    final fsSection = 18 * scale;
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final titleFs = fsHeader;
    final bodyFs = fsMain;
    final smallFs = fsMeta;
    final iconSize = 18.0;
    final cardPadding = padding + 4; // slightly bigger for cards

    final query = _searchController.text.trim().toLowerCase();
    final filteredAdmins = _admins.where((a) {
      final matchesSearch =
          query.isEmpty ||
          a['name'].toString().toLowerCase().contains(query) ||
          a['email'].toString().toLowerCase().contains(query) ||
          a['role'].toString().toLowerCase().contains(query) ||
          a['username'].toString().toLowerCase().contains(query);

      final status = a['status'].toString().toLowerCase();
      final active = a['active'] == true;
      final matchesTab =
          selectedTab == "All" ||
          (selectedTab == "Active" && active) ||
          (selectedTab == "Disabled" && !active) ||
          (selectedTab == "Pending" && status.contains('pending'));

      return matchesSearch && matchesTab;
    }).toList();
    final showNoData = !_loadingAdmins && filteredAdmins.isEmpty;

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
            // --------------------------------------------
            // ADMIN LIST
            // --------------------------------------------
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
                        "Administrators",
                        style: GoogleFonts.roboto(
                          fontSize: fsSection,
                          height: 24 / 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.push('/superadmin/admins/add');
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
                  // --------------------------------------------
                  // SEARCH FIELD
                  // --------------------------------------------
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
                        hintText: "Search name, email, role, department...",
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
                                  value: "Disabled",
                                  child: Text('Disabled'),
                                ),
                                PopupMenuItem(
                                  value: "Pending",
                                  child: Text('Pending'),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                _loadAdmins();
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                              onTap: _loadAdmins,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                _adminsLoadFailed
                                    ? "Couldn't load admins."
                                    : "No admins found",
                                style: GoogleFonts.roboto(
                                  fontSize: fsSecondary,
                                  height: 16 / 12,
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_adminsLoadFailed)
                              TextButton(
                                onPressed: _loadAdmins,
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_loadingAdmins)
                    ...List<Widget>.generate(
                      3,
                      (_) => _buildAdminSkeletonCard(
                        padding: padding,
                        spacing: spacing,
                        cardPadding: cardPadding,
                        screenWidth: screenWidth,
                        bodyFs: bodyFs,
                        smallFs: smallFs,
                      ),
                    ),
                  if (!showNoData && !_loadingAdmins)
                    ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAdmins.length,
                      itemBuilder: (context, index) {
                        final admin = filteredAdmins[index];
                        final statusLabel = admin["status"].toString();
                        final statusLower = statusLabel.toLowerCase();
                        final isPending = statusLower.contains('pending');
                        final isPositive =
                            statusLower.contains('verified') ||
                            statusLower.contains('active');
                        final statusColor = isPending
                            ? Colors.orange
                            : (isPositive ? Colors.green : colorScheme.error);
                        final statusBg = statusColor.withOpacity(0.2);

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
                        onTap: null,
                              child: Padding(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              colorScheme.surface,
                                          radius:
                                              AdaptiveUtils.getAvatarSize(
                                                    screenWidth,
                                                  ) /
                                                  2,
                                          foregroundColor:
                                              colorScheme.onSurface,
                                          child: Container(
                                            width:
                                                AdaptiveUtils.getAvatarSize(
                                                  screenWidth,
                                                ),
                                            height:
                                                AdaptiveUtils.getAvatarSize(
                                                  screenWidth,
                                                ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              admin["initials"],
                                              style: GoogleFonts.roboto(
                                                color:
                                                    colorScheme.onSurface,
                                                fontSize:
                                                    AdaptiveUtils
                                                        .getFsAvatarFontSize(
                                                          screenWidth,
                                                        ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: spacing * 2),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {
                                                        final id = admin['id']
                                                                ?.toString() ??
                                                            '';
                                                        if (id.isEmpty) return;
                                                        context.push(
                                                          '/superadmin/admins/details/$id',
                                                        );
                                                      },
                                                      child: Text(
                                                        admin["name"],
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize: fsMain,
                                                          height: 20 / 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: colorScheme
                                                              .onSurface,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  Transform.scale(
                                                    scale: 0.75,
                                                    child: Switch(
                                                      value: admin["active"],
                                                      onChanged:
                                                          _statusSubmittingAdminIds
                                                                  .contains(
                                                        admin['id']
                                                                ?.toString() ??
                                                            '',
                                                      )
                                                              ? null
                                                              : (v) =>
                                                                  _toggleAdminStatus(
                                                                    admin:
                                                                        admin,
                                                                    isActive:
                                                                        v,
                                                                  ),
                                                      activeColor:
                                                          colorScheme.onPrimary,
                                                      activeTrackColor:
                                                          colorScheme.primary,
                                                      inactiveThumbColor:
                                                          colorScheme.onPrimary,
                                                      inactiveTrackColor:
                                                          colorScheme.primary
                                                              .withOpacity(0.3),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: spacing / 2),
                                              Text(
                                                _safeText(
                                                  admin["username"]
                                                      ?.toString(),
                                                  fallback: '—',
                                                ),
                                                style: GoogleFonts.roboto(
                                                  fontSize: fsSecondary,
                                                  height: 16 / 12,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.7),
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: spacing / 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.mail,
                                                    size: iconSize,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                  SizedBox(width: spacing),
                                                  Expanded(
                                                    child: Text(
                                                      _safeText(
                                                        admin["email"]
                                                            ?.toString(),
                                                        fallback: '—',
                                                      ),
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsSecondary,
                                                        height: 16 / 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
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
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                  SizedBox(width: spacing),
                                                  Expanded(
                                                    child: Text(
                                                      _safeText(
                                                        admin["phone"]
                                                            ?.toString(),
                                                        fallback: '—',
                                                      ),
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsSecondary,
                                                        height: 16 / 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: spacing / 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.apartment,
                                                    size: iconSize,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                  SizedBox(width: spacing),
                                                  Expanded(
                                                    child: Text(
                                                      _safeText(
                                                        admin["company"]
                                                            ?.toString(),
                                                        fallback: '—',
                                                      ),
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsSecondary,
                                                        height: 16 / 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Location",
                                            style: GoogleFonts.roboto(
                                              fontSize: fsMeta,
                                              height: 14 / 11,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          SizedBox(height: spacing / 2),
                                          Text(
                                            _safeText(
                                              admin["location"]?.toString(),
                                              fallback: '—',
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.roboto(
                                              fontSize: fsSecondary,
                                              height: 16 / 12,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: spacing),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final double gap = spacing;
                                        final double cellWidth =
                                            (constraints.maxWidth - gap) / 2;
                                        return Wrap(
                                          spacing: gap,
                                          runSpacing: gap,
                                          children: [
                                            SizedBox(
                                              width: cellWidth,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing - 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.visibility,
                                                          size: iconSize,
                                                          color: colorScheme
                                                              .onSurface
                                                              .withOpacity(0.7),
                                                        ),
                                                        SizedBox(
                                                          width: spacing,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "Usage",
                                                            style:
                                                                GoogleFonts.roboto(
                                                              fontSize: fsMeta,
                                                              height: 14 / 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: spacing,
                                                    ),
                                                    Text(
                                                      _safeText(
                                                        admin["credits"]
                                                            ?.toString(),
                                                        fallback: '—',
                                                      ),
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: cellWidth,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: spacing - 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.schedule,
                                                          size: iconSize,
                                                          color: colorScheme
                                                              .onSurface
                                                              .withOpacity(0.7),
                                                        ),
                                                        SizedBox(
                                                          width: spacing,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "Recent login",
                                                            style:
                                                                GoogleFonts.roboto(
                                                              fontSize: fsMeta,
                                                              height: 14 / 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: spacing,
                                                    ),
                                                    Text(
                                                      _safeText(
                                                        admin["recentLogin"]
                                                            ?.toString(),
                                                        fallback: '—',
                                                      ),
                                                      style: GoogleFonts.roboto(
                                                        fontSize: fsMain,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    SizedBox(height: spacing),
                                    GestureDetector(
                                      onTap: () => _confirmLoginAsAdmin(admin),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: padding,
                                          vertical: spacing * 1.6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.login,
                                              size: iconSize,
                                              color: colorScheme.onPrimary,
                                            ),
                                            SizedBox(width: spacing),
                                            _loginSubmittingAdminIds.contains(
                                                  admin['id']?.toString() ??
                                                      '',
                                                )
                                                ? const AppShimmer(
                                                    width: 16,
                                                    height: 16,
                                                    radius: 8,
                                                  )
                                                : Text(
                                                    "Login",
                                                    style: GoogleFonts.roboto(
                                                      fontSize: fsMain,
                                                      height: 20 / 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          colorScheme.onPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
            child: SuperAdminHomeAppBar(
              title: 'Administration',
              leadingIcon: Symbols.verified_user,
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/superadmin/home');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSkeletonCard({
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
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
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
                    width: AdaptiveUtils.getAvatarSize(screenWidth),
                    height: AdaptiveUtils.getAvatarSize(screenWidth),
                    radius: AdaptiveUtils.getAvatarSize(screenWidth),
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
                              width: 72,
                              height: smallFs + 10,
                              radius: 999,
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: screenWidth * 0.4,
                          height: bodyFs + 6,
                          radius: 8,
                        ),
                        SizedBox(height: spacing / 2),
                        AppShimmer(
                          width: screenWidth * 0.52,
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
                  AppShimmer(width: 96, height: smallFs + 12, radius: 20),
                  SizedBox(width: spacing * 2),
                  AppShimmer(width: 110, height: smallFs + 12, radius: 20),
                ],
              ),
              SizedBox(height: spacing * 2),
              AppShimmer(
                width: screenWidth * 0.5,
                height: smallFs + 10,
                radius: 8,
              ),
              SizedBox(height: spacing),
              AppShimmer(
                width: double.infinity,
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
}

class _AdminLoginConfirmDialog extends StatelessWidget {
  final String adminName;

  const _AdminLoginConfirmDialog({required this.adminName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.login,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Login as admin?',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You are about to enter the admin module as $adminName. You can return to superadmin at any time.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
