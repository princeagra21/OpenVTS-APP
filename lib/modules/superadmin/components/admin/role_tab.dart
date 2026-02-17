import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/models/permission_matrix.dart';
import 'package:fleet_stack/core/models/role_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RolesTab extends StatefulWidget {
  final String adminId;

  const RolesTab({super.key, required this.adminId});

  @override
  State<RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<RolesTab> {
  String _selectedRole = 'Full Admin';
  final Map<String, String> _permissions = {};

  // Fallback-first roles list.
  List<RoleItem> _roles = const [
    RoleItem({'id': 'full_admin', 'name': 'Full Admin'}),
  ];

  final List<String> modules = [
    "Tenants",
    "Users",
    "Roles",
    "Vehicles",
    "Devices",
    "SIM/APN",
    "Live Tracking",
    "Geofences",
    "Alerts",
    "Commands",
    "Reports",
    "Billing",
    "Integrations",
    "Support",
    "SSL"
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
    for (var module in modules) {
      _permissions[module] = 'Full';
    }
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

  Future<void> _loadRoleAndPermissions() async {
    _ensureRepo();

    _token?.cancel('reload');
    _token = CancelToken();

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Postman-confirmed source of truth:
      // only use GET /superadmin/admin/{adminId} for role + permissions hydration.
      final res = await _repo!.getAdminProfile(
        widget.adminId,
        cancelToken: _token,
      );

      if (!mounted) return;

      String adminRoleId = '';
      String adminRoleName = '';

      if (res.isSuccess) {
        final AdminProfile p = res.data!;

        adminRoleId = p.roleId.trim();
        adminRoleName = p.roleName.trim();

        final matrix = PermissionMatrix.fromRaw(p.permissionsRaw);
        if (matrix.levelsByModule.isNotEmpty) {
          // Normalize/hydrate only the stable core module rows.
          const stableModules = <String>[
            'Tenants',
            'Users',
            'Roles',
            'Vehicles',
            'Devices',
            'SIM/APN',
          ];
          for (final module in stableModules) {
            final lvl = matrix.levelForModule(module);
            if (lvl != null) _permissions[module] = lvl.uiLabel;
          }
        } else if (kDebugMode) {
          debugPrint(
            'RolesTab: permissions missing in admin payload for adminId=${widget.adminId}',
          );
        }
      } else {
        if (!_errorShown) {
          _errorShown = true;
          final err = res.error;
          if (err is ApiException &&
              (err.statusCode == 401 || err.statusCode == 403)) {
            _snackOnce("Not authorized to view roles.");
          } else {
            _snackOnce("Couldn't load roles. Showing defaults.");
          }
        }
      }

      // Preselect role based on admin profile if possible.
      if (adminRoleName.isNotEmpty) {
        final match = _roles.firstWhere(
          (r) => r.name.trim().toLowerCase() == adminRoleName.toLowerCase(),
          orElse: () => const RoleItem({'id': '', 'name': ''}),
        );
        if (match.name.isNotEmpty) {
          _selectedRole = match.name;
        } else {
          _selectedRole = adminRoleName;
          final exists = _roles.any(
            (r) => r.name.trim().toLowerCase() == adminRoleName.toLowerCase(),
          );
          if (!exists) {
            _roles = [
              ..._roles,
              RoleItem({
                'id': adminRoleId.isEmpty ? adminRoleName : adminRoleId,
                'name': adminRoleName,
              }),
            ];
          }
        }
      }
    } catch (_) {
      if (!_errorShown) {
        _errorShown = true;
        _snackOnce("Couldn't load roles. Showing defaults.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
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
          value: _selectedRole,
          onChanged: (value) {
            setState(() {
              _selectedRole = value!;
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
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Full",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "Full",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      if (kDebugMode && !_saveNotEnabledShown) {
                        _saveNotEnabledShown = true;
                        _snackOnce("Editing roles not available yet.");
                      }
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Manage",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "Manage",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      if (kDebugMode && !_saveNotEnabledShown) {
                        _saveNotEnabledShown = true;
                        _snackOnce("Editing roles not available yet.");
                      }
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Edit",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "Edit",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      if (kDebugMode && !_saveNotEnabledShown) {
                        _saveNotEnabledShown = true;
                        _snackOnce("Editing roles not available yet.");
                      }
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "View",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      if (kDebugMode && !_saveNotEnabledShown) {
                        _saveNotEnabledShown = true;
                        _snackOnce("Editing roles not available yet.");
                      }
                    },
                  ),
                ],
              ),
            ),
            Text(
              "⟶",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                color: colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "None",
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Radio<String>(
                    activeColor: colorScheme.primary,
                    value: "None",
                    groupValue: _permissions[module],
                    onChanged: (value) {
                      setState(() {
                        _permissions[module] = value!;
                      });
                      if (kDebugMode && !_saveNotEnabledShown) {
                        _saveNotEnabledShown = true;
                        _snackOnce("Editing roles not available yet.");
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    final roleNames = _roles
        .map((r) => r.name.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (_selectedRole.trim().isNotEmpty && !roleNames.contains(_selectedRole)) {
      roleNames.insert(0, _selectedRole);
    }

    final roleItems = roleNames
        .map(
          (n) => DropdownMenuItem<String>(value: n, child: Text(n)),
        )
        .toList();

    List<Widget> permissionRows = [];
    for (var module in modules) {
      permissionRows.add(_buildPermissionRow(module, screenWidth));
      permissionRows.add(const SizedBox(height: 20));
    }
    if (permissionRows.isNotEmpty) {
      permissionRows.removeLast();
    }

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
            // Roles Header
            Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 24, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Roles",
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
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSettingField(
              icon: Icons.person,
              label: "Select Role",
              hint: "Select Role",
              items: roleItems,
            ),
            const SizedBox(height: 20),
            Text(
              "Permissions overview for this role",
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 20),
            ...permissionRows,
          ],
        ),
      ),
    );
  }
}
