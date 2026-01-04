/*
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlng;

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  String selectedTab = "Geofences";
  final TextEditingController _searchController = TextEditingController();

  int selectedIndex = 0; // Default to Main Office Perimeter

  final List<_GeofenceData> geofenceItems = [
    _GeofenceData(
      icon: CupertinoIcons.circle,
      title: "Main Office Perimeter",
      subtitle: "CIRCLE • 50m tolerance • 229m radius",
    ),
    _GeofenceData(
      icon: CupertinoIcons.crop,
      title: "Warehouse District",
      subtitle: "POLYGON • 25m tolerance",
    ),
    _GeofenceData(
      icon: CupertinoIcons.shopping_cart,
      title: "Shopping Mall Area",
      subtitle: "POLYGON",
    ),
    _GeofenceData(
      icon: Icons.show_chart,
      title: "Highway Corridor",
      subtitle: "LINE • 100m tolerance",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double iconSize = titleFs + 2;

    // Adaptive grid settings
    final int crossAxisCount = width > 600 ? 2 : 1;
    final double childAspectRatio = width > 600 ? 2.5 : 4.5;

    // Map data based on selected geofence
    final selectedItem = geofenceItems[selectedIndex];

    late latlng.LatLng mapCenter;
    late double mapZoom;
    final List<CircleMarker> circles = [];
    final List<Polygon> polygons = [];
    final List<Polyline> polylines = [];
    final List<Marker> markers = [];

    final Color fillColor = colorScheme.primary.withOpacity(0.2);
    final Color borderColor = colorScheme.primary;

    if (selectedIndex == 0) {
      // Main Office - Circle
      mapCenter = const latlng.LatLng(37.7749, -122.4194); // San Francisco
      mapZoom = 15.5;
      circles.addAll([
        CircleMarker(
          point: mapCenter,
          radius: 229,
          useRadiusInMeter: true,
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: 4,
        ),
        // Tolerance ring (outer)
        CircleMarker(
          point: mapCenter,
          radius: 279, // 229 + 50m tolerance
          useRadiusInMeter: true,
          color: Colors.transparent,
          borderColor: borderColor.withOpacity(0.5),
          borderStrokeWidth: 2,
        ),
      ]);
    } else if (selectedIndex == 1) {
      // Warehouse District - Polygon
      mapCenter = const latlng.LatLng(37.8044, -122.2711); // Oakland area
      mapZoom = 14.0;
      final List<latlng.LatLng> points = [
        latlng.LatLng(mapCenter.latitude + 0.008, mapCenter.longitude - 0.008),
        latlng.LatLng(mapCenter.latitude + 0.008, mapCenter.longitude + 0.012),
        latlng.LatLng(mapCenter.latitude - 0.008, mapCenter.longitude + 0.012),
        latlng.LatLng(mapCenter.latitude - 0.008, mapCenter.longitude - 0.008),
        latlng.LatLng(mapCenter.latitude + 0.008, mapCenter.longitude - 0.008),
      ];
      polygons.add(Polygon(
        points: points,
        color: fillColor,
        borderColor: borderColor,
        borderStrokeWidth: 4,
        // Note: some flutter_map versions removed the 'isFilled' parameter from Polygon.
      ));
    } else if (selectedIndex == 2) {
      // Shopping Mall Area - Polygon (render as small markers for broad compatibility)
      mapCenter = const latlng.LatLng(37.3382, -121.8863); // San Jose area
      mapZoom = 13.5;
      final List<latlng.LatLng> points = [
        latlng.LatLng(mapCenter.latitude + 0.012, mapCenter.longitude - 0.015),
        latlng.LatLng(mapCenter.latitude + 0.012, mapCenter.longitude + 0.020),
        latlng.LatLng(mapCenter.latitude - 0.012, mapCenter.longitude + 0.020),
        latlng.LatLng(mapCenter.latitude - 0.012, mapCenter.longitude - 0.015),
        latlng.LatLng(mapCenter.latitude + 0.012, mapCenter.longitude - 0.015),
      ];
      // Some flutter_map versions changed the Polygon API; to avoid breaking changes,
      // represent polygon vertices as small markers so the preview still indicates the area.
      for (final p in points) {
        markers.add(Marker(
          point: p,
          width: 12,
          height: 12,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
          ),
        ));
      }
    } else if (selectedIndex == 3) {
      // Highway Corridor - Line
      mapCenter = const latlng.LatLng(37.7749, -122.4194);
      mapZoom = 11.5;
      polylines.add(Polyline(
        points: [
          const latlng.LatLng(37.6000, -122.5000),
          const latlng.LatLng(37.9500, -122.3000),
        ],
        color: borderColor,
        strokeWidth: 6,
      ));
    }

    // Central marker for all types
    markers.add(Marker(
      point: mapCenter,
      width: 40,
      height: 40,
      child: Icon(
        Icons.location_on,
        color: Theme.of(context).colorScheme.primary,
        size: 40,
      ),
    ));

    // Provide a simple, stable preview widget instead of directly depending on
    // flutter_map internals that may have changed between package versions.
    final Widget mapPreview = Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, size: 48, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              selectedItem.title,
              style: GoogleFonts.inter(
                fontSize: titleFs,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedItem.subtitle,
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );

    return AppLayout(
      title: 'USER',
      subtitle: 'MAP',
      leftAvatarText: 'mp',
      showAppBar: false,
      horizontalPadding: 5,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TABS
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["Geofences", "POI", "Routes"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),

            SizedBox(height: hp * 2),

            // SEARCH BAR
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search model, IMEI, VIN, user...",
                  hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6), fontSize: bodyFs),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.primary.withOpacity(0.7)),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent, width: 0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: hp, vertical: hp),
                ),
              ),
            ),

            SizedBox(height: hp),

            // MAIN CONTAINER WITH LIST + MAP PREVIEW
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: geofenceItems.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    final item = geofenceItems[index];
                    return GeofenceListTile(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      isSelected: index == selectedIndex,
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Map Preview: ${selectedItem.title}',
                  style: GoogleFonts.inter(
                    fontSize: titleFs,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mapPreview,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GeofenceData {
  final IconData icon;
  final String title;
  final String subtitle;

  _GeofenceData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  }

class GeofenceListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const GeofenceListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    final double iconContainerSize = AdaptiveUtils.getAvatarSize(width) * 1.1;
    final double innerIconSize = AdaptiveUtils.getIconSize(width);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.05) : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.05),
          width: isSelected ? 2 : 1,
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
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AdaptiveUtils.getHorizontalPadding(width) * 1.2, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: iconContainerSize,
                  width: iconContainerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: innerIconSize - 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) - 1,
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/material.dart';

class GeofenceScreen extends StatelessWidget {
  const GeofenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(title: 'title', showAppBar: false, subtitle: 'subtitle', child: const Center(child: Text("Geofence Screen")), leftAvatarText: 'leftAvatarText');
  }
}