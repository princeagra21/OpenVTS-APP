import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

String safeText(String? value, {String fallback = '—'}) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return fallback;
  return trimmed;
}

String formatDateLabel(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '—';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final local = date.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final year = local.year.toString();
  final hour24 = local.hour;
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = hour24 >= 12 ? 'PM' : 'AM';
  return '$day $month $year • ${hour12.toString().padLeft(2, '0')}:$minute $meridiem';
}

String boolLabel(bool? value) {
  if (value == null) return '—';
  return value ? 'Yes' : 'No';
}

Widget detailsCard(BuildContext context, Widget child) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

Widget statusChip(BuildContext context, String status, double fontSize) {
  final cs = Theme.of(context).colorScheme;
  final lower = status.toLowerCase();
  Color bg() {
    if (lower.contains('verify') ||
        lower.contains('active') ||
        lower.contains('success')) {
      return Colors.green.withValues(alpha: 0.18);
    }
    if (lower.contains('pending') || lower.contains('process')) {
      return Colors.orange.withValues(alpha: 0.18);
    }
    if (lower.contains('disable') ||
        lower.contains('inactive') ||
        lower.contains('closed') ||
        lower.contains('failed') ||
        lower.contains('refund')) {
      return Colors.red.withValues(alpha: 0.18);
    }
    return Colors.blue.withValues(alpha: 0.15);
  }

  Color fg() {
    if (lower.contains('verify') ||
        lower.contains('active') ||
        lower.contains('success')) {
      return Colors.green;
    }
    if (lower.contains('pending') || lower.contains('process')) {
      return Colors.orange;
    }
    if (lower.contains('disable') ||
        lower.contains('inactive') ||
        lower.contains('closed') ||
        lower.contains('failed') ||
        lower.contains('refund')) {
      return Colors.red;
    }
    return cs.primary;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg(),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      status,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: fg(),
      ),
    ),
  );
}

Widget sectionTitle(BuildContext context, String title, double fontSize) {
  final cs = Theme.of(context).colorScheme;
  return Text(
    title,
    style: GoogleFonts.inter(
      fontSize: fontSize + 1,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
  );
}

Widget infoRow(
  BuildContext context,
  String label,
  String value,
  double bodyFontSize, {
  double labelWidth = 120,
}) {
  final cs = Theme.of(context).colorScheme;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: labelWidth,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: bodyFontSize,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: bodyFontSize, color: cs.onSurface),
        ),
      ),
    ],
  );
}

Widget detailLine(
  BuildContext context,
  String label,
  String value,
  double bodyFontSize,
) {
  return infoRow(context, label, value, bodyFontSize, labelWidth: 90);
}

Widget emptyStateCard(
  BuildContext context, {
  required String title,
  required String subtitle,
}) {
  final cs = Theme.of(context).colorScheme;
  final screenWidth = MediaQuery.of(context).size.width;
  final fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

  return detailsCard(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: fontSize - 2,
            color: cs.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ],
    ),
  );
}

Widget listShimmer(
  BuildContext context, {
  required int count,
  required double height,
}) {
  return Column(
    children: List<Widget>.generate(
      count,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 14),
        child: detailsCard(
          context,
          AppShimmer(width: double.infinity, height: height, radius: 14),
        ),
      ),
    ),
  );
}
