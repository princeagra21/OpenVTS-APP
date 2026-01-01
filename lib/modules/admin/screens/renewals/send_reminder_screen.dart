// screens/renewals/send_reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

class SendReminderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedDevices; // List of selected devices

  const SendReminderScreen({super.key, required this.selectedDevices});

  @override
  State<SendReminderScreen> createState() => _SendReminderScreenState();
}

class _SendReminderScreenState extends State<SendReminderScreen> {
  String notificationMode = 'per-device'; // 'per-device' or 'consolidated'
  List<bool> channelSelections = [true, false, false]; // email, sms, whatsapp

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.text =
        "Your device subscription is due. Please renew to avoid suspension.";
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _getPreviewText() {
    if (widget.selectedDevices.isEmpty) return _messageController.text;

    final example = widget.selectedDevices.first;
    return _messageController.text
        .replaceAll('{customer}', example['customer'])
        .replaceAll('{vehicle}', example['vehicle'])
        .replaceAll('{imei}', example['imei'])
        .replaceAll('{expiry_date}', example['expiry'])
        .replaceAll('{amount}', example['amount']);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    final int deviceCount = widget.selectedDevices.length;

    // compute available minHeight so ConstrainedBox works well across devices
    final media = MediaQuery.of(context);
    final double availableHeight = media.size.height -
        media.padding.top -
        media.padding.bottom -
        (padding * 2);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── HEADER ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Send Reminder",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    Center(
                      child: Text(
                        "Notify per-device or consolidated by customer.",
                        style: GoogleFonts.inter(
                          fontSize: fs - 2,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── NOTIFICATION MODE ──────────────────
                    Text(
                      "Notification Mode",
                      style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text("Per-device", style: GoogleFonts.inter(fontSize: fs - 2)),
                            subtitle: Text("Individual reminder for each device", style: GoogleFonts.inter(fontSize: fs - 4, color: cs.onSurface.withOpacity(0.7))),
                            value: 'per-device',
                            groupValue: notificationMode,
                            onChanged: (v) => setState(() => notificationMode = v!),
                          ),
                          RadioListTile<String>(
                            title: Text("Consolidated by customer", style: GoogleFonts.inter(fontSize: fs - 2)),
                            subtitle: Text("One message listing all due devices", style: GoogleFonts.inter(fontSize: fs - 4, color: cs.onSurface.withOpacity(0.7))),
                            value: 'consolidated',
                            groupValue: notificationMode,
                            onChanged: (v) => setState(() => notificationMode = v!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── CHANNELS ───────────────────────────
                    Text(
                      "Channels",
                      style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                   Card(
  elevation: 4,
  shadowColor: Colors.black.withOpacity(0.3),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _channelItem(
          label: "Email",
          icon: Icons.email_rounded,
          value: channelSelections[0],
          onChanged: (v) => setState(() => channelSelections[0] = v!),
          cs: cs,
          fs: fs,
        ),
        _channelItem(
          label: "SMS",
          icon: Icons.sms_rounded,
          value: channelSelections[1],
          onChanged: (v) => setState(() => channelSelections[1] = v!),
          cs: cs,
          fs: fs,
        ),
        _channelItem(
          label: "WhatsApp",
          icon: Icons.chat_rounded,
          value: channelSelections[2],
          onChanged: (v) => setState(() => channelSelections[2] = v!),
          cs: cs,
          fs: fs,
        ),
      ],
    ),
  ),
),


                    const SizedBox(height: 24),

                    // ─── MESSAGE ────────────────────────────
                    Text(
                      "Message",
                      style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          fillColor: cs.surface,
                          filled: true,
                          hintText: "Enter message (supports variables)",
                          hintStyle: GoogleFonts.inter(color: cs.onSurface.withOpacity(0.6), fontSize: fs - 2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Variables: {customer}, {vehicle}, {imei}, {expiry_date}, {amount}",
                      style: GoogleFonts.inter(fontSize: fs - 4, color: cs.onSurface.withOpacity(0.7)),
                    ),

                    const SizedBox(height: 16),

                    // ─── PREVIEW ────────────────────────────
                    Text(
                      "Preview",
                      style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _getPreviewText(),
                          style: GoogleFonts.inter(fontSize: fs - 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── ACTION BUTTONS ─────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: cs.primary.withOpacity(0.3)),
                              foregroundColor: cs.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: channelSelections.contains(true)
                                ? () {
                                    // TODO: Send reminders via selected channels
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Reminder sent to $deviceCount device(s)")),
                                    );
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                            ),
                            child: Text(
                              "Send Reminder",
                              style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


Widget _channelItem({
  required String label,
  required IconData icon,
  required bool value,
  required ValueChanged<bool?> onChanged,
  required ColorScheme cs,
  required double fs,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: cs.primary),
      const SizedBox(height: 4),
      Text(
        label,
        style: GoogleFonts.inter(fontSize: fs - 3),
      ),
      Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: cs.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ],
  );
}

