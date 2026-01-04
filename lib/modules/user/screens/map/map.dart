import 'dart:ui';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../layout/app_layout.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();

  bool _showSearch = false;

  // ---- MAP STATE ----
  final LatLng _initialCenter = LatLng(6.5244, 3.3792);
  late LatLng _currentCenter;
  double _currentZoom = 13.0;

  // ---- CONTROL STATE ----
  String _mapMode = "live"; // live | history | playback
  String _mapType = "standard"; // standard | satellite
  bool _trafficEnabled = false;
  bool _controlPanelExpanded = false;

  final ExpansionTileController _mapModeController = ExpansionTileController();
  final ExpansionTileController _mapTypeController = ExpansionTileController();

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialCenter;
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_currentCenter, newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _openSearch() => setState(() => _showSearch = true);

  void _closeSearch() {
    setState(() => _showSearch = false);
    _searchController.clear();
  }

  void _closeControlPanel() {
    _mapModeController.collapse();
    _mapTypeController.collapse();
    setState(() => _controlPanelExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    final bottomBarHeight = AdaptiveUtils.getBottomBarHeight(screenWidth);
    final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final bottomMargin =
        MediaQuery.of(context).padding.bottom + bottomBarHeight + 50;

    return AppLayout(
      title: "MAP",
      subtitle: "Vehicle Locations",
      actionIcons: const [],
      leftAvatarText: "MP",
      showAppBar: false,
      horizontalPadding: 0,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // ================= MAP =================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _currentZoom,
                minZoom: 3,
                maxZoom: 18,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.all),
                onPositionChanged: (camera, _) {
                  _currentCenter = camera.center;
                  _currentZoom = camera.zoom;
                  if (mounted) setState(() {});
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapType == "satellite"
                      ? "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png"
                      : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _initialCenter,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ================= LEFT ACTION BUTTONS =================
            Positioned(
              left: 16,
              bottom: bottomMargin + 10,
              child: Column(
                children: [
                  _fab(
                    hero: "search",
                    icon: Icons.search,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: _openSearch,
                  ),
                  const SizedBox(height: 12),
                  _fab(
                    hero: "zoom_in",
                    icon: Icons.add,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 12),
                  _fab(
                    hero: "zoom_out",
                    icon: Icons.remove,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: _zoomOut,
                  ),
                ],
              ),
            ),

            // ================= RIGHT CONTROL PANEL =================
            Positioned(
              right: 16,
              top: 40 ,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_controlPanelExpanded) _controlContainer(cs),
                  if (_controlPanelExpanded) const SizedBox(height: 12),
                  _fab(
                    hero: "controls",
                    icon: Icons.tune,
                    size: fabSize,
                    iconSize: iconSize,
                    onTap: () => setState(() => _controlPanelExpanded = !_controlPanelExpanded),
                  ),
                ],
              ),
            ),

            // ================= SEARCH BAR =================
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              top: _showSearch ? 10 : -120,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: cs.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: cs.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: "Search location",
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _closeSearch(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _closeSearch,
                            child: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _fab({
    required String hero,
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: hero,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: onTap,
        child: Icon(icon, size: iconSize),
      ),
    );
  }

  Widget _controlContainer(ColorScheme cs) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitleWithIcon(Icons.map, "Map Controls"),
                GestureDetector(
                  onTap: _closeControlPanel,
                  child: Icon(Icons.close, size: 20, color: cs.onSurface),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpansionTile(
                  controller: _mapModeController,
                  title: _sectionTitleWithIcon(Icons.location_on, "Map Mode"),
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    _radio(
                      "Live Tracking",
                      "live",
                      _mapMode,
                      (v) => setState(() => _mapMode = v),
                      icon: Icons.gps_fixed,
                    ),
                    _radio(
                      "History",
                      "history",
                      _mapMode,
                      (v) => setState(() => _mapMode = v),
                      icon: Icons.history,
                    ),
                    _radio(
                      "Playback",
                      "playback",
                      _mapMode,
                      (v) => setState(() => _mapMode = v),
                      icon: Icons.play_arrow,
                    ),
                  ],
                ),
                ExpansionTile(
                  controller: _mapTypeController,
                  title: _sectionTitleWithIcon(Icons.layers, "Map Type"),
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: [
                    _radio(
                      "Standard",
                      "standard",
                      _mapType,
                      (v) => setState(() => _mapType = v),
                      icon: Icons.map,
                    ),
                    _radio(
                      "Satellite",
                      "satellite",
                      _mapType,
                      (v) => setState(() => _mapType = v),
                      icon: Icons.satellite_alt,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitleWithIcon(Icons.traffic, "Traffic"),
                    Switch(
                      value: _trafficEnabled,
                      activeColor: cs.primary,
                      onChanged: (v) {
                        setState(() => _trafficEnabled = v);
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitleWithIcon(IconData icon, String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: textSize + 4, color: cs.onSurface.withOpacity(0.9)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: textSize,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _radio(
    String label,
    String value,
    String group,
    ValueChanged<String> onTap, {
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final active = value == group;
    final screenWidth = MediaQuery.of(context).size.width;
    final textSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);

    final double radioSize = 18;
    final double iconSize = (textSize + 2).clamp(12.0, 20.0);

    return InkWell(
      onTap: () => onTap(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: active ? cs.primary : cs.onSurface.withOpacity(0.8)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? cs.primary : cs.onSurface,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: textSize - 2,
                ),
              ),
            ),
            _buildCircularRadio(active, cs.primary, radioSize),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularRadio(bool active, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? color : Colors.grey.withOpacity(0.5),
          width: 1.6,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: active ? size * 0.55 : 0,
          height: active ? size * 0.55 : 0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.transparent,
          ),
        ),
      ),
    );
  }
}