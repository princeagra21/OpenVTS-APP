import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'notification_toggle_tile.dart';

class NotificationDndBox extends StatefulWidget {
  const NotificationDndBox({super.key, this.onAttemptPersist});

  final VoidCallback? onAttemptPersist;

  @override
  State<NotificationDndBox> createState() => _NotificationDndBoxState();
}

class _NotificationDndBoxState extends State<NotificationDndBox> {
  bool dnd = false;

  // Nullable DND times
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // Pick DND time range
  void _pickTimeRange() async {
    final cs = Theme.of(context).colorScheme;

    final result = await showTimeRangePicker(
      context: context,
      start: startTime ?? const TimeOfDay(hour: 22, minute: 0),
      end: endTime ?? const TimeOfDay(hour: 6, minute: 0),
      interval: const Duration(minutes: 15),
      use24HourFormat: false,
      strokeColor: cs.primary,
      handlerColor: cs.primary,
      ticksColor: cs.primary,
      timeTextStyle: TextStyle(
        color: cs.primary,
        fontSize: 16, // Adjust to fit your titleFont or design
        fontWeight: FontWeight.w600,
      ),
      activeTimeTextStyle: TextStyle(
        color: cs.primary,
        fontSize: 16, // Adjust to fit your titleFont or design
        fontWeight: FontWeight.w600,
      ),
    );

    if (result != null) {
      setState(() {
        // Safely assign only if non-null
        startTime = result.startTime ?? startTime;
        endTime = result.endTime ?? endTime;
      });
      widget.onAttemptPersist?.call();
    }
  }

  String _formatTime(TimeOfDay? t) {
    final time = t ?? const TimeOfDay(hour: 0, minute: 0);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Do Not Disturb",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.do_not_disturb_on,
          title: "Enable DND",
          subtitle: "Mute all notifications temporarily",
          value: dnd,
          onChanged: (v) {
            setState(() {
              dnd = v;
              if (v && startTime == null && endTime == null) {
                startTime = const TimeOfDay(hour: 22, minute: 0);
                endTime = const TimeOfDay(hour: 6, minute: 0);
              }
            });
            widget.onAttemptPersist?.call();
          },
        ),
        if (dnd) ...[
          SizedBox(height: spacing),
          InkWell(
            onTap: _pickTimeRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(
                AdaptiveUtils.getHorizontalPadding(width),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: spacing),
                      Text(
                        "Select DND Time",
                        style: TextStyle(
                          fontSize: titleFont - 2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${_formatTime(startTime)} → ${_formatTime(endTime)}",
                    style: TextStyle(
                      fontSize: titleFont - 2,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing / 2),
          Text(
            "Critical alerts (like SOS) will be delivered even during this time.",
            style: TextStyle(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }
}
