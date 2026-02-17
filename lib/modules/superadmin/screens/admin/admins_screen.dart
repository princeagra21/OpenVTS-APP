import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  late List<Map<String, dynamic>> _admins;
  bool _loadingAdmins = false;
  bool _adminsErrorShown = false;
  CancelToken? _adminsCancelToken;
  final Map<String, CancelToken> _statusTokensByAdminId = {};
  final Set<String> _statusSubmittingAdminIds = {};

  ApiClient? _api;
  SuperadminRepository? _repo;

  final List<Map<String, dynamic>> _fallbackAdmins = List.generate(
    5,
    (i) => {
      "id": i,
      "initials": "MS",
      "name": "Muhammad Sani",
      "phone": "+2349018980920",
      "username": "@muhammad",
      "email": "muhammad@gmail.com",
      "status": i % 2 == 0 ? "Verified" : "Pending",
      "vehicles": "76",
      "credits": "18",
      "recentLogin": "Oct 12, 09:32",
      "active": true,
      "location": "Dawakin Tofa, Kano, Nigeria",
      "joined": "Aug 11, 2025 • 120d",
      "role": "Das Fleet Management • Primary",
    },
  );

  @override
  void initState() {
    super.initState();
    _admins = List<Map<String, dynamic>>.from(_fallbackAdmins);
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

  Map<String, dynamic> _mapAdmin(AdminListItem a) {
    final name = a.name.isNotEmpty ? a.name : '—';
    final status = a.status.isNotEmpty
        ? a.status
        : (a.isActive ? 'Active' : 'Disabled');

    return <String, dynamic>{
      "id": a.id.isNotEmpty ? a.id : '',
      "initials": _initials(name),
      "name": name,
      "phone": a.phone,
      "username": a.username.isNotEmpty ? '@${a.username}' : '',
      "email": a.email,
      "status": status,
      "vehicles": a.vehiclesCount == 0 ? '' : a.vehiclesCount.toString(),
      "credits": a.credits == 0 ? '' : a.credits.toString(),
      "recentLogin": a.recentLogin,
      "active": a.isActive,
      "location": a.location,
      "joined": a.createdAt,
      "role": a.role,
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
        limit: 50,
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
            _admins = mapped;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingAdmins = false);
          if (_adminsErrorShown) return;
          _adminsErrorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view admins.'
              : "Couldn't load admins. Showing fallback list.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
      if (_adminsErrorShown) return;
      _adminsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load admins. Showing fallback list."),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        admin['active'] = prev; // revert
        _statusSubmittingAdminIds.remove(adminId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update status.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // --- ADAPTIVE VALUES ---
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8-16
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6-10
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth); // 13-15
    final bodyFs = titleFs - 1; // general text
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
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

    return AppLayout(
      title: "SUPER ADMIN",
      subtitle: "Administrators",
      actionIcons: const [CupertinoIcons.add],
      onActionTaps: [
        // NEW: Handle tap on add icon
        () {
          context.push(
            '/superadmin/admins/add',
          ); // Navigate to AddNewAdminScreen (adjust route if needed)
        },
      ],
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------
            // SEARCH FIELD
            // --------------------------------------------
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
                  hintText: "Search name, email, role, department...",
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.onSurface,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: padding,
                  ),
                ),
              ),
            ),

            SizedBox(height: padding),

            // --------------------------------------------
            // TABS
            // --------------------------------------------
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Active", "Disabled", "Pending"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),

            SizedBox(height: padding),

            // --------------------------------------------
            // TOP ROW: showing count + export
            // --------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            "Showing ${filteredAdmins.length} of ${_admins.length} admins",
                        style: GoogleFonts.inter(
                          fontSize: bodyFs,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      if (_loadingAdmins)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // EXPORT BUTTON
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 1.5,
                    vertical: spacing,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    "Export",
                    style: GoogleFonts.inter(
                      fontSize: bodyFs,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing),

            // --------------------------------------------
            // ADMIN LIST
            // --------------------------------------------
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAdmins.length,
              itemBuilder: (context, index) {
                final admin = filteredAdmins[index];

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
                      onTap: () {
                        () async {
                          final ctx = context;
                          final deleted = await ctx.push<bool>(
                            "/superadmin/admins/details/${admin['id']}",
                          );
                          if (!ctx.mounted) return;
                          if (deleted == true) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Admin deleted')),
                            );
                            _loadAdmins();
                          }
                        }();
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // AVATAR
                                CircleAvatar(
                                  backgroundColor: colorScheme.primary,
                                  radius:
                                      AdaptiveUtils.getAvatarSize(screenWidth) /
                                      2,
                                  child: Text(
                                    admin["initials"],
                                    style: GoogleFonts.inter(
                                      color: colorScheme.onPrimary,
                                      fontSize:
                                          AdaptiveUtils.getFsAvatarFontSize(
                                            screenWidth,
                                          ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(width: spacing * 2),

                                // RIGHT SIDE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // NAME + STATUS + LOGIN
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                admin["name"],
                                                style: GoogleFonts.inter(
                                                  fontSize: bodyFs,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              SizedBox(width: spacing),

                                              // STATUS BADGE
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: spacing + 2,
                                                  vertical: spacing - 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      admin["status"] ==
                                                          "Verified"
                                                      ? Colors.green
                                                            .withOpacity(0.2)
                                                      : Colors.orange
                                                            .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  admin["status"],
                                                  style: GoogleFonts.inter(
                                                    fontSize: smallFs,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        admin["status"] ==
                                                            "Verified"
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // LOGIN BUTTON
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: padding + 4,
                                              vertical: spacing - 2,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: colorScheme.primary
                                                    .withOpacity(0.5),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Text(
                                              "Login",
                                              style: GoogleFonts.inter(
                                                fontSize: smallFs + 1,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: spacing),

                                      // PHONE
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.phone,
                                            size: iconSize,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.87),
                                          ),
                                          SizedBox(width: spacing),
                                          Text(
                                            admin["phone"],
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: spacing / 2),

                                      // EMAIL
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.mail,
                                            size: iconSize,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.87),
                                          ),
                                          SizedBox(width: spacing),
                                          Text(
                                            admin["email"],
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
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

                            // VEHICLES + CREDITS
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: padding,
                                    vertical: spacing - 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "${admin["vehicles"]} Vehicles",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),

                                SizedBox(width: spacing * 2),

                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: padding,
                                    vertical: spacing - 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                  child: Text(
                                    "${admin["credits"]} LOW Credits",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing * 2),

                            // RECENT LOGIN + SWITCH
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recent login: ${admin["recentLogin"]}",
                                  style: GoogleFonts.inter(
                                    fontSize: smallFs + 1,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),

                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: admin["active"],
                                    onChanged:
                                        _statusSubmittingAdminIds.contains(
                                              admin['id']?.toString() ?? '',
                                            )
                                            ? null
                                            : (v) => _toggleAdminStatus(
                                                  admin: admin,
                                                  isActive: v,
                                                ),
                                    activeColor: colorScheme.onPrimary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveThumbColor: colorScheme.onPrimary,
                                    inactiveTrackColor: colorScheme.primary
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing),

                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(
                                    0.87,
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: Text(
                                    admin["location"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing),

                            Divider(
                              color: colorScheme.onSurface.withOpacity(0.1),
                            ),

                            SizedBox(height: spacing),

                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Joined: ${admin["joined"]}",
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    admin["role"],
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs - 1,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
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
