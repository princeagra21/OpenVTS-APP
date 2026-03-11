import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignDriverScreen extends StatefulWidget {
  final String? current;

  const AssignDriverScreen({super.key, this.current});

  @override
  State<AssignDriverScreen> createState() => _AssignDriverScreenState();
}

class _AssignDriverScreenState extends State<AssignDriverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? selected;
  List<AdminDriverListItem> _drivers = <AdminDriverListItem>[];
  bool _loading = false;
  bool _errorShown = false;

  ApiClient? _api;
  UserDriversRepository? _repo;
  CancelToken? _token;

  @override
  void initState() {
    super.initState();
    selected = widget.current;
    _searchController.addListener(() => setState(() {}));
    _loadDrivers();
  }

  @override
  void dispose() {
    _token?.cancel('Assign driver disposed');
    _searchController.dispose();
    super.dispose();
  }

  UserDriversRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserDriversRepository(api: _api!);
    return _repo!;
  }

  Future<void> _loadDrivers() async {
    _token?.cancel('Reload drivers for route assignment');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getDrivers(cancelToken: token);
      if (!mounted || token.isCancelled) return;
      res.when(
        success: (drivers) {
          setState(() {
            _drivers = drivers;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (error) {
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          var msg = "Couldn't load drivers.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load drivers.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w) * 1.5;
    final query = _searchController.text.trim().toLowerCase();

    final filteredDrivers = _drivers.where((d) {
      if (query.isEmpty) return true;
      return d.fullName.toLowerCase().contains(query) ||
          d.fullPhone.toLowerCase().contains(query) ||
          d.email.toLowerCase().contains(query);
    }).toList();

    final double iconContainerSize = AdaptiveUtils.getAvatarSize(w);
    final double innerIconSize = AdaptiveUtils.getIconSize(w) * 0.9;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign to Driver',
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
              const SizedBox(height: 20),
              CustomTextField(
                controller: _searchController,
                hintText: 'Search drivers',
                prefixIcon: Icons.search,
                fontSize: AdaptiveUtils.getTitleFontSize(w),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? ListView.separated(
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, __) => const AppShimmer(
                          width: double.infinity,
                          height: 92,
                          radius: 20,
                        ),
                      )
                    : filteredDrivers.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No drivers found',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add a driver first, then return to assign it to this route.',
                              style: GoogleFonts.inter(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          final isSelected = selected == driver.fullName;
                          final statusColor = driver.isActive
                              ? Colors.green
                              : Colors.red;
                          final location = driver.addressLocation.trim().isEmpty
                              ? driver.email
                              : driver.addressLocation;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.05),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    setState(() => selected = driver.fullName),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: hp * 0.8,
                                    vertical: hp * 0.4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: iconContainerSize,
                                        width: iconContainerSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cs.primary.withOpacity(0.1),
                                        ),
                                        child: Center(
                                          child: Text(
                                            driver.initials,
                                            style: TextStyle(
                                              fontSize: innerIconSize,
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              driver.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize:
                                                    AdaptiveUtils.getSubtitleFontSize(
                                                      w,
                                                    ) -
                                                    2,
                                                fontWeight: FontWeight.bold,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${driver.fullPhone} • $location',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize:
                                                    AdaptiveUtils.getTitleFontSize(
                                                      w,
                                                    ) -
                                                    2,
                                                color: cs.onSurface.withOpacity(
                                                  0.55,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              driver.statusLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : CupertinoIcons.chevron_forward,
                                        size:
                                            AdaptiveUtils.getIconSize(w) * 0.8,
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurface.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected != null
                          ? () => Navigator.pop(context, selected)
                          : null,
                      child: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
