import 'package:fleet_stack/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 14,
          vertical: isSmallScreen ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
       //   border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 10.58 : 11.96,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String selectedTab = "All";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> admins = List.generate(5, (i) => {
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
    final bool isSmallScreen = screenWidth < 420;

    final filteredAdmins = admins; // For now, no filtering, all shown

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
            // Search TextField
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search name, email, role, department...",
                  hintStyle: GoogleFonts.inter(color: Colors.black.withOpacity(0.5), fontSize: isSmallScreen ? 12 : 14,),
                  prefixIcon: const Icon(CupertinoIcons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: ["All", "Active", "Disabled", "Pending"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () => setState(() => selectedTab = tab),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
           Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Showing text
    Text(
      "Showing ${filteredAdmins.length} of ${admins.length} admins",
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.black.withOpacity(0.87),
      ),
    ),

    // Export button
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent),
      ),
      child: Text(
        "Export",
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  ],
),

            const SizedBox(height: 10),
            // Admin list
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAdmins.length,
              itemBuilder: (context, index) {
                final admin = filteredAdmins[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Avatar
    CircleAvatar(
      backgroundColor: Colors.black,
      child: Text(
        admin["initials"],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    const SizedBox(width: 12),

    // Right side expanded area
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // -------------------------------------
          //  NAME + STATUS + LOGIN (same row)
          // -------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // Name + Status together
            GestureDetector(
  onTap: () {
    context.push("/admins/details/${admin['id']}");
  },
  child: Row(
    children: [
      Text(
        admin["name"],
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(width: 8),

      // STATUS BADGE
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: admin["status"] == "Verified"
              ? Colors.green.withOpacity(0.2)
              : admin["status"] == "Pending"
                  ? Colors.orange.withOpacity(0.2)
                  : admin["status"] == "Rejected"
                      ? Colors.red.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          admin["status"],
          style: GoogleFonts.inter(
            color: admin["status"] == "Verified"
                ? Colors.green
                : admin["status"] == "Pending"
                    ? Colors.orange
                    : admin["status"] == "Rejected"
                        ? Colors.red
                        : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  ),
),

              // LOGIN BUTTON
             Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white, // background color
    borderRadius: BorderRadius.circular(20), // rounded corners
    border: Border.all(
      color: Colors.black.withOpacity(0.5), // border color
      width: 1, // border width
    ),
  ),
  child: Text(
    "Login",
    style: GoogleFonts.inter(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
),

            ],
          ),

          const SizedBox(height: 6),

         // PHONE ROW
Row(
  children: [
    const Icon(CupertinoIcons.phone, size: 16, color: Colors.black),
    const SizedBox(width: 6), // horizontal gap between icon and text
    Text(
      admin["phone"],
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black.withOpacity(0.87),
      ),
    ),
  ],
),

const SizedBox(height: 4), // vertical gap before email row

// EMAIL ROW
Row(
  children: [
    const Icon(CupertinoIcons.mail, size: 16, color: Colors.black),
    const SizedBox(width: 6), // horizontal gap between icon and text
    Text(
      admin["email"],
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black.withOpacity(0.87),
      ),
    ),
  ],
),

        ],
      ),
    ),
  ],
),

                      const SizedBox(height: 12),
                     Row(
  children: [
    // Vehicles Badge (normal)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
      color: Colors.black.withOpacity(0.7), 
      width: 1,
    ),
      ),
      child: Text(
        "${admin["vehicles"]} Vehicles",
        style: GoogleFonts.inter(fontSize: 12, color: Colors.black.withOpacity(0.7)),
      ),
    ),

    const SizedBox(width: 12),

    // LOW Credits Badge (warning)
    Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.red.withOpacity(0.05), // very subtle background (optional)
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.red, // red border
      width: 1,
    ),
  ),
  child: RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: "${admin["credits"]} LOW ",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600, // bold
            color: Colors.red, // warning color
          ),
        ),
        TextSpan(
          text: "Credits",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.black.withOpacity(0.7), // credit number color
          ),
        ),
      ],
    ),
  ),
),

  ],
),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent login: ${admin["recentLogin"]}",
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.black.withOpacity(0.87), fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: admin["active"],
                            onChanged: (value) {
                              setState(() {
                                admin["active"] = value;
                              });
                            },
                            activeColor: Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              admin["location"],
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.black.withOpacity(0.87)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Joined: ${admin["joined"]}",
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              admin["role"],
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w500),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}