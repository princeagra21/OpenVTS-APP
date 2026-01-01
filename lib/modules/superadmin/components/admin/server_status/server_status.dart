// screens/server/server_status_screen.dart
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);

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
            // MAIN CARD
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // REFRESH BUTTON (top-right)
                  Align(
                    alignment: Alignment.topRight,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(horizontal: hp + 4, vertical: hp - 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.refresh_rounded, color: colorScheme.onPrimary),
                      label: Text("Refresh", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TITLE
                  Text("Server Status", style: GoogleFonts.inter(fontSize: fs + 8, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withOpacity(0.9))),
                  const SizedBox(height: 8),
                  Text("Monitor and manage server infrastructure", style: GoogleFonts.inter(fontSize: fs - 1, color: colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 32),

                  // OVERALL
                  _buildSection(
                    context: context,
                    title: "Overall",
                    status: "Down",
                    statusColor: Colors.red,
                    children: [
                      _buildInfoRow("Uptime", "5d 13h 59m 5s"),
                      _buildInfoRow("Started", "02/12/2025, 16:44:46"),
                      const SizedBox(height: 20),
                      _buildProgress("CPU", 41),
                      _buildProgress("Memory", 63),
                      _buildProgress("Disk", 72),
                      const SizedBox(height: 12),
                      Text("Load avg: 0.52 / 0.61 / 0.73", style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onSurface.withOpacity(0.8))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(context: context, title: "PostgreSQL", subtitle: "fleetstack", children: [
                    _buildInfoRow("Size", "86 GB"),
                    _buildInfoRow("Connections", "38"),
                    _buildInfoRow("Dead tuples", "120,000"),
                    const SizedBox(height: 16),
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      _actionChip("Refresh"),
                      _actionChip("Vacuum"),
                      _actionChip("Diagnostics"),
                    ]),
                  ]),
                  const SizedBox(height: 24),

                  _buildSection(context: context, title: "Services", subtitle: "4/6 running", children: [
                    _serviceRow("HTTP API", "running", "08/12/2025, 05:43:51", Colors.green),
                    _serviceRow("Device Ingest", "running", "08/12/2025, 00:43:51", Colors.green),
                    _serviceRow("WebSocket", "degraded", "08/12/2025, 06:13:51", Colors.orange),
                    _serviceRow("Background Jobs", "running", "07/12/2025, 06:43:51", Colors.green),
                    _serviceRow("Notifications", "stopped", "08/12/2025, 06:38:51", Colors.red),
                    _serviceRow("Redis", "running", "08/12/2025, 04:43:51", Colors.green),
                  ]),
                  const SizedBox(height: 24),

                  _buildSection(context: context, title: "Redis", children: [
                    _buildInfoRow("State", "connected", color: Colors.green),
                    _buildInfoRow("Used", "977 MB"),
                    _buildInfoRow("Hit rate", "91%"),
                    _buildInfoRow("Keys", "785,123"),
                    const SizedBox(height: 16),
                    _actionChip("Restart Redis", color: Colors.orange),
                  ]),
                  const SizedBox(height: 24),

                  _buildSection(context: context, title: "Socket.io", children: [
                    _buildInfoRow("Clients", "1,420"),
                    _buildInfoRow("Rooms", "220"),
                    _buildInfoRow("Events/sec", "340"),
                    const SizedBox(height: 16),
                    _actionChip("Restart Socket", color: Colors.orange),
                  ]),
                  const SizedBox(height: 24),

                  _buildSection(context: context, title: "BullMQ", children: [
                    _queueRow("ingest", "Active", wait: 42, act: 6, delay: 3, fail: 1),
                    _queueRow("notifications", "paused", wait: 0, act: 0, delay: 0, fail: 0),
                    _queueRow("geocoder", "Active", wait: 12, act: 2, delay: 1, fail: 0),
                  ]),
                  const SizedBox(height: 24),

                  _buildSection(context: context, title: "Firebase", children: [
                    _buildInfoRow("FCM", "reachable", color: Colors.green),
                    _buildInfoRow("Last ping", "08/12/2025, 06:44:46"),
                  ]),
                  const SizedBox(height: 32),

                  // DANGER ZONE: DELETE LOGS
                  Container(
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.error.withOpacity(0.5), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.warning_rounded, color: colorScheme.error, size: fs + 6),
                          const SizedBox(width: 12),
                          Text("Delete Data (Logs)", style: GoogleFonts.inter(fontSize: fs + 4, fontWeight: FontWeight.w800, color: colorScheme.error)),
                        ]),
                        const SizedBox(height: 12),
                        Text("Permanently delete GPS logs for a date range.", style: GoogleFonts.inter(fontSize: fs - 2, color: colorScheme.onSurface.withOpacity(0.8))),
                        const SizedBox(height: 24),
                        Text("Select date range", style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        CalendarDatePicker2(
                          config: CalendarDatePicker2WithActionButtonsConfig(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: colorScheme.primary,
                            dayTextStyle: TextStyle(color: colorScheme.onSurface),
                            todayTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                            controlsTextStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
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
                              backgroundColor: colorScheme.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text("Delete Selected Range", style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onError, fontWeight: FontWeight.w600)),
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

Widget _buildSection({
  required BuildContext context,
  required String title,
  String? subtitle,
  String? status,
  Color? statusColor,
  required List<Widget> children,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final double width = MediaQuery.of(context).size.width;

  // FIX: Add hp here
  final double hp = AdaptiveUtils.getHorizontalPadding(width);
  final double fs = AdaptiveUtils.getTitleFontSize(width);

  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(hp),
    decoration: BoxDecoration(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.storage_rounded, size: fs + 6, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: fs + 3,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 12),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: fs - 2,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
            if (status != null) ...[
              const Spacer(),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: fs - 1,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );
}

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text("$label: ", style: GoogleFonts.inter(fontSize: fs - 1, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.inter(fontSize: fs - 1, color: color ?? colorScheme.onSurface)),
      ]),
    );
  }

  Widget _buildProgress(String label, int percent) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(fontSize: fs - 1, fontWeight: FontWeight.w600)),
          Text("$percent%", style: GoogleFonts.inter(fontSize: fs - 1, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(percent > 80 ? Colors.red : percent > 60 ? Colors.orange : colorScheme.primary),
          minHeight: 8,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _serviceRow(String name, String status, String since, Color color) {
    final double fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontSize: fs - 1, fontWeight: FontWeight.w600)),
          Text("since $since", style: GoogleFonts.inter(fontSize: fs - 4, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ])),
        if (status != "running") _actionChip("Restart", color: status == "stopped" ? Colors.red : Colors.orange),
      ]),
    );
  }

  Widget _queueRow(String name, String state, {required int wait, required int act, required int delay, required int fail}) {
    final double fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text("$name ", style: GoogleFonts.inter(fontSize: fs - 1, fontWeight: FontWeight.w600)),
        Text(state, style: GoogleFonts.inter(fontSize: fs - 3, color: state == "paused" ? Colors.orange : Colors.green)),
        const Spacer(),
        Text("wait:$wait act:$act delay:$delay fail:$fail", style: GoogleFonts.inter(fontSize: fs - 5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ]),
    );
  }

  Widget _actionChip(String label, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    return ActionChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: fs - 3, fontWeight: FontWeight.w600, color: color ?? colorScheme.primary)),
      backgroundColor: (color ?? colorScheme.primary).withOpacity(0.1),
      onPressed: () {},
    );
  }
}