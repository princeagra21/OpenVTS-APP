import 'package:fleet_stack/components/small_box/small_box.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> admins = List.generate(5, (i) => {
        "id": i,
        "initials": "MS",
        "name": "Muhammad Sani",
        "phone": "+2349018980920",
        "username": "@muhammad",
        "email": "muhammad@gmail.com",
        "status": i % 2 == 0 ? "Verified" : "Pending",
        "vehicles": "76",
        "credits": "18",
        "recentLogin": "Oct 12, 09:32",
        "active": true,
        "location": "Dawakin Tofa, Kano, Nigeria",
        "joined": "Aug 11, 2025 • 120d",
        "role": "Das Fleet Management • Primary",
      });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // --- ADAPTIVE VALUES ---
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8–16
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6–10
    final titleFs = AdaptiveUtils.getTitleFontSize(screenWidth); // 13–15
    final bodyFs = titleFs - 1; // general text
    final smallFs = titleFs - 3;
    final iconSize = titleFs + 2;
    final cardPadding = padding + 4; // slightly bigger for cards

    final filteredAdmins = admins;

    return AppLayout(
      title: "SUPER ADMIN",
      subtitle: "Administrators",
      actionIcons: const [
        CupertinoIcons.add,
      ],
      leftAvatarText: 'SA',
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
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: bodyFs),
                decoration: InputDecoration(
                  hintText: "Search name, email, role, department...",
                  hintStyle: GoogleFonts.inter(
                    color: Colors.black.withOpacity(0.5),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(CupertinoIcons.search, size: iconSize),
                  border: InputBorder.none,
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
              children: ["All", "Active", "Disabled", "Pending"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),

            SizedBox(height: padding),

            // --------------------------------------------
            // TOP ROW: showing count + export
            // --------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${filteredAdmins.length} of ${admins.length} admins",
                  style: GoogleFonts.inter(
                    fontSize: bodyFs,
                    color: Colors.black.withOpacity(0.87),
                  ),
                ),

                // EXPORT BUTTON
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 1.5,
                    vertical: spacing,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Text(
                    "Export",
                    style: GoogleFonts.inter(
                      fontSize: bodyFs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: spacing),

            // --------------------------------------------
            // ADMIN LIST
            // --------------------------------------------
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAdmins.length,
              itemBuilder: (context, index) {
                final admin = filteredAdmins[index];

                return Container(
                  margin: EdgeInsets.only(bottom: padding),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // AVATAR
                          CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2,
                            child: Text(
                              admin["initials"],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: AdaptiveUtils.getFsAvatarFontSize(screenWidth),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          SizedBox(width: spacing * 2),

                          // RIGHT SIDE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // NAME + STATUS + LOGIN
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        context.push("/admins/details/${admin['id']}");
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            admin["name"],
                                            style: GoogleFonts.inter(
                                              fontSize: bodyFs,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: spacing),

                                          // STATUS BADGE
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: spacing + 2,
                                              vertical: spacing - 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: admin["status"] == "Verified"
                                                  ? Colors.green.withOpacity(0.2)
                                                  : Colors.orange.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              admin["status"],
                                              style: GoogleFonts.inter(
                                                fontSize: smallFs,
                                                fontWeight: FontWeight.w600,
                                                color: admin["status"] == "Verified"
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // LOGIN BUTTON
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: padding + 4,
                                        vertical: spacing - 2,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.black.withOpacity(0.5),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        "Login",
                                        style: GoogleFonts.inter(
                                          fontSize: smallFs + 1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: spacing),

                                // PHONE
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.phone, size: iconSize),
                                    SizedBox(width: spacing),
                                    Text(
                                      admin["phone"],
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: spacing / 2),

                                // EMAIL
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.mail, size: iconSize),
                                    SizedBox(width: spacing),
                                    Text(
                                      admin["email"],
                                      style: GoogleFonts.inter(
                                        fontSize: bodyFs,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing * 2),

                      // VEHICLES + CREDITS
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: spacing - 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withOpacity(0.7)),
                            ),
                            child: Text(
                              "${admin["vehicles"]} Vehicles",
                              style: GoogleFonts.inter(fontSize: smallFs),
                            ),
                          ),

                          SizedBox(width: spacing * 2),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: spacing - 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              "${admin["credits"]} LOW Credits",
                              style: GoogleFonts.inter(
                                fontSize: smallFs,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing * 2),

                      // RECENT LOGIN + SWITCH
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent login: ${admin["recentLogin"]}",
                            style: GoogleFonts.inter(
                              fontSize: smallFs + 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: admin["active"],
                              onChanged: (v) {
                                setState(() => admin["active"] = v);
                              },
                              activeColor: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing),

                      Row(
                        children: [
                          Icon(CupertinoIcons.location, size: iconSize),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Text(
                              admin["location"],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: bodyFs),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing),

                      Divider(),

                      SizedBox(height: spacing),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Joined: ${admin["joined"]}",
                              style: GoogleFonts.inter(
                                fontSize: smallFs,
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              admin["role"],
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: smallFs - 1,
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
