import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_landmarks_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class RouteLocationPreset {
  final String id;
  final String type; // poi | geofence
  final String title;
  final String subtitle;
  final double lat;
  final double lng;
  final String? color;
  final String? iconSlug;

  const RouteLocationPreset({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
    this.color,
    this.iconSlug,
  });
}

class AddLandmarkScreen extends StatefulWidget {
  final LatLng? initialPoint;

  const AddLandmarkScreen({super.key, this.initialPoint});

  @override
  State<AddLandmarkScreen> createState() => _AddLandmarkScreenState();
}

class _AddLandmarkScreenState extends State<AddLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<IconData> _iconOptions = [
    Icons.location_on,
    Icons.place,
    Icons.flag,
    Icons.home,
    Icons.store,
    Icons.star,
  ];

  IconData _selectedIcon = Icons.location_on;
  RouteLocationPreset? _selectedPreset;

  final List<RouteLocationPreset> _presets = [];
  bool _loadingPresets = false;
  String? _presetError;
  ApiClient? _api;
  UserLandmarksRepository? _repo;
  CancelToken? _loadToken;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loadToken?.cancel('Add landmark disposed');
    super.dispose();
  }

  ApiClient _apiOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _api!;
  }

  UserLandmarksRepository _repoOrCreate() {
    _repo ??= UserLandmarksRepository(api: _apiOrCreate());
    return _repo!;
  }

  Future<void> _loadSavedLocations() async {
    _loadToken?.cancel('Reload saved locations');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() {
      _loadingPresets = true;
      _presetError = null;
    });

    final repo = _repoOrCreate();
    final results = await Future.wait([
      repo.getPois(cancelToken: token),
      repo.getGeofences(cancelToken: token),
    ]);
    if (!mounted || token.isCancelled) return;

    final next = <RouteLocationPreset>[];
    String? error;

    final poisRes = results[0];
    final geofencesRes = results[1];

    poisRes.when(
      success: (items) {
        next.addAll(items.map(_poiToPreset).whereType<RouteLocationPreset>());
      },
      failure: (err) {
        error ??= _formatError(err, "Couldn't load POIs.");
      },
    );

    geofencesRes.when(
      success: (items) {
        next.addAll(
          items.map(_geofenceToPreset).whereType<RouteLocationPreset>(),
        );
      },
      failure: (err) {
        error ??= _formatError(err, "Couldn't load geofences.");
      },
    );

    if (!mounted) return;
    setState(() {
      _presets
        ..clear()
        ..addAll(next);
      _loadingPresets = false;
      _presetError = error;
    });

    _applyInitialSelectionIfPossible();
  }

  String _formatError(Object err, String fallback) {
    if (err is ApiException && err.message.trim().isNotEmpty) {
      return err.message.trim();
    }
    return fallback;
  }

  void _applyInitialSelectionIfPossible() {
    final initial = widget.initialPoint;
    if (initial == null || _selectedPreset != null || _presets.isEmpty) return;
    for (final preset in _presets) {
      if ((preset.lat - initial.latitude).abs() < 0.001 &&
          (preset.lng - initial.longitude).abs() < 0.001) {
        _selectPreset(preset, autoFillLabel: true);
        break;
      }
    }
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _subtitleForPoi(Map<String, dynamic> poi) {
    final category = (poi['category'] ?? '').toString().trim();
    final tolerance = _asDouble(poi['toleranceMeters'] ?? poi['tolerance_meters']);
    final parts = <String>[];
    if (category.isNotEmpty) parts.add(category);
    if (tolerance != null) parts.add('Tolerance ${tolerance.round()} m');
    return parts.join(' · ');
  }

  String _subtitleForGeofence(Map<String, dynamic> g) {
    final type = (g['type'] ?? g['geodata']?['kind'] ?? '').toString().trim();
    final radius = _asDouble(g['radius'] ?? g['geodata']?['radiusM']);
    final tolerance =
        _asDouble(g['toleranceMeters'] ?? g['tolerance_meters'] ?? g['geodata']?['toleranceM']);
    final normalized = _friendlyType(type);
    final parts = <String>[normalized];
    if (radius != null) {
      parts.add('Radius ${radius.round()} m');
    } else if (tolerance != null) {
      parts.add('Tolerance ${tolerance.round()} m');
    }
    return parts.join(' · ');
  }

  String _friendlyType(String raw) {
    final value = raw.trim().toUpperCase();
    switch (value) {
      case 'CIRCLE':
        return 'Circle';
      case 'LINE':
        return 'Line';
      case 'POLYGON':
        return 'Polygon';
      case 'RECTANGLE':
        return 'Rectangle';
      default:
        return value.isEmpty ? 'Geofence' : value[0] + value.substring(1).toLowerCase();
    }
  }

  List<double>? _pairToLatLng(dynamic pair) {
    if (pair is List && pair.length >= 2) {
      final lng = _asDouble(pair[0]);
      final lat = _asDouble(pair[1]);
      if (lat != null && lng != null) return [lat, lng];
    }
    return null;
  }

  RouteLocationPreset? _poiToPreset(Map<String, dynamic> poi) {
    final active = poi['isActive'];
    if (active is bool && !active) return null;

    final coords = poi['coordinates'];
    final lat = _asDouble(coords is Map ? coords['lat'] : null);
    final lng = _asDouble(coords is Map ? coords['lon'] ?? coords['lng'] : null);
    if (lat == null || lng == null) return null;

    final title = (poi['name'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    return RouteLocationPreset(
      id: 'poi-${poi['id'] ?? title}',
      type: 'poi',
      title: title,
      subtitle: _subtitleForPoi(poi),
      lat: lat,
      lng: lng,
      color: poi['color']?.toString(),
      iconSlug: poi['iconSlug']?.toString(),
    );
  }

  RouteLocationPreset? _geofenceToPreset(Map<String, dynamic> g) {
    final active = g['isActive'];
    if (active is bool && !active) return null;

    final title = (g['name'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final geodata = g['geodata'];
    double? lat;
    double? lng;

    if (geodata is Map) {
      final center = geodata['center'];
      if (center is Map) {
        lat = _asDouble(center['lat']);
        lng = _asDouble(center['lon'] ?? center['lng']);
      }

      if ((lat == null || lng == null) && geodata['geometry'] is Map) {
        final coords = geodata['geometry']['coordinates'];
        final points = <List<double>>[];
        if (coords is List) {
          void collect(dynamic node) {
            if (node is List && node.isNotEmpty) {
              if (node.first is num && node.length >= 2) {
                final pair = _pairToLatLng(node);
                if (pair != null) {
                  points.add(pair);
                }
              } else {
                for (final child in node) {
                  collect(child);
                }
              }
            }
          }

          collect(coords);
        }

        if (points.isNotEmpty) {
          final avgLat = points.map((p) => p[0]).reduce((a, b) => a + b) / points.length;
          final avgLng = points.map((p) => p[1]).reduce((a, b) => a + b) / points.length;
          lat = avgLat;
          lng = avgLng;
        }
      }
    }

    final type = (g['type'] ?? geodata?['kind'] ?? '').toString().trim().toUpperCase();
    if (type == 'LINE' && geodata is Map && geodata['geometry'] is Map) {
      final coords = geodata['geometry']['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        final first = _pairToLatLng(coords.first);
        if (first != null) {
          lat ??= first[0];
          lng ??= first[1];
        }
      }
    }

    if (lat == null || lng == null) return null;

    return RouteLocationPreset(
      id: 'geofence-${g['id'] ?? title}',
      type: 'geofence',
      title: title,
      subtitle: _subtitleForGeofence(g),
      lat: lat,
      lng: lng,
      color: g['color']?.toString(),
    );
  }

  void _selectPreset(RouteLocationPreset preset, {bool autoFillLabel = false}) {
    setState(() => _selectedPreset = preset);
    if (autoFillLabel && _nameController.text.trim().isEmpty) {
      _nameController.text = preset.title;
    }
  }

  Future<void> _openPresetPicker() async {
    if (_loadingPresets && _presets.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<RouteLocationPreset>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _RouteLocationPickerSheet(
          presets: List<RouteLocationPreset>.from(_presets),
          loading: _loadingPresets,
          errorMessage: _presetError,
          onRetry: _loadSavedLocations,
        );
      },
    );

    if (!mounted || selected == null) return;
    _selectPreset(selected, autoFillLabel: true);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final selected = _selectedPreset;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a saved location')),
      );
      return;
    }

    Navigator.pop(context, {
      'label': _nameController.text.trim(),
      'lat': selected.lat,
      'lng': selected.lng,
      'icon': _selectedIcon,
    });
  }

  Widget _buildSelectedPresetTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = _selectedPreset?.title;
    final subtitle = _selectedPreset?.subtitle ?? 'POIs and geofences from your account';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _loadingPresets && _presets.isEmpty ? null : _openPresetPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _selectedPreset?.type == 'geofence'
                    ? Icons.layers_outlined
                    : Icons.location_on_rounded,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? (_loadingPresets ? 'Loading locations...' : 'Choose location (lat/lng presets)'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w);
    final fontSize = AdaptiveUtils.getTitleFontSize(w);

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
                    'Add Landmark',
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
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'Label',
                          prefixIcon: Icons.label,
                          fontSize: fontSize,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a label';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSelectedPresetTile(context),
                        if (_presetError != null && _presets.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Unable to load saved locations',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.error,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadSavedLocations,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Icon',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: _iconOptions.map((icon) {
                                final sel = icon == _selectedIcon;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedIcon = icon),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: sel ? cs.primary : cs.surface,
                                      border: Border.all(
                                        color: cs.outline.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: sel ? cs.onPrimary : cs.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  foregroundColor: cs.primary,
                                  side: BorderSide(color: cs.primary),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_loadingPresets && _presets.isEmpty)
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                ),
                                child: const Text('Add Landmark'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLocationPickerSheet extends StatefulWidget {
  final List<RouteLocationPreset> presets;
  final bool loading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  const _RouteLocationPickerSheet({
    required this.presets,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  State<_RouteLocationPickerSheet> createState() => _RouteLocationPickerSheetState();
}

class _RouteLocationPickerSheetState extends State<_RouteLocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RouteLocationPreset> get _filteredPresets {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.presets;
    return widget.presets.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.subtitle.toLowerCase().contains(q) ||
          p.type.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildSheetCard(BuildContext context, RouteLocationPreset preset) {
    final cs = Theme.of(context).colorScheme;
    final icon = preset.type == 'poi'
        ? _iconForPoi(preset)
        : _iconForGeofence(preset);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pop(context, preset),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: preset.type == 'poi'
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: preset.type == 'poi' ? cs.primary : Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPoi(RouteLocationPreset preset) {
    final slug = (preset.iconSlug ?? '').trim().toLowerCase();
    final subtitle = preset.subtitle.toLowerCase();
    if (slug.contains('flag') || subtitle.contains('yard')) return Icons.flag_rounded;
    if (slug.contains('home') || subtitle.contains('home')) return Icons.home_rounded;
    if (slug.contains('store') || subtitle.contains('shop')) return Icons.store_rounded;
    if (slug.contains('star')) return Icons.star_rounded;
    return Icons.location_on_rounded;
  }

  IconData _iconForGeofence(RouteLocationPreset preset) {
    final type = preset.subtitle.toUpperCase();
    if (type.contains('CIRCLE')) return Icons.circle_outlined;
    if (type.contains('LINE')) return Icons.timeline_rounded;
    if (type.contains('POLYGON')) return Icons.polyline_rounded;
    if (type.contains('RECTANGLE')) return Icons.crop_square_rounded;
    return Icons.map_outlined;
  }

  Widget _buildLoadingPlaceholder() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: const AppShimmer(width: double.infinity, height: 72, radius: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groupedPois = _filteredPresets.where((p) => p.type == 'poi').toList();
    final groupedGeofences =
        _filteredPresets.where((p) => p.type == 'geofence').toList();
    final hasItems = groupedPois.isNotEmpty || groupedGeofences.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search saved locations',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              if (widget.loading && widget.presets.isEmpty)
                Expanded(child: Padding(padding: const EdgeInsets.all(16), child: _buildLoadingPlaceholder()))
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (widget.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Unable to load saved locations',
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await widget.onRetry();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (groupedPois.isNotEmpty) ...[
                        Text(
                          'POIs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...groupedPois.map((preset) => _buildSheetCard(context, preset)),
                        const SizedBox(height: 16),
                      ],
                      if (groupedGeofences.isNotEmpty) ...[
                        Text(
                          'Geofences',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...groupedGeofences.map((preset) => _buildSheetCard(context, preset)),
                        const SizedBox(height: 16),
                      ],
                      if (!hasItems)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.loading
                                ? 'Loading saved locations...'
                                : 'No saved POIs or geofences found',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
