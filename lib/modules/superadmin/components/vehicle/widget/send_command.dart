// components/vehicle/send_commands_tab.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SendCommandsTab extends StatefulWidget {
  const SendCommandsTab({super.key});

  @override
  State<SendCommandsTab> createState() => _SendCommandsTabState();
}

class _SendCommandsTabState extends State<SendCommandsTab> {
  String selectedCommand = "Set Geofence";
  final TextEditingController payload1Controller = TextEditingController();
  final TextEditingController payload2Controller = TextEditingController();
  final TextEditingController payload3Controller = TextEditingController();
  bool showJson = false;
  bool confirmBeforeSend = false;

  final List<String> commandOptions = [
    "ping",
    "immobile",
    "mobilize",
    "Set Timezone",
    "Set Geofence",
    "Reboot device",
    "custom"
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADING
          Text("Send Command", style: GoogleFonts.inter(fontSize: titleFs + 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text("DL01 AB 1287 • IMEI 358920108765431 • GT06", style: GoogleFonts.inter(fontSize: smallFs + 1, color: colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 20),

          // COMMAND DROPDOWN
          DropdownButtonFormField<String>(
            value: selectedCommand,
            decoration: InputDecoration(
              labelText: "Select Command",
              labelStyle: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface.withOpacity(0.8)),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
            dropdownColor: colorScheme.surface,
            items: commandOptions.map((cmd) => DropdownMenuItem(value: cmd, child: Text(cmd))).toList(),
            onChanged: (val) => val != null ? setState(() => selectedCommand = val) : null,
          ),
          const SizedBox(height: 20),

          // PAYLOAD SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: spacing - 2),
                decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                child: Text("Payload", style: GoogleFonts.inter(fontSize: smallFs + 2, fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: payload1Controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payload copied")));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: spacing + 8, vertical: spacing - 2),
                  decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(10), border: Border.all(color: colorScheme.outline.withOpacity(0.5))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 16, color: colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text("Copy", style: GoogleFonts.inter(fontSize: smallFs + 2, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: payload1Controller,
            minLines: 3,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Enter payload here...",
              hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6)),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
            ),
          ),

          const SizedBox(height: 20),

          // REQUEST JSON TOGGLE
          GestureDetector(
            onTap: () => setState(() => showJson = !showJson),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(showJson ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text("Request JSON", style: GoogleFonts.inter(fontSize: smallFs + 2, color: colorScheme.onSurface.withOpacity(0.8))),
              ],
            ),
          ),
          if (showJson) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '{\n  "imei": "358920108765431",\n  "transport": "SMS",\n  "command": "REBOOT",\n  "payload": "REBOOT#"\n}',
                style: GoogleFonts.jetBrainsMono(fontSize: smallFs + 1, color: colorScheme.onSurface.withOpacity(0.9)),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // CONFIRM + SEND
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: confirmBeforeSend,
                    activeColor: colorScheme.primary,
                    onChanged: (v) => v != null ? setState(() => confirmBeforeSend = v) : null,
                  ),
                  Text("Confirm Before Send", style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onSurface)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: Icon(Icons.send, size: 18, color: colorScheme.onPrimary),
                label: Text("Send", style: GoogleFonts.inter(fontSize: bodyFs, color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // RECENT COMMANDS
          Text("Recent commands", style: GoogleFonts.inter(fontSize: titleFs, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 36, color: colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text("No recent commands", style: GoogleFonts.inter(fontSize: smallFs + 2, color: colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}