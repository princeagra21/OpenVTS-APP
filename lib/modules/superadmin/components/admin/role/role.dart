import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final TextEditingController _roleController = TextEditingController();
  final Map<String, int> permissions = <String, int>{};
  final List<String> currencies = <String>[
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AED',
    'SAR',
  ];
  final List<int> amounts = <int>[0, 5, 10, 25, 50, 100, 250, 500];

  List<Map<String, dynamic>> _roles = const <Map<String, dynamic>>[];
  String _selectedRoleKey = '';
  String selectedRoleTitle = '';
  String selectedCurrency = 'USD';
  int selectedAmount = 0;

  bool _loading = false;
  bool _errorShown = false;
  bool _actionUnavailableShown = false;
  CancelToken? _token;
  ApiClient? _apiClient;
  SuperadminRepository? _repo;

  static const List<Map<String, Object>> _permissionLevels =
      <Map<String, Object>>[
        {'label': 'None', 'level': 0},
        {'label': 'View', 'level': 1},
        {'label': 'Edit', 'level': 2},
        {'label': 'Manage', 'level': 3},
        {'label': 'Full', 'level': 4},
      ];

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _token?.cancel('Roles screen disposed');
    _roleController.dispose();
    super.dispose();
  }

  SuperadminRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= SuperadminRepository(api: _apiClient!);
    return _repo!;
  }

  Future<void> _loadRoles() async {
    _token?.cancel('Reload roles');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getRoles(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (rows) {
          final normalized = _normalizeRoles(rows);
          setState(() {
            _loading = false;
            _errorShown = false;
            _roles = normalized;
          });

          if (normalized.isNotEmpty) {
            _applyRoleFromMap(normalized.first);
          } else {
            _clearRoleSelection();
          }
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view roles.'
              : "Couldn't load roles.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load roles.")));
    }
  }

  List<Map<String, dynamic>> _normalizeRoles(List<Map<String, dynamic>> rows) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final raw in rows) {
      final normalized = _normalizeRole(raw);
      final title = (normalized['title'] as String?)?.trim() ?? '';
      final key = (normalized['key'] as String?)?.trim() ?? '';
      if (title.isEmpty) continue;

      final fingerprint = '${key.toLowerCase()}|${title.toLowerCase()}';
      if (!seen.add(fingerprint)) continue;
      out.add(normalized);
    }

    return out;
  }

  Map<String, dynamic> _normalizeRole(Map<String, dynamic> raw) {
    final roleMap = _asMap(raw['role']);
    final dataMap = _asMap(raw['data']);
    final merged = <String, dynamic>{...raw, ...dataMap, ...roleMap};

    final title = _pickString(merged, const [
      'name',
      'title',
      'roleName',
      'role',
      'label',
    ]);
    final key = _pickString(merged, const [
      'id',
      'roleId',
      'uid',
      'code',
      'slug',
    ]);
    final currency = _pickString(merged, const [
      'currency',
      'billingCurrency',
      'priceCurrency',
      'costCurrency',
    ]).toUpperCase();
    final amount = _pickInt(merged, const [
      'monthlyCost',
      'amount',
      'price',
      'cost',
      'monthly_price',
    ]);
    final permissionSource =
        merged['permissions'] ??
        merged['permission'] ??
        merged['access'] ??
        merged['modules'] ??
        merged['rights'];

    return <String, dynamic>{
      'key': key.isNotEmpty ? key : title,
      'title': title,
      'currency': currency,
      'amount': amount,
      'permissions': _parsePermissions(permissionSource),
    };
  }

  Map<String, int> _parsePermissions(Object? raw) {
    final out = <String, int>{};

    if (raw is Map) {
      final map = _asMap(raw);
      map.forEach((module, value) {
        final name = module.toString().trim();
        if (name.isEmpty) return;
        out[name] = _permissionLevelFromAny(value);
      });
      return out;
    }

    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final map = _asMap(item);
        final module = _pickString(map, const [
          'module',
          'name',
          'key',
          'resource',
          'title',
        ]);
        if (module.isEmpty) continue;

        final level = _permissionLevelFromAny(
          map['level'] ?? map['access'] ?? map['permission'] ?? map['value'],
        );
        out[module] = level;
      }
    }

    return out;
  }

  int _permissionLevelFromAny(Object? value) {
    if (value == null) return 0;
    if (value is int) return value.clamp(0, 4).toInt();
    if (value is num) return value.toInt().clamp(0, 4).toInt();
    if (value is bool) return value ? 1 : 0;

    if (value is Map) {
      final map = _asMap(value);
      if (_isTruthy(map['full']) ||
          _isTruthy(map['all']) ||
          _isTruthy(map['owner']) ||
          _isTruthy(map['superadmin'])) {
        return 4;
      }
      if (_isTruthy(map['manage']) || _isTruthy(map['admin'])) return 3;
      if (_isTruthy(map['edit']) ||
          _isTruthy(map['write']) ||
          _isTruthy(map['update'])) {
        return 2;
      }
      if (_isTruthy(map['view']) ||
          _isTruthy(map['read']) ||
          _isTruthy(map['access'])) {
        return 1;
      }
      if (map.containsKey('level'))
        return _permissionLevelFromAny(map['level']);
      if (map.containsKey('value'))
        return _permissionLevelFromAny(map['value']);
      return 0;
    }

    final s = value.toString().trim().toLowerCase();
    if (s.isEmpty) return 0;

    if (const {'none', 'no', 'deny', 'denied', '0', 'false'}.contains(s)) {
      return 0;
    }
    if (const {'view', 'read', 'viewer', 'readonly', '1', 'true'}.contains(s)) {
      return 1;
    }
    if (const {'edit', 'write', 'update', '2'}.contains(s)) return 2;
    if (const {'manage', 'manager', 'admin', '3'}.contains(s)) return 3;
    if (const {'full', 'all', 'owner', 'superadmin', '4'}.contains(s)) {
      return 4;
    }

    final parsed = int.tryParse(s);
    if (parsed != null) return parsed.clamp(0, 4).toInt();
    return 0;
  }

  bool _isTruthy(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().trim().toLowerCase() ?? '';
    return const {'true', '1', 'yes', 'y'}.contains(s);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  String _pickString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int _pickInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  void _applyRoleFromMap(Map<String, dynamic> role) {
    final roleKey = (role['key'] as String?)?.trim() ?? '';
    final title = (role['title'] as String?)?.trim() ?? '';
    final currency = (role['currency'] as String?)?.trim().toUpperCase() ?? '';
    final amount = (role['amount'] as int?) ?? 0;
    final rolePermissions = Map<String, int>.from(
      (role['permissions'] as Map<String, int>?) ?? const <String, int>{},
    );

    if (currency.isNotEmpty && !currencies.contains(currency)) {
      currencies.add(currency);
    }
    if (!amounts.contains(amount)) {
      amounts.add(amount);
      amounts.sort();
    }

    if (!mounted) return;
    setState(() {
      _selectedRoleKey = roleKey;
      selectedRoleTitle = title;
      _roleController.text = title;
      if (currency.isNotEmpty) {
        selectedCurrency = currency;
      } else if (!currencies.contains(selectedCurrency)) {
        selectedCurrency = currencies.first;
      }
      selectedAmount = amounts.contains(amount) ? amount : amounts.first;
      permissions
        ..clear()
        ..addAll(rolePermissions);
    });
  }

  void _clearRoleSelection() {
    if (!mounted) return;
    setState(() {
      _selectedRoleKey = '';
      selectedRoleTitle = '';
      _roleController.text = '';
      selectedCurrency = currencies.first;
      selectedAmount = amounts.first;
      permissions.clear();
    });
  }

  void _setAllPermissions(int level) {
    if (permissions.isEmpty) return;
    setState(() {
      for (final module in permissions.keys.toList()) {
        permissions[module] = level;
      }
    });
  }

  void _showRoleActionUnavailable() {
    if (_actionUnavailableShown || !mounted) return;
    _actionUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Role action API not available yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final bool showSkeleton = _loading && _roles.isEmpty;
    final bool showNoData = !_loading && _roles.isEmpty;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Role Permissions",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.onSurface.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.onSurface.withOpacity(0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _loadRoles,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showRoleActionUnavailable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.error,
                        ),
                        icon: Icon(Icons.delete_outline, color: scheme.onError),
                        label: Text(
                          "Delete",
                          style: GoogleFonts.inter(
                            color: scheme.onError,
                            fontWeight: FontWeight.w600,
                            fontSize: titleFs - 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showRoleActionUnavailable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                        ),
                        icon: Icon(
                          Icons.save_outlined,
                          color: scheme.onPrimary,
                        ),
                        label: Text(
                          "Save",
                          style: GoogleFonts.inter(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: titleFs - 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Role Permissions",
                    style: GoogleFonts.inter(
                      fontSize: titleFs + 2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Configure access levels for different modules",
                    style: GoogleFonts.inter(
                      fontSize: titleFs - 2,
                      fontWeight: FontWeight.w300,
                      color: scheme.onSurface.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Roles",
                    style: GoogleFonts.inter(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (showSkeleton)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        AppShimmer(width: 110, height: 34, radius: 12),
                        AppShimmer(width: 120, height: 34, radius: 12),
                        AppShimmer(width: 92, height: 34, radius: 12),
                      ],
                    )
                  else if (showNoData)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        "No role data from API.",
                        style: GoogleFonts.inter(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _roles.map((role) {
                        final key = (role['key'] as String?) ?? '';
                        final title = (role['title'] as String?) ?? 'Role';
                        return _LocalTab(
                          label: title,
                          selected: key == _selectedRoleKey,
                          onTap: () => _applyRoleFromMap(role),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 28),
                  Text(
                    "Role Title",
                    style: GoogleFonts.inter(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showSkeleton)
                    const AppShimmer(
                      width: double.infinity,
                      height: 48,
                      radius: 16,
                    )
                  else
                    TextField(
                      controller: _roleController,
                      onChanged: (v) => setState(() => selectedRoleTitle = v),
                      decoration: _inputDecoration(context, hint: "Role name"),
                      style: GoogleFonts.inter(color: scheme.onSurface),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    "Monthly Cost",
                    style: GoogleFonts.inter(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (showSkeleton)
                    const Column(
                      children: [
                        AppShimmer(
                          width: double.infinity,
                          height: 48,
                          radius: 16,
                        ),
                        SizedBox(height: 12),
                        AppShimmer(
                          width: double.infinity,
                          height: 48,
                          radius: 16,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.onSurface.withOpacity(0.08),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCurrency,
                              isExpanded: true,
                              style: GoogleFonts.inter(color: scheme.onSurface),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => selectedCurrency = v);
                              },
                              items: currencies
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.onSurface.withOpacity(0.08),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedAmount,
                              isExpanded: true,
                              style: GoogleFonts.inter(color: scheme.onSurface),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => selectedAmount = v);
                              },
                              items: amounts
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,
                                      child: Text(a == 0 ? "Free" : "$a"),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 28),
                  Text(
                    "Set all:",
                    style: GoogleFonts.inter(
                      fontSize: titleFs,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (showSkeleton)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        AppShimmer(width: 64, height: 32, radius: 12),
                        AppShimmer(width: 64, height: 32, radius: 12),
                        AppShimmer(width: 64, height: 32, radius: 12),
                        AppShimmer(width: 72, height: 32, radius: 12),
                        AppShimmer(width: 58, height: 32, radius: 12),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _permissionLevels.map((item) {
                        return _LocalTab(
                          label: item['label']! as String,
                          selected: false,
                          onTap: () =>
                              _setAllPermissions(item['level']! as int),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 28),
                  if (showSkeleton)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: List<Widget>.generate(
                          6,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: AppShimmer(
                              width: double.infinity,
                              height: 18,
                              radius: 8,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (permissions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.onSurface.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        "No permissions data for selected role.",
                        style: GoogleFonts.inter(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Module",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  "Access",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 32,
                            color: scheme.onSurface.withOpacity(0.06),
                          ),
                          ...permissions.keys.map((module) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      module,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _permissionLevels.map((item) {
                                        final level = item['level']! as int;
                                        final label = item['label']! as String;
                                        final isSelected =
                                            permissions[module] == level;
                                        return _LocalTab(
                                          label: label,
                                          selected: isSelected,
                                          onTap: () => setState(
                                            () => permissions[module] = level,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {String? hint}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: scheme.onSurface.withOpacity(0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    );
  }
}

class _LocalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocalTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool small = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.onSurface.withOpacity(0.06),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
