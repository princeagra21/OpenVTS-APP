import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_status_chip.dart';

class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalize(status);
    final tone = switch (normalized) {
      'open' => OpenVtsStatusTone.info,
      'in_process' => OpenVtsStatusTone.warning,
      'answered' => OpenVtsStatusTone.success,
      'hold' => OpenVtsStatusTone.neutral,
      'closed' => OpenVtsStatusTone.danger,
      _ => OpenVtsStatusTone.neutral,
    };

    return OpenVtsStatusChip(label: _label(status), tone: tone, compact: true);
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
