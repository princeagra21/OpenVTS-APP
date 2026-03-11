import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_share_track_links_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareTrackAddScreen extends StatefulWidget {
  const ShareTrackAddScreen({super.key});

  @override
  State<ShareTrackAddScreen> createState() => _ShareTrackAddScreenState();
}

class _ShareTrackAddScreenState extends State<ShareTrackAddScreen> {
  // FleetStack-API-Reference.md confirmed:
  // - GET  /user/vehicles
  // - POST /user/sharetracklinks
  //
  // Confirmed create keys:
  // - MD:      { vehicleIds, expiryAt, isGeofence, isHistory }
  // - Postman: { vehicleId, expiresAt }
  //
  // API-backed create UI fields:
  // - Vehicles
  // - Expiry Date
  // - Expiry Time
  // - Enable Geofence
  // - Enable History
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _expiryTimeController = TextEditingController();

  ApiClient? _apiClient;
  UserShareTrackLinksRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _saveToken;

  bool geofence = false;
  bool history24h = false;
  bool _loadingVehicles = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  DateTime _selectedExpiry = DateTime.now().add(const Duration(days: 1));

  List<VehicleListItem> _availableVehicles = <VehicleListItem>[];
  List<VehicleListItem> selectedVehicles = <VehicleListItem>[];

  @override
  void initState() {
    super.initState();
    _syncExpiryControllers();
    _loadVehicles();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Share track add disposed');
    _saveToken?.cancel('Share track add disposed');
    _expiryDateController.dispose();
    _expiryTimeController.dispose();
    super.dispose();
  }

  UserShareTrackLinksRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserShareTrackLinksRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadVehicles() async {
    _loadToken?.cancel('Reload share track vehicles');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingVehicles = true);

    final result = await _repoOrCreate().getVehicles(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (items) {
        setState(() {
          _availableVehicles = items;
          _loadingVehicles = false;
          _loadErrorShown = false;
        });
      },
      failure: (error) {
        setState(() => _loadingVehicles = false);
        if (_isCancelled(error) || _loadErrorShown) return;
        _loadErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load vehicles.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  void _syncExpiryControllers() {
    String two(int value) => value.toString().padLeft(2, '0');
    _expiryDateController.text =
        '${_selectedExpiry.year}-${two(_selectedExpiry.month)}-${two(_selectedExpiry.day)}';
    _expiryTimeController.text =
        '${two(_selectedExpiry.hour)}:${two(_selectedExpiry.minute)}';
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedExpiry = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedExpiry.hour,
        _selectedExpiry.minute,
      );
      _syncExpiryControllers();
    });
  }

  Future<void> _pickExpiryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedExpiry),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedExpiry = DateTime(
        _selectedExpiry.year,
        _selectedExpiry.month,
        _selectedExpiry.day,
        picked.hour,
        picked.minute,
      );
      _syncExpiryControllers();
    });
  }

  Future<void> _createLink() async {
    if (_saving) return;
    final expiryIso = _selectedExpiry.toUtc().toIso8601String();

    if (selectedVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one vehicle')),
      );
      return;
    }

    _saveToken?.cancel('Restart share track create');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final result = await _repoOrCreate().createLink(
      vehicleIds: selectedVehicles.map((vehicle) => vehicle.id).toList(),
      expiryAtIso: expiryIso,
      isGeofence: geofence,
      isHistory: history24h,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (_) {
        setState(() {
          _saving = false;
          _saveErrorShown = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Share link created')));
        Navigator.pop(context, true);
      },
      failure: (error) {
        setState(() => _saving = false);
        if (_isCancelled(error) || _saveErrorShown) return;
        _saveErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't create share link.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Share Track',
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
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_loadingVehicles)
                          const AppShimmer(
                            width: double.infinity,
                            height: 56,
                            radius: 16,
                          )
                        else
                          CustomMultiDropdownField<VehicleListItem>(
                            value: selectedVehicles,
                            items: _availableVehicles,
                            hintText: _availableVehicles.isEmpty
                                ? 'No vehicles available'
                                : 'Select vehicles',
                            prefixIcon: Icons.directions_car,
                            onChanged: (v) =>
                                setState(() => selectedVehicles = v),
                            fontSize: fs,
                            itemLabelBuilder: (item) {
                              final plate = item.plateNumber.trim();
                              final name = item.name.trim();
                              return plate.isNotEmpty
                                  ? plate
                                  : (name.isNotEmpty ? name : item.id);
                            },
                          ),
                        const SizedBox(height: 16),
                        _PickerField(
                          controller: _expiryDateController,
                          label: 'Expiry Date',
                          icon: Icons.calendar_today,
                          fontSize: fs,
                          onTap: _pickExpiryDate,
                        ),
                        const SizedBox(height: 16),
                        _PickerField(
                          controller: _expiryTimeController,
                          label: 'Expiry Time',
                          icon: Icons.schedule,
                          fontSize: fs,
                          onTap: _pickExpiryTime,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Permissions',
                          style: GoogleFonts.inter(
                            fontSize: fs,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SwitchListTile(
                          title: Text(
                            'Geofence',
                            style: GoogleFonts.inter(fontSize: fs),
                          ),
                          value: geofence,
                          onChanged: (v) => setState(() => geofence = v),
                        ),
                        SwitchListTile(
                          title: Text(
                            'History last 24 hours',
                            style: GoogleFonts.inter(fontSize: fs),
                          ),
                          value: history24h,
                          onChanged: (v) => setState(() => history24h = v),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Links auto-expire and can be revoked anytime.',
                          style: GoogleFonts.inter(
                            fontSize: fs - 1,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: cs.primary.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_saving || _loadingVehicles)
                                    ? null
                                    : _createLink,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const AppShimmer(
                                        width: 56,
                                        height: 14,
                                        radius: 7,
                                      )
                                    : Text(
                                        'Create',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final double fontSize;
  final VoidCallback onTap;

  const _PickerField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(
              fontSize: fontSize - 1,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomMultiDropdownField<T> extends StatelessWidget {
  final List<T> value;
  final List<T> items;
  final String hintText;
  final IconData? prefixIcon;
  final Function(List<T>) onChanged;
  final double fontSize;
  final String Function(T)? itemLabelBuilder;

  const CustomMultiDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.hintText,
    this.prefixIcon,
    required this.onChanged,
    required this.fontSize,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayText = value.isEmpty
        ? hintText
        : 'Selected (${value.length}) vehicles';

    return GestureDetector(
      onTap: items.isEmpty
          ? null
          : () {
              showDialog(
                context: context,
                builder: (ctx) {
                  List<T> tempSelected = List.from(value);
                  return AlertDialog(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 20.0,
                    ),
                    titlePadding: const EdgeInsets.fromLTRB(
                      24.0,
                      24.0,
                      24.0,
                      0.0,
                    ),
                    actionsPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    title: Text(hintText),
                    content: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                        maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                      ),
                      child: SingleChildScrollView(
                        child: StatefulBuilder(
                          builder: (context, dialogSetState) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: items.map((item) {
                              return CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                title: Text(
                                  itemLabelBuilder != null
                                      ? itemLabelBuilder!(item)
                                      : item.toString(),
                                  style: GoogleFonts.inter(fontSize: fontSize),
                                ),
                                value: tempSelected.contains(item),
                                onChanged: (bool? checked) {
                                  dialogSetState(() {
                                    if (checked == true) {
                                      tempSelected.add(item);
                                    } else {
                                      tempSelected.remove(item);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          onChanged(tempSelected);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  );
                },
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: colorScheme.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: items.isEmpty
                      ? colorScheme.onSurface.withOpacity(0.5)
                      : colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
