import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normalized = _normalize(status);
    final color = switch (normalized) {
      'open' => cs.primary,
      'in_process' => Colors.orange,
      'answered' => Colors.green,
      'hold' => Colors.purple,
      'closed' => cs.error,
      _ => cs.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _label(status),
        style: AppFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _normalize(String raw) {
    final v = raw
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (v.contains('close')) return 'closed';
    if (v.contains('answer') || v.contains('resolve')) return 'answered';
    if (v.contains('hold')) return 'hold';
    if (v.contains('process') ||
        v.contains('progress') ||
        v.contains('pending')) {
      return 'in_process';
    }
    if (v.contains('open') || v.contains('new')) return 'open';
    return v;
  }

  String _label(String raw) {
    final v = _normalize(raw);
    switch (v) {
      case 'open':
        return 'Open';
      case 'in_process':
        return 'In Process';
      case 'answered':
        return 'Answered';
      case 'hold':
        return 'Hold';
      case 'closed':
        return 'Closed';
      default:
        return raw.trim().isEmpty ? 'Unknown' : raw;
    }
  }
}
