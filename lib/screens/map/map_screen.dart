import 'dart:ui';
import 'package:fleet_stack/utils/adaptive_utils.dart';
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
  

  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
   // Adjust based on your CustomBottomBar height

  final LatLng _initialCenter = LatLng(6.5244, 3.3792);

  double _currentZoom = 13.0;
  late LatLng _currentCenter;

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

 @override
Widget build(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final double height = AdaptiveUtils.getBottomBarHeight(screenWidth);

  final fabSize = AdaptiveUtils.getButtonSize(screenWidth);
  final iconSize = AdaptiveUtils.getIconSize(screenWidth);

  final bottomMargin = MediaQuery.of(context).padding.bottom + height + 50;

  final cs = Theme.of(context).colorScheme; // <--- color scheme shortcut
  final brand = cs.primary;
  final onBrand = cs.onPrimary;

  return AppLayout(
    title: "MAP",
    subtitle: "Vehicle Locations",
    actionIcons: const [],
    leftAvatarText: "MP",
    showAppBar: false,
    horizontalPadding: 0.0,
    child: SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // ---------------- MAP ----------------
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _currentZoom,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.all),
              onTap: (tapPos, latlng) {
                debugPrint("Tapped: $latlng");
              },
              onPositionChanged: (camera, hasGesture) {
                _currentCenter = camera.center;
                _currentZoom = camera.zoom;
                if (mounted) setState(() {});
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                      color: brand, // <--- brand-based marker
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ---------------- ACTION BUTTONS ----------------
          Positioned(
            right: 16,
            bottom: bottomMargin,
            child: Column(
              children: [
                // Search FAB
                SizedBox(
                  width: fabSize,
                  height: fabSize,
                  child: FloatingActionButton(
                    heroTag: "map_search",
                    backgroundColor: brand,
                    foregroundColor: onBrand,
                    onPressed: _openSearch,
                    child: Icon(Icons.search, size: iconSize),
                  ),
                ),
                const SizedBox(height: 12),

                // Zoom In FAB
                SizedBox(
                  width: fabSize,
                  height: fabSize,
                  child: FloatingActionButton(
                    heroTag: "map_zoom_in",
                    backgroundColor: brand,
                    foregroundColor: onBrand,
                    onPressed: _zoomIn,
                    child: Icon(Icons.add, size: iconSize),
                  ),
                ),
                const SizedBox(height: 12),

                // Zoom Out FAB
                SizedBox(
                  width: fabSize,
                  height: fabSize,
                  child: FloatingActionButton(
                    heroTag: "map_zoom_out",
                    backgroundColor: brand,
                    foregroundColor: onBrand,
                    onPressed: _zoomOut,
                    child: Icon(Icons.remove, size: iconSize),
                  ),
                ),
              ],
            ),
          ),

          // ---------------- ZOOM DEBUG BOX ----------------
          Positioned(
            right: 16,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brand.withOpacity(0.3)), // active color
              ),
              child: Text(
                "Zoom: ${_currentZoom.toStringAsFixed(1)}",
                style: TextStyle(color: cs.onSurface),
              ),
            ),
          ),

          // ---------------- SEARCH BAR ----------------
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: _showSearch ? 10 : -120,
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
                      border: Border.all(color: brand.withOpacity(0.3)), // active brand border
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: cs.onSurface.withOpacity(0.7)),
                        const SizedBox(width: 10),
                        Expanded(
  child: TextField(
    controller: _searchController,
    autofocus: true,
    decoration: InputDecoration(
      hintText: "Search location",
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      hintStyle: TextStyle(
        color: cs.onSurface.withOpacity(0.5),
      ),
      isDense: true, // optional – reduces padding
      contentPadding: EdgeInsets.zero, // optional – tight layout
    ),
    style: TextStyle(color: cs.onSurface),
    onSubmitted: (q) {
      debugPrint("Searching: $q");
      _closeSearch();
    },
  ),
),

                        GestureDetector(
                          onTap: _closeSearch,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.onSurface.withOpacity(0.1),
                            ),
                            child: Icon(Icons.close,
                                size: 18, color: cs.onSurface),
                          ),
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
}