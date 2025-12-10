// screens/support/support_screen.dart
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Data Models for Ticket and Message ---

class Ticket {
  final String title;
  final String id;
  final String name;
  final String owner;
  final String status;
  final String desc;
  final String created;
  final String updated;
  final List<Message> messages;

  const Ticket({
    required this.title,
    required this.id,
    required this.name,
    required this.owner,
    required this.status,
    required this.desc,
    required this.created,
    required this.updated,
    required this.messages,
  });
}

class Message {
  final String sender;
  final String content;
  final String timestamp;
  final bool isInternalNote;

  const Message({
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isInternalNote = false,
  });
}

// --- Status Color Helper ---

Color _statusColor(String status, ColorScheme colorScheme) {
  switch (status) {
    case "Open":
      return colorScheme.primary;
    case "In Process":
      return Colors.orange;
    case "Answered":
      return Colors.green;
    case "Hold":
      return Colors.purple;
    case "Closed":
      return colorScheme.error;
    default:
      return colorScheme.onSurfaceVariant;
  }
}

// --- Dummy Data ---

final List<Ticket> dummyTickets = [
  Ticket(
    title: "SFTP Export Setup",
    id: "FS-1041",
    name: "Contoso Ops",
    owner: "Contoso Ops",
    status: "Closed",
    desc: "Need daily CSV at 02:00 IST...",
    created: "Yesterday",
    updated: "1d",
    messages: [
      Message(
        sender: "Contoso Ops",
        content: "Hi Team, we need to set up a daily SFTP export of vehicle data (trip summary, current location) to our server. We require the file every day at 02:00 IST. Please let us know the required credentials.",
        timestamp: "Yesterday, 10:30 AM",
      ),
      Message(
        sender: "Fleet Stack Support",
        content: "Hello Contoso Ops, we have provisioned the SFTP export. Please find your credentials and configuration details attached. The daily CSV export will begin tomorrow at 02:00 IST. We are marking this ticket as Answered and will close it in 24 hours if no further issues are reported.",
        timestamp: "Yesterday, 04:45 PM",
      ),
      Message(
        sender: "Fleet Stack Support",
        content: "Configuration confirmed by Contoso Ops, closing ticket. [Internal Note]",
        timestamp: "Today, 10:00 AM",
        isInternalNote: true,
      ),
    ],
  ),
  Ticket(
    title: "API key not working after rotation",
    id: "FS-1046",
    name: "Priya Sharma",
    owner: "Priya Sharma",
    status: "In Process",
    desc: "Regenerated key still 401…",
    created: "2 hours ago",
    updated: "10 mins ago",
    messages: [
      Message(
        sender: "Priya Sharma",
        content: "I rotated my API key, but the new key is still returning a 401 Unauthorized error. I've double-checked the header format. The old key stopped working as expected.",
        timestamp: "2 hours ago",
      ),
      Message(
        sender: "Fleet Stack Support",
        content: "We are looking into the key rotation logs and investigating the issue with the 401 error. Will update you shortly. [In Process]",
        timestamp: "10 mins ago",
      ),
    ],
  ),
  Ticket(
    title: "Unable to add new device (IMEI blocked?)",
    id: "FS-1045",
    name: "Rahul Verma",
    owner: "Rahul Verma",
    status: "Open",
    desc: "Adding GT06 shows validation error…",
    created: "2 days ago",
    updated: "2 days ago",
    messages: [
      Message(
        sender: "Rahul Verma",
        content: "When trying to add a new GT06 device with IMEI 123456789012345, I get a validation error 'IMEI already in use or blocked'. This is a new device.",
        timestamp: "2 days ago, 9:00 AM",
      ),
    ],
  ),
  // ... (Other dummy tickets can be added here)
];

