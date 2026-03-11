import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/models/user_driver_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverDetailsScreen extends StatefulWidget {
  final String driverId;
  final AdminDriverListItem? initialDriver;

  const DriverDetailsScreen({
    super.key,
    required this.driverId,
    this.initialDriver,
  });

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  // Confirmed User endpoint:
  // - GET /user/drivers/:id
  // Key mapping handled:
  // - data.data
  // - data.driver
  // - root driver map
  UserDriverDetails? _details;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;

  ApiClient? _apiClient;
  UserDriversRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _token?.cancel('User driver details disposed');
    super.dispose();
  }

  UserDriversRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserDriversRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadDetails() async {
    _token?.cancel('Reload user driver details');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getDriverDetails(
      widget.driverId,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (details) {
        setState(() {
          _details = details;
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
            : "Couldn't load driver details.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  String _safe(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '—';
    return text;
  }

  String _formatDateTime(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _displayName() {
    final details = _details;
    if (details != null) return _safe(details.fullName);
    return _safe(widget.initialDriver?.fullName);
  }

  String _displayStatus() {
    final details = _details;
    if (details != null) return _safe(details.statusLabel);
    return _safe(widget.initialDriver?.statusLabel);
  }

  Color _statusColor(ColorScheme cs) {
    final status = _displayStatus().toLowerCase();
    if (status.contains('active')) return Colors.green;
    if (status.contains('pending')) return Colors.orange;
    if (status.contains('inactive') || status.contains('disable')) {
      return Colors.red;
    }
    return cs.onSurface.withValues(alpha: 0.75);
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: AdaptiveUtils.getSubtitleFontSize(w) - 2,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: hp * 0.7),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final fs = AdaptiveUtils.getTitleFontSize(w);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: fs,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: fs,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: AppShimmer(width: double.infinity, height: 18, radius: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final details = _details;
    final initials = _safe(details?.initials ?? widget.initialDriver?.initials);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Driver Details',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: spacing * 1.2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(hp),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AdaptiveUtils.getAvatarSize(w) / 2,
                      backgroundColor: cs.primary,
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: AdaptiveUtils.getFsAvatarFontSize(w),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _loading
                              ? const AppShimmer(
                                  width: 180,
                                  height: 20,
                                  radius: 8,
                                )
                              : Text(
                                  _displayName(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(w) -
                                        1,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                          const SizedBox(height: 8),
                          _loading
                              ? const AppShimmer(
                                  width: 160,
                                  height: 14,
                                  radius: 8,
                                )
                              : Text(
                                  _safe(
                                    details?.username ??
                                        widget.initialDriver?.username,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                                    color: cs.onSurface.withValues(alpha: 0.68),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _loading
                        ? const AppShimmer(width: 82, height: 28, radius: 14)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(cs).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _displayStatus(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: _statusColor(cs),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              SizedBox(height: spacing * 1.4),
              _section(
                context,
                title: 'Profile',
                children: _loading
                    ? [
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                      ]
                    : [
                        _row(context, 'Email', _safe(details?.email)),
                        _row(
                          context,
                          'Phone',
                          _safe(
                            details?.fullPhone.isNotEmpty == true
                                ? details?.fullPhone
                                : '${details?.mobileCode ?? ''} ${details?.mobileNumber ?? ''}',
                          ),
                        ),
                        _row(
                          context,
                          'Verified',
                          details?.isVerified == true ? 'Yes' : 'No',
                        ),
                        _row(
                          context,
                          'Created',
                          _formatDateTime(details?.createdAtLabel),
                        ),
                        _row(
                          context,
                          'Driver Vehicle',
                          _safe(details?.driverVehicleLabel),
                        ),
                      ],
              ),
              SizedBox(height: spacing * 1.4),
              _section(
                context,
                title: 'Address',
                children: _loading
                    ? [
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                        _shimmerRow(),
                      ]
                    : [
                        _row(
                          context,
                          'Full Address',
                          _safe(details?.fullAddress),
                        ),
                        _row(context, 'Country', _safe(details?.countryCode)),
                        _row(context, 'State', _safe(details?.stateCode)),
                        _row(context, 'City', _safe(details?.cityId)),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
