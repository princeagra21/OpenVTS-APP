import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  List<DateTime?> _dates = [
    DateTime.now().subtract(const Duration(days: 7)),
    DateTime.now(),
  ];

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Server Status",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Header Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                 // Header: Refresh at top-right, Title + Subtitle at left bottom
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Row with Refresh button at the top right
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: hp + 2,
              vertical: hp - 4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          label: Text(
            "Refresh",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),

    const SizedBox(height: 20),

    // Title: Server Status
    Text(
      "Server Status",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getTitleFontSize(width) + 6,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    ),

    const SizedBox(height: 6),

    // Subtitle: Monitor and manage...
    Text(
      "Monitor and manage server infrastructure",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getSubtitleFontSize(width) -2,
        fontWeight: FontWeight.w200,
        color: Colors.black54,
      ),
    ),
  ],
),

                  const SizedBox(height: 32),

                  // Overall Status
                  _buildSection(
                    width,
                    title: "Overall",
                    status: "Down",
                    statusColor: Colors.red,
                    children: [
                      _buildInfoRow("Uptime", "5d 13h 59m 5s"),
                      _buildInfoRow("Started", "02/12/2025, 16:44:46"),
                      const SizedBox(height: 24),
                      _buildProgress("CPU", 41),
                      _buildProgress("Memory", 63),
                      _buildProgress("Disk", 72),
                      const SizedBox(height: 12),
                      Text(
                        "Load avg: 0.52 / 0.61 / 0.73",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // PostgreSQL
                  _buildSection(
                    width,
                    title: "PostgreSQL",
                    subtitle: "fleetstack",
                    children: [
                      _buildInfoRow("Size", "86 GB"),
                      _buildInfoRow("Connections", "38"),
                      _buildInfoRow("Dead tuples", "120,000"),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _actionChip("Refresh"),
                          _actionChip("Vacuum"),
                          _actionChip("Diagnostics"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Services
                  _buildSection(
                    width,
                    title: "Services",
                    subtitle: "4/6 running",
                    children: [
                      _serviceRow("HTTP API", "running", "08/12/2025, 05:43:51", Colors.green),
                      _serviceRow("Device Ingest", "running", "08/12/2025, 00:43:51", Colors.green),
                      _serviceRow("WebSocket", "degraded", "08/12/2025, 06:13:51", Colors.orange),
                      _serviceRow("Background Jobs", "running", "07/12/2025, 06:43:51", Colors.green),
                      _serviceRow("Notifications", "stopped", "08/12/2025, 06:38:51", Colors.red),
                      _serviceRow("Redis", "running", "08/12/2025, 04:43:51", Colors.green),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Redis Details
                  _buildSection(
                    width,
                    title: "Redis",
                    children: [
                      _buildInfoRow("State", "connected", color: Colors.green),
                      _buildInfoRow("Used", "977 MB"),
                      _buildInfoRow("Hit rate", "91%"),
                      _buildInfoRow("Keys", "785,123"),
                      const SizedBox(height: 16),
                      _actionChip("Restart Redis", color: Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Socket.io
                  _buildSection(
                    width,
                    title: "Socket.io",
                    children: [
                      _buildInfoRow("Clients", "1,420"),
                      _buildInfoRow("Rooms", "220"),
                      _buildInfoRow("Events/sec", "340"),
                      const SizedBox(height: 16),
                      _actionChip("Restart Socket", color: Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // BullMQ Queues
                  _buildSection(
                    width,
                    title: "BullMQ",
                    children: [
                      _queueRow("ingest", "Active", wait: 42, act: 6, delay: 3, fail: 1),
                      _queueRow("notifications", "paused", wait: 0, act: 0, delay: 0, fail: 0),
                      _queueRow("geocoder", "Active", wait: 12, act: 2, delay: 1, fail: 0),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Firebase
                  _buildSection(
                    width,
                    title: "Firebase",
                    children: [
                      _buildInfoRow("FCM", "reachable", color: Colors.green),
                      _buildInfoRow("Last ping", "08/12/2025, 06:44:46"),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Delete GPS Logs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              "Delete Data (Logs)",
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                                fontWeight: FontWeight.w800,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Permanently delete GPS logs for a date range.",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Select date range",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(width),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
    calendarType: CalendarDatePicker2Type.range,
    selectedDayHighlightColor: Colors.black,
  ),
                          value: _dates,
                          onValueChanged: (dates) => setState(() => _dates = dates),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Delete Selected Range",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(double width, {
    required String title,
    String? subtitle,
    String? status,
    Color? statusColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, size: AdaptiveUtils.getTitleFontSize(width) + 5, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
              if (status != null) ...[
                const Spacer(),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? Colors.black87,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.inter(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(String label, int percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            Text("$percent%", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percent > 80 ? Colors.red : percent > 60 ? Colors.orange : Colors.green,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _serviceRow(String name, String status, String since, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                Text("since $since", style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          if (status != "running") // Show restart for non-running
            _actionChip("Restart", color: status == "stopped" ? Colors.red : Colors.orange),
        ],
      ),
    );
  }

  Widget _queueRow(String name, String state, {required int wait, required int act, required int delay, required int fail}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$name ", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(state, style: GoogleFonts.inter(color: state == "paused" ? Colors.orange : Colors.green, fontSize: 11)),
          const Spacer(),
          Text("wait:$wait act:$act delay:$delay fail:$fail", style: GoogleFonts.inter(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _actionChip(String label, {Color? color}) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color?.withOpacity(0.1) ?? Colors.black.withOpacity(0.05),
      labelStyle: GoogleFonts.inter(
        color: color ?? Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
      onPressed: () {},
    );
  }
}