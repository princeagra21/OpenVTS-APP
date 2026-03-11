import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/models/permission_matrix.dart';
import 'package:fleet_stack/core/models/role_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RolesTab extends StatefulWidget {
  final String adminId;

  const RolesTab({super.key, required this.adminId});

  @override
  State<RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<RolesTab> {
  String? _selectedRole;
  final Map<String, String> _permissions = <String, String>{};
  final List<RoleItem> _roles = <RoleItem>[];

  static const List<String> _permissionLevels = <String>[
    'Full',
    'Manage',
    'Edit',
    'View',
    'None',
  ];

  bool _loading = false;
  bool _errorShown = false;
  bool _saveNotEnabledShown = false;

  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadRoleAndPermissions();
  }

  @override
  void dispose() {
    _token?.cancel('dispose');
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = SuperadminRepository(api: _api!);
  }

  void _snackOnce(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  List<RoleItem> _normalizeRoles(List<Map<String, dynamic>> rows) {
    final out = <RoleItem>[];
    final seen = <String>{};

    for (final raw in rows) {
      final roleMap = _asMap(raw['role']);
      final dataMap = _asMap(raw['data']);
      final merged = <String, dynamic>{...raw, ...dataMap, ...roleMap};

      final name = _pickString(merged, const [
        'name',
        'title',
        'roleName',
        'role',
        'label',
      ]);
      if (name.isEmpty) continue;

      final id = _pickString(merged, const [
        'id',
        'roleId',
        'role_id',
        'uid',
        'code',
        'slug',
      ]);

      final fingerprint = '${id.toLowerCase()}|${name.toLowerCase()}';
      if (!seen.add(fingerprint)) continue;
      out.add(RoleItem({'id': id.isEmpty ? name : id, 'name': name}));
    }

    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  Future<void> _loadRoleAndPermissions() async {
    _ensureRepo();

    _token?.cancel('reload');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final rolesFuture = _repo!.getRoles(cancelToken: token);
      final profileFuture = _repo!.getAdminProfile(
        widget.adminId,
        cancelToken: token,
      );
      final profileRes = await profileFuture;
      final rolesRes = await rolesFuture;

      if (!mounted) return;

      String adminRoleId = '';
      String adminRoleName = '';
      final nextRoles = <RoleItem>[];
      final nextPermissions = <String, String>{};

      if (rolesRes.isSuccess) {
        nextRoles.addAll(
          _normalizeRoles(rolesRes.data ?? const <Map<String, dynamic>>[]),
        );
      } else {
        final err = rolesRes.error;
        if (err is ApiException && err.statusCode == 404) {
          // Roles endpoint unavailable on this backend version.
        } else if (!_errorShown) {
          _errorShown = true;
          _snackOnce("Couldn't load role list.");
        }
      }

      if (profileRes.isSuccess) {
        final AdminProfile p = profileRes.data!;

        adminRoleId = p.roleId.trim();
        adminRoleName = p.roleName.trim();

        final matrix = PermissionMatrix.fromRaw(p.permissionsRaw);
        if (matrix.levelsByModule.isNotEmpty) {
          matrix.levelsByModule.forEach((module, level) {
            nextPermissions[module] = level.uiLabel;
          });
        }
      } else if (!_errorShown) {
        _errorShown = true;
        final err = profileRes.error;
        if (err is ApiException &&
            (err.statusCode == 401 || err.statusCode == 403)) {
          _snackOnce('Not authorized to view roles.');
        } else {
          _snackOnce("Couldn't load roles.");
        }
      }

      if (adminRoleName.isNotEmpty) {
        final roleExists = nextRoles.any(
          (r) => r.name.trim().toLowerCase() == adminRoleName.toLowerCase(),
        );
        if (!roleExists) {
          nextRoles.add(
            RoleItem({
              'id': adminRoleId.isEmpty ? adminRoleName : adminRoleId,
              'name': adminRoleName,
            }),
          );
          nextRoles.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        }
      }

      final roleNames =
          nextRoles
              .map((r) => r.name.trim())
              .where((n) => n.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      String? selected = _selectedRole;
      if (adminRoleName.isNotEmpty && roleNames.contains(adminRoleName)) {
        selected = adminRoleName;
      } else if (selected != null && roleNames.contains(selected)) {
        // keep current selection
      } else if (roleNames.isNotEmpty) {
        selected = roleNames.first;
      } else {
        selected = null;
      }

      if (!mounted) return;
      setState(() {
        _errorShown = false;
        _loading = false;
        _roles
          ..clear()
          ..addAll(nextRoles);
        _permissions
          ..clear()
          ..addAll(nextPermissions);
        _selectedRole = selected;
      });
    } catch (_) {
      if (!_errorShown) {
        _errorShown = true;
        _snackOnce("Couldn't load roles.");
      }
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _updatePermission(String module, String level) {
    setState(() {
      _permissions[module] = level;
    });
    if (!_saveNotEnabledShown) {
      _saveNotEnabledShown = true;
      _snackOnce('Editing roles not available yet.');
    }
  }

  Widget _buildSettingField({
    required IconData icon,
    required String label,
    required String hint,
    required List<DropdownMenuItem<String>> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    final selectedValue = items.any((item) => item.value == _selectedRole)
        ? _selectedRole
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary.withOpacity(0.2),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant,
          ),
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          items: items,
          value: selectedValue,
          onChanged: items.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildPermissionRow(String module, double screenWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          module,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _permissionLevels.map((level) {
            return ChoiceChip(
              showCheckmark: false,
              label: Text(
                level,
                style: GoogleFonts.inter(fontSize: fontSize - 1),
              ),
              selected: _permissions[module] == level,
              selectedColor: colorScheme.primary.withOpacity(0.18),
              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.55),
              side: BorderSide(
                color: _permissions[module] == level
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.08),
              ),
              onSelected: (_) => _updatePermission(module, level),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionSkeleton() {
    return Column(
      children: List<Widget>.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: AppShimmer(width: double.infinity, height: 56, radius: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    final roleNames =
        _roles
            .map((r) => r.name.trim())
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final roleItems = roleNames
        .map((n) => DropdownMenuItem<String>(value: n, child: Text(n)))
        .toList();

    final modules = _permissions.keys.toList()..sort();
    final showNoPermissions = !_loading && modules.isEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Roles',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: _loading
                      ? const AppShimmer(width: 12, height: 12, radius: 6)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_loading && roleItems.isEmpty)
              const AppShimmer(width: double.infinity, height: 54, radius: 16)
            else
              _buildSettingField(
                icon: Icons.person,
                label: 'Select Role',
                hint: roleItems.isEmpty ? 'No roles from API' : 'Select Role',
                items: roleItems,
              ),
            const SizedBox(height: 20),
            Text(
              'Permissions overview for this role',
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 20),
            if (_loading && modules.isEmpty)
              _buildPermissionSkeleton()
            else if (showNoPermissions)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  'No permissions data from API.',
                  style: GoogleFonts.inter(
                    fontSize: fontSize - 1,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < modules.length; i++) ...[
                    _buildPermissionRow(modules[i], screenWidth),
                    if (i != modules.length - 1) const SizedBox(height: 18),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
