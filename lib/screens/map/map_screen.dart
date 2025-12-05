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
        final fabSize = AdaptiveUtils.getButtonSize(screenWidth); // You can use this to adjust size
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);

           // Get the bottom padding + bottom bar height
final bottomMargin = MediaQuery.of(context).padding.bottom + height + 50;
    return AppLayout(
      title: "MAP",
      subtitle: "Vehicle Locations",
      actionIcons: const [],
      leftAvatarText: "MP",
      showAppBar: false,        // hide app bar
      horizontalPadding: 0.0,   // zero padding for full-screen map
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
                onPositionChanged: (MapCamera camera, bool hasGesture) {
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
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
 
// <-- 68 is your CustomBottomBar height (adjust if different)

Positioned(
  right: 16,
  bottom: bottomMargin, // now safe above bottom bar
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
       SizedBox(
          width: fabSize,
          height: fabSize,
          child: FloatingActionButton(
            heroTag: "map_search",
            backgroundColor: Colors.black,
            onPressed: _openSearch,
            child: Icon(Icons.search, color: Colors.white, size: iconSize),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: fabSize,
          height: fabSize,
          child: FloatingActionButton(
            heroTag: "map_zoom_in",
            backgroundColor: Colors.black,
            onPressed: _zoomIn,
            child: Icon(Icons.add, color: Colors.white, size: iconSize),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: fabSize,
          height: fabSize,
          child: FloatingActionButton(
            heroTag: "map_zoom_out",
            backgroundColor: Colors.black,
            onPressed: _zoomOut,
            child: Icon(Icons.remove, color: Colors.white, size: iconSize),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Zoom: ${_currentZoom.toStringAsFixed(1)}"),
              ),
            ),

            // ---------------- BLURRED TOP SEARCH BAR ----------------
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
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.black.withOpacity(0.7)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Search location",
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
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
                                color: Colors.black.withOpacity(0.1),
                              ),
                              child: const Icon(Icons.close, size: 18),
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
