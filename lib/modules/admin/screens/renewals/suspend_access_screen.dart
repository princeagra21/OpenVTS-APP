// screens/renewals/suspend_access_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

class SuspendAccessScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedDevices; // List of selected devices

  const SuspendAccessScreen({super.key, required this.selectedDevices});

  @override
  State<SuspendAccessScreen> createState() => _SuspendAccessScreenState();
}

class _SuspendAccessScreenState extends State<SuspendAccessScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    final int deviceCount = widget.selectedDevices.length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Suspend Access",
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
              const SizedBox(height: 24),

              Center(
                child: Text(
                  "Temporarily disable tracking access and API per device.",
                  style: GoogleFonts.inter(
                    fontSize: fs - 2,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ─── WARNING CARD ───────────────────────
              Card(
                color: Colors.red.withOpacity(0.1),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.red[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Suspended devices will stop data access until renewed.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: fs,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "You can unsuspend after payment.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: fs - 2,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── DEVICES LIST ───────────────────────
              Text(
                "Devices to suspend ($deviceCount)",
                style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: deviceCount,
                  itemBuilder: (context, index) {
                    final device = widget.selectedDevices[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: cs.primary,
                        ),
                        title: Text(
                          device['vehicle'],
                          style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "IMEI: ${device['imei']}\nCustomer: ${device['customer']}",
                          style: GoogleFonts.inter(fontSize: fs - 4),
                        ),
                        trailing: Icon(
                          Icons.block,
                          color: Colors.red[600],
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // ─── ACTION BUTTONS ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                      onPressed: () {
                        // TODO: Suspend selected devices
                        // Show confirmation snackbar or dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$deviceCount device(s) suspended successfully"),
                            backgroundColor: Colors.red[600],
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      child: Text(
                        "Suspend",
                        style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600, color: Colors.white),
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
    );
  }
}