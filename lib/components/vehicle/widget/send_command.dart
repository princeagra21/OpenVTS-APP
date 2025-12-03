import 'package:fleet_stack/utils/adaptive_utils.dart';
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
    final double screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values from our design system
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);     // 12–14
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);         
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            "Send Command",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "DL01 AB 1287 • IMEI 358920108765431 • GT06",
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),

          // Command Dropdown
          DropdownButtonFormField<String>(
            value: selectedCommand,
            items: commandOptions
                .map((cmd) => DropdownMenuItem(value: cmd, child: Text(cmd)))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedCommand = val!;
              });
            },
            decoration: InputDecoration(
              labelText: "Select Command",
              border: const OutlineInputBorder(),
               enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.black),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.black),
    ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 24),

          // Three textareas with copy buttons
          Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Row with "Payload" text and copy icon
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
          Container(
  padding: EdgeInsets.symmetric(
    horizontal: spacing + 2,
    vertical: spacing - 2,
  ),
  decoration: BoxDecoration(
    color: Colors.black, // <- set background here
    border: Border.all(color: Colors.black, width: 1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    "Payload",
    style: GoogleFonts.inter(
      fontSize: badgeFontSize,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
),

       Container(
  padding: EdgeInsets.symmetric(
    horizontal: spacing + 8,
    vertical: spacing - 2,
  ),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.black.withOpacity(0.5), width: 1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: InkWell(
    onTap: () {
      Clipboard.setData(ClipboardData(text: payload1Controller.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payload copied")),
      );
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.copy, color: Colors.black, size: 18),
        const SizedBox(width: 4),
        Text(
          "Copy",
          style: GoogleFonts.inter(
            fontSize: badgeFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    ),
  ),
),

      ],
    ),

    const SizedBox(height: 10), // tiny spacing

    // TextField
    TextField(
      controller: payload1Controller,
      minLines: 3,
      maxLines: 3,
      decoration: InputDecoration(
    labelText: "",
    labelStyle: const TextStyle(color: Colors.black),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.black),
      borderRadius: BorderRadius.circular(16),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.black),
    ),
    border: const OutlineInputBorder(),
    isDense: true,
    contentPadding: const EdgeInsets.all(12),
  ),
  style: const TextStyle(color: Colors.black), // text color
),
  ],
),


          const SizedBox(height: 24),

          // JSON toggle container
         GestureDetector(
  onTap: () => setState(() => showJson = !showJson),
  child: Row(
    mainAxisSize: MainAxisSize.min, // wrap tightly around content
    children: [
      Icon(
        showJson ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: 18,
      ),
      const SizedBox(width: 4),
      Text(
        "Request JSON",
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  ),
),

          if (showJson)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '{\n  "imei": "358920108765431",\n  "transport": "SMS",\n  "command": "REBOOT",\n  "payload": "REBOOT#"\n}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[800]),
              ),
            ),

          const SizedBox(height: 24),

          // Confirm + Send row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    checkColor: Colors.white,
                    focusColor:   Colors.black,
                    activeColor: Colors.black,

                      value: confirmBeforeSend,
                      onChanged: (val) {
                        setState(() {
                          confirmBeforeSend = val!;
                        });
                      }),
                  Text("Confirm Before Send",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send, size: 18, color: Colors.white,),
                label: const Text("Send", style: TextStyle(fontSize: 14, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.black
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Commands (empty)

          Text("Recent commands", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7)),),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    "No recent commands",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 
}