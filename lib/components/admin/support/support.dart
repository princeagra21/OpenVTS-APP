import 'package:fleet_stack/layout/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String selectedLocalTab = "All";
  String selectedDropdownStatus = "Closed";
  final List<String> localTabs = ["All", "Open", "In Process", "Answered", "Hold", "Closed"];
  final List<String> statusOptions = ["Closed", "Open", "In Process", "Answered", "Hold"];
  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double hp = 16;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Support",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

           /// ---------------- MAIN SFTP MASTER CONTAINER ----------------
Container(
  width: double.infinity,
  padding: EdgeInsets.all(hp),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.black.withOpacity(0.05)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// ---------------- HEADER: Title + Subtitle + Dropdown ----------------
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SFTP Export Setup",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Contoso Ops • Created: Yesterday • Updated: 1d",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// DROPDOWN
          Container(
            width: 100,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: DropdownButton<String>(
              value: selectedDropdownStatus,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedDropdownStatus = value);
                }
              },
              items: statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status,
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),
      Divider(color: Colors.black.withOpacity(0.1)),

      /// STATUS + OWNER
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "Status: $selectedDropdownStatus • Ticket owner: Contoso Ops",
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ),
      Divider(color: Colors.black.withOpacity(0.1)),

      const SizedBox(height: 16),

      /// ---------------- Conversation / Internal Note Tabs ----------------
      Wrap(
        spacing: 12,
        children: ["Conversation", "Internal Note"].map((tab) {
          return _LocalTab(
            label: tab,
            selected: tab == "Conversation",
            onTap: () {},
          );
        }).toList(),
      ),

      const SizedBox(height: 16),

      /// ---------------- Messages Container ----------------
      Container(
        width: double.infinity,
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Text("Previous messages will appear here"),
      ),

      const SizedBox(height: 16),

      /// ---------------- Message Input ----------------
      TextField(
        controller: messageController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: "Write your message...",
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
          ),
        ),
      ),

      const SizedBox(height: 12),

      /// ---------------- Buttons ----------------
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          /// AI Answer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, size: 18, color: Colors.black.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  "Generate Answer",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.7)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// Send button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.send, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text("Send", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
),


            const SizedBox(height: 24),

            /// ---------------- INBOX TITLE ----------------
            Text("Inbox", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text("8 tickets", style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),

            /// ---------------- TICKET CARDS ----------------
            _TicketCard(
              title: "API key not working after rotation",
              id: "FS-1046",
              name: "Priya Sharma",
              status: "In Process",
              desc: "Regenerated key still 401…",
            ),
            _TicketCard(
              title: "Unable to add new device (IMEI blocked?)",
              id: "FS-1045",
              name: "Rahul Verma",
              status: "Open",
              desc: "Adding GT06 shows validation error…",
            ),
            _TicketCard(
              title: "Billing GST invoice copy",
              id: "FS-1044",
              name: "Anita Desai",
              status: "Answered",
              desc: "Need last month invoice in PDF…",
            ),
            _TicketCard(
              title: "Geofence alert delay ~3 mins",
              id: "FS-1043",
              name: "Zhang Wei",
              status: "Hold",
              desc: "Alerts arriving late vs live map…",
            ),
            _TicketCard(
              title: "Device not reporting since midnight",
              id: "FS-1042",
              name: "Alice Johnson",
              status: "Open",
              desc: "Last ping 00:02 IST. Please check…",
            ),
            _TicketCard(
              title: "SFTP export setup",
              id: "FS-1041",
              name: "Contoso Ops",
              status: "Closed",
              desc: "Need daily CSV at 02:00 IST…",
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Local Tab ----------------
class _LocalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocalTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool small = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 6 : 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: small ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

/// ---------------- Ticket Card ----------------
class _TicketCard extends StatelessWidget {
  final String title;
  final String id;
  final String name;
  final String status;
  final String desc;

  const _TicketCard({
    super.key,
    required this.title,
    required this.id,
    required this.name,
    required this.status,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final double hp = 16;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          Text("$id • $name",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),

          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _statusColor(status),
            ),
          ),
          const SizedBox(height: 10),

          Text(desc, style: GoogleFonts.inter(fontSize: 13)),
        ],
      ),
    );
  }
}

/// ---------------- Status Colors ----------------
Color _statusColor(String status) {
  switch (status) {
    case "Open":
      return Colors.blue;
    case "In Process":
      return Colors.orange;
    case "Answered":
      return Colors.green;
    case "Hold":
      return Colors.purple;
    case "Closed":
      return Colors.red;
    default:
      return Colors.grey;
  }
}