// --- Support Screen State and Widgets ---

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String selectedLocalTab = "Conversation"; // Keep Conversation selected initially
  String selectedDropdownStatus = "Closed";
  final List<String> localTabs = ["All", "Open", "In Process", "Answered", "Hold", "Closed"];
  final List<String> statusOptions = ["Closed", "Open", "In Process", "Answered", "Hold"];
  final TextEditingController messageController = TextEditingController();

  // New State: Selected Ticket
  Ticket? selectedTicket;

  @override
  void initState() {
    super.initState();
    // 1. When the user enters the screen, select the first ticket by default.
    if (dummyTickets.isNotEmpty) {
      selectedTicket = dummyTickets.first;
      // Also update the dropdown to match the selected ticket's status
      selectedDropdownStatus = selectedTicket!.status;
    }
  }

  void _selectTicket(Ticket ticket) {
    setState(() {
      selectedTicket = ticket;
      selectedDropdownStatus = ticket.status; // Update dropdown to match ticket status
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

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
            // MAIN TICKET DETAIL CONTAINER
            if (selectedTicket != null)
              _TicketDetailContainer(
                ticket: selectedTicket!,
                selectedDropdownStatus: selectedDropdownStatus,
                statusOptions: statusOptions,
                onStatusChanged: (value) {
                  if (value != null) setState(() => selectedDropdownStatus = value);
                },
                messageController: messageController,
                selectedLocalTab: selectedLocalTab,
                onTabSelected: (tab) => setState(() => selectedLocalTab = tab),
              ),

            if (selectedTicket == null)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Select a ticket from the inbox below to view details.",
                  style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                ),
              ),

            const SizedBox(height: 24),

            // INBOX TITLE
            Text(
              "Inbox",
              style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width), fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text("${dummyTickets.length} tickets", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), color: colorScheme.onSurface.withOpacity(0.54))),
            const SizedBox(height: 16),

            // TICKET CARDS LIST
            ...dummyTickets.map((ticket) => _TicketCard(
                  ticket: ticket,
                  isSelected: ticket.id == selectedTicket?.id, // Highlight the selected card
                  onTap: () => _selectTicket(ticket), // Set the selected ticket
                )).toList(),
          ],
        ),
      ),
    );
  }
}

// --- New Widget for Ticket Detail View (Master Container) ---

class _TicketDetailContainer extends StatelessWidget {
  final Ticket ticket;
  final String selectedDropdownStatus;
  final List<String> statusOptions;
  final ValueChanged<String?> onStatusChanged;
  final TextEditingController messageController;
  final String selectedLocalTab;
  final ValueChanged<String> onTabSelected;

  const _TicketDetailContainer({
    required this.ticket,
    required this.selectedDropdownStatus,
    required this.statusOptions,
    required this.onStatusChanged,
    required this.messageController,
    required this.selectedLocalTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    // Filter messages based on the selected tab
    final filteredMessages = selectedLocalTab == "Conversation"
        ? ticket.messages.where((m) => !m.isInternalNote).toList()
        : ticket.messages.where((m) => m.isInternalNote).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Title + Dropdown
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${ticket.name} • Created: ${ticket.created} • Updated: ${ticket.updated}",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        color: colorScheme.onSurface.withOpacity(0.54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // DROPDOWN
              Container(
                width: 110,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: selectedDropdownStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: colorScheme.surface,
                  icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
                  style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface),
                  onChanged: onStatusChanged,
                  items: statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Status: ${ticket.status} • Ticket owner: ${ticket.owner}",
              style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),

          // Conversation / Internal Note Tabs
          Wrap(
            spacing: 12,
            children: ["Conversation", "Internal Note"].map((tab) {
              return _LocalTab(
                label: tab,
                selected: tab == selectedLocalTab,
                onTap: () => onTabSelected(tab),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 2. Display place of messages with ticket message
          _MessagesContainer(
            messages: filteredMessages,
            selectedTab: selectedLocalTab,
          ),

          const SizedBox(height: 16),

          // Message Input
          TextField(
            controller: messageController,
            maxLines: 5,
            style: GoogleFonts.inter(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Write your message...",
              hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // AI Answer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      "Generate Answer",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.send, color: colorScheme.onPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Send",
                      style: GoogleFonts.inter(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- New Widget for Messages Display ---

class _MessagesContainer extends StatelessWidget {
  final List<Message> messages;
  final String selectedTab;

  const _MessagesContainer({required this.messages, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (messages.isEmpty) {
      return Container(
        width: double.infinity,
        height: 150,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Text(
          "No ${selectedTab.toLowerCase()} messages for this ticket.",
          style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.builder(
        reverse: true, // Display newest message at the bottom
        shrinkWrap: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.sender,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: message.isInternalNote ? Colors.purple : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// LOCAL TAB (Unchanged)
class _LocalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocalTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final bool small = width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 6 : 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: small ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// TICKET CARD (Modified to accept a Ticket object and handle selection)
class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isSelected;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final Color statusColor = _statusColor(ticket.status, colorScheme);

    return InkWell(
      onTap: onTap, // Set the selected ticket on tap
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(hp),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.title,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${ticket.id} • ${ticket.name}",
              style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 2, color: colorScheme.onSurface.withOpacity(0.54)),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.status,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ticket.desc,
              style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), color: colorScheme.onSurface.withOpacity(0.87)),
            ),
          ],
        ),
      ),
    );
  }
}