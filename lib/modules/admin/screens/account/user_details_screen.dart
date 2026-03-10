import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final String id;

  const AdminUserDetailsScreen({super.key, required this.id});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  AdminUserDetails? _details;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;

  ApiClient? _apiClient;
  AdminUsersRepository? _repo;

  AdminUsersRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminUsersRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _token?.cancel('User details disposed');
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDetails() async {
    _token?.cancel('Reload user details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getUserDetails(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (details) {
          setState(() {
            _details = details;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          setState(() {
            _details = null;
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load user details.'
              : "Couldn't load user details.";
          _showErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = null;
        _loading = false;
      });
      _showErrorOnce("Couldn't load user details.");
    }
  }

  String _safe(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    return trimmed;
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('verify')) return Colors.green.withOpacity(0.2);
    if (s.contains('pending')) return Colors.orange.withOpacity(0.2);
    if (s.contains('disable') || s.contains('inactive')) {
      return Colors.red.withOpacity(0.2);
    }
    return Colors.blue.withOpacity(0.15);
  }

  Color _statusTextColor(String status, ColorScheme cs) {
    final s = status.toLowerCase();
    if (s.contains('verify')) return Colors.green;
    if (s.contains('pending')) return Colors.orange;
    if (s.contains('disable') || s.contains('inactive')) return Colors.red;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w);
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final bodyFs = titleFs - 1;
    final smallFs = titleFs - 3;

    final details = _details;
    final initials = _safe(details?.summary.initials ?? '--');
    final name = _safe(details?.fullName ?? '');
    final status = _safe(details?.statusLabel ?? '');
    final email = _safe(details?.email ?? '');
    final phone = _safe(details?.fullPhone ?? '');
    final joined = _safe(details?.joinedAt ?? '');
    final location = _safe(details?.location ?? '');
    final vehicles = details?.vehiclesCount;
    final vehiclesText = vehicles == null ? '—' : '$vehicles';
    final role = _safe(details?.summary.roleLabel ?? '');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'User',
          style: GoogleFonts.inter(
            fontSize: titleFs,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              context: context,
              child: _loading
                  ? _buildHeaderShimmer(padding)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: cs.primary,
                              child: Text(
                                initials,
                                style: GoogleFonts.inter(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: titleFs,
                                ),
                              ),
                            ),
                            SizedBox(width: padding),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: titleFs + 1,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusBgColor(status),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.inter(
                                            fontSize: smallFs,
                                            fontWeight: FontWeight.w600,
                                            color: _statusTextColor(status, cs),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.mail,
                                        size: titleFs + 1,
                                        color: cs.primary.withOpacity(0.87),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.phone,
                                        size: titleFs + 1,
                                        color: cs.primary.withOpacity(0.87),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          phone,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            color: cs.onSurface,
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
                      ],
                    ),
            ),
            SizedBox(height: padding),
            _buildCard(
              context: context,
              child: _loading
                  ? _buildInfoShimmer()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Joined', joined, cs, bodyFs),
                        const SizedBox(height: 10),
                        _infoRow('Location', location, cs, bodyFs),
                        const SizedBox(height: 10),
                        _infoRow('Vehicles', vehiclesText, cs, bodyFs),
                        const SizedBox(height: 10),
                        _infoRow('Role/Department', role, cs, bodyFs),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderShimmer(double padding) {
    return Row(
      children: [
        const AppShimmer(width: 56, height: 56, radius: 28),
        SizedBox(width: padding),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmer(width: 170, height: 18, radius: 8),
              SizedBox(height: 10),
              AppShimmer(width: 220, height: 14, radius: 8),
              SizedBox(height: 8),
              AppShimmer(width: 170, height: 14, radius: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoShimmer() {
    return const Column(
      children: [
        AppShimmer(width: double.infinity, height: 14, radius: 8),
        SizedBox(height: 12),
        AppShimmer(width: double.infinity, height: 14, radius: 8),
        SizedBox(height: 12),
        AppShimmer(width: double.infinity, height: 14, radius: 8),
        SizedBox(height: 12),
        AppShimmer(width: double.infinity, height: 14, radius: 8),
      ],
    );
  }

  Widget _infoRow(String label, String value, ColorScheme cs, double bodyFs) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: bodyFs,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: bodyFs, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
