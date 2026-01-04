import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareTrackScreen extends StatefulWidget {
  const ShareTrackScreen({super.key});

  @override
  State<ShareTrackScreen> createState() => _ShareTrackScreenState();
}

class _ShareTrackScreenState extends State<ShareTrackScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> tracks = [
    {
      "name": "Agra Delivery – Morning Slot",
      "status": "Active",
      "vehicles_count": 3,
      "link": "trk.fleet.link/agra-morning",
      "expires": "03/01/2026, 14:39:35",
      "views": 48,
      "last_opened": "03/01/2026, 08:27:35",
      "vehicles": ["UP80AA1234", "UP80BB4567", "DL01C7788"],
    },
    {
      "name": "Vendor QA – One day",
      "status": "Scheduled",
      "vehicles_count": 1,
      "link": "trk.fleet.link/vendor-qa",
      "expires": "05/01/2026, 08:39:35",
      "views": 0,
      "last_opened": null,
      "vehicles": ["MH12Q9090"],
    },
    {
      "name": "Festival Rush – North Zone",
      "status": "Expired",
      "vehicles_count": 4,
      "link": "trk.fleet.link/north-rush",
      "expires": "03/01/2026, 05:39:35",
      "views": 311,
      "last_opened": "03/01/2026, 04:39:35",
      "vehicles": ["HR26D3344", "GJ01M6666", "RJ14P2211", "TN99Z0000"],
    },
    // Add more dummy tracks if needed
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isExpiringToday(String expires) {
    // Simple check assuming format DD/MM/YYYY, HH:MM:SS and current date 03/01/2026
    // In real app, parse to DateTime and compare DateTime.now()
    final datePart = expires.split(', ')[0];
    return datePart == "03/01/2026";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // --- ADAPTIVE VALUES ---
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8-16
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6-10
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth); // 13-15
    final bodyFs = titleFs - 1; // general text
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4; // slightly bigger for cards
    final searchQuery = _searchController.text.toLowerCase();

    var filteredTracks = tracks.where((track) {
      final matchesSearch = searchQuery.isEmpty ||
          track['name'].toString().toLowerCase().contains(searchQuery) ||
          track['status'].toString().toLowerCase().contains(searchQuery) ||
          track['link'].toString().toLowerCase().contains(searchQuery) ||
          track['vehicles'].toString().toLowerCase().contains(searchQuery);

      final matchesTab = selectedTab == "All" ||
          (selectedTab == "Active" && track['status'] == "Active") ||
          (selectedTab == "Expires Today" && _isExpiringToday(track['expires']));

      return matchesSearch && matchesTab;
    }).toList();

    return AppLayout(
      title: "USER",
      subtitle: "Share Track",
      showLeftAvatar: false,
      actionIcons: const [],
      onActionTaps: [],
      leftAvatarText: 'ST',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------
            // SEARCH FIELD
            // --------------------------------------------
            Container(
              height: padding * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search name, link, status...",
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize, color: colorScheme.primary),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.transparent, width: 0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: padding,
                  ),
                ),
              ),
            ),
            SizedBox(height: padding),
            // --------------------------------------------
            // TABS
            // --------------------------------------------
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ["All", "Active", "Expires Today"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            SizedBox(height: padding),
            // --------------------------------------------
            // TOP ROW: showing count + add track
            // --------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredTracks.length} of ${tracks.length} tracks",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                // ADD TRACK BUTTON
                GestureDetector(
                  onTap: () {
                    context.push('/user/share-track/add');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding * 1.5,
                      vertical: spacing,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
                    ),
                    child: Text(
                      "Add Track",
                      style: GoogleFonts.inter(
                        fontSize: bodyFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // --------------------------------------------
            // TRACK LIST
            // --------------------------------------------
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTracks.length,
              itemBuilder: (context, index) {
                final track = filteredTracks[index];
                final vehicles = track["vehicles"] as List<String>;
                final vehiclesDisplay = vehicles.length > 3
                    ? "${vehicles.sublist(0, 3).join(' ')} +${vehicles.length - 3} more"
                    : vehicles.join(' ');
                final isActive = track["status"] == "Active";
                final statusColor = track["status"] == "Active"
                    ? Colors.green
                    : track["status"] == "Scheduled"
                        ? Colors.orange
                        : Colors.red;
                return Container(
                  margin: EdgeInsets.only(bottom: padding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(25),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NAME + STATUS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    track["name"],
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 2,
                                    vertical: spacing - 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    track["status"],
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            // VEHICLES COUNT + LINK
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse('https://${track["link"]}');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              child: Text(
                                "${track["vehicles_count"]} vehicles • ${track["link"]}",
                                style: GoogleFonts.inter(
                                  fontSize: bodyFs,
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            SizedBox(height: spacing / 2),
                            // EXPIRES AND VIEWS IN ROW
                            Row(
                              children: [
                                // EXPIRES
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.calendar,
                                      size: iconSize * 0.8,
                                      color: colorScheme.primary.withOpacity(0.87),
                                    ),
                                    SizedBox(width: spacing / 2),
                                    Text(
                                      "Expires: ${track["expires"]}",
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: spacing + 5),
                                // VIEWS
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: iconSize * 0.8,
                                      color: colorScheme.primary.withOpacity(0.87),
                                    ),
                                    SizedBox(width: spacing / 2),
                                    Text(
                                      "Views: ${track["views"]}",
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: spacing / 2),
                            // LAST OPENED
                            if (track["last_opened"] != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: iconSize * 0.8,
                                    color: colorScheme.primary.withOpacity(0.87),
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    "Last opened: ${track["last_opened"]}",
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(height: spacing),
                            // VEHICLES
                            Text(
                              vehiclesDisplay,
                              style: GoogleFonts.inter(
                                fontSize: bodyFs,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: spacing * 2),
                            // ACTION ICONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: 'Copy Link',
                                  icon: Icon(Icons.content_copy, size: iconSize, color: colorScheme.primary),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: 'https://${track["link"]}'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Link copied to clipboard')),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'QR Code',
                                  icon: Icon(Icons.qr_code, size: iconSize, color: colorScheme.primary),
                                  onPressed: () {
                                    // Placeholder: Show QR dialog or something
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('QR Code functionality TBD')),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: isActive ? 'Pause' : 'Resume',
                                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: iconSize, color: colorScheme.primary),
                                  onPressed: () {
                                    // Placeholder: Toggle status
                                    setState(() {
                                      track["status"] = isActive ? "Paused" : "Active";
                                    });
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: Icon(Icons.edit, size: iconSize, color: colorScheme.primary),
                                  onPressed: () {
                                    // Placeholder: Navigate to edit
                                    context.push('/user/share-track/edit/${track["name"]}');
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: Icon(Icons.delete, size: iconSize, color: Colors.red),
                                  onPressed: () {
                                    // Placeholder: Confirm delete
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Delete functionality TBD')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: padding * 2),
          ],
        ),
      ),
    );
  }
}