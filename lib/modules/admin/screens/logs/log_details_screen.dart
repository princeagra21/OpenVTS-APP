import 'dart:convert';

import 'package:fleet_stack/core/models/admin_log_item.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLogDetailsScreen extends StatelessWidget {
  final AdminLogItem log;

  const AdminLogDetailsScreen({super.key, required this.log});

  String? _clean(String? value, {bool hideUnknown = true}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final low = v.toLowerCase();
    if (low == 'null' || low == '-' || low == '—') return null;
    if (hideUnknown && (low == 'unknown' || low == 'n/a')) return null;
    return v;
  }

  DateTime? _parseDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final numeric = int.tryParse(value);
    if (numeric != null) {
      if (numeric > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numeric,
          isUtc: true,
        ).toLocal();
      }
      if (numeric > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numeric * 1000,
          isUtc: true,
        ).toLocal();
      }
    }

    final iso = DateTime.tryParse(value);
    if (iso != null) return iso.toLocal();
    return null;
  }

  String _relativeTime(String? raw) {
    final date = _parseDate(raw);
    if (date == null) return '';
    final now = DateTime.now();
    var diff = now.difference(date);
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inMinutes < 1) return '0m';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  String _absoluteTime(String? raw) {
    final date = _parseDate(raw);
    if (date == null) return '';
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
    final month = months[date.month - 1];
    final d = date.day.toString().padLeft(2, '0');
    var hour = date.hour;
    final min = date.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hh = hour.toString().padLeft(2, '0');
    return '$d $month ${date.year}, $hh:$min $amPm';
  }

  String _titleCaseAction(String raw) {
    final normalized = raw
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return '';
    return normalized
        .split(' ')
        .map((w) {
          final l = w.toLowerCase();
          if (l.isEmpty) return l;
          if (l.length == 1) return l.toUpperCase();
          return l[0].toUpperCase() + l.substring(1);
        })
        .join(' ');
  }

  String _summaryLabel() {
    final action = _clean(log.raw['action']?.toString());
    final entity = _clean(log.entity);
    final userMap = log.raw['user'];
    String? userName;
    if (userMap is Map<String, dynamic>) {
      userName = _clean((userMap['name'] ?? userMap['username'])?.toString());
    } else if (userMap is Map) {
      final m = Map<String, dynamic>.from(userMap.cast());
      userName = _clean((m['name'] ?? m['username'])?.toString());
    }

    final actionPretty = action == null ? null : _titleCaseAction(action);
    if (entity != null && actionPretty != null) {
      return '$entity • $actionPretty';
    }
    if (userName != null && actionPretty != null) {
      return '$userName • $actionPretty';
    }
    if (actionPretty != null) return actionPretty;
    if (entity != null) return entity;
    if (userName != null) return userName;
    return 'Activity';
  }

  Map<String, dynamic>? _metaMap() {
    final meta = log.raw['meta'];
    if (meta is Map<String, dynamic>) {
      return meta.isEmpty ? null : meta;
    }
    if (meta is Map) {
      final m = Map<String, dynamic>.from(meta.cast());
      return m.isEmpty ? null : m;
    }
    return null;
  }

  Widget _sectionCard({
    required ColorScheme colorScheme,
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _labelValue({
    required String label,
    required String? value,
    required double labelSize,
    required double valueSize,
    required ColorScheme colorScheme,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: valueSize,
                color: colorScheme.onSurface.withOpacity(0.92),
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final basePadding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final titleSize = AdaptiveUtils.getSubtitleFontSize(w) + 2;
    final subtitleSize = AdaptiveUtils.getTitleFontSize(w) - 2;
    final bodySize = AdaptiveUtils.getTitleFontSize(w);
    final smallSize = AdaptiveUtils.getTitleFontSize(w) - 2;

    final actionRaw = _clean(log.raw['action']?.toString());
    final actionPretty = actionRaw == null ? null : _titleCaseAction(actionRaw);
    final relative = _relativeTime(log.time);
    final absolute = _absoluteTime(log.time);

    final entity = _clean(log.entity);
    final entityId = _clean(log.raw['entityId']?.toString());

    final userMap = log.raw['user'];
    String? name;
    String? username;
    String? loginType;
    if (userMap is Map<String, dynamic>) {
      name = _clean(userMap['name']?.toString());
      username = _clean(userMap['username']?.toString());
      loginType = _clean(userMap['loginType']?.toString(), hideUnknown: false);
    } else if (userMap is Map) {
      final m = Map<String, dynamic>.from(userMap.cast());
      name = _clean(m['name']?.toString());
      username = _clean(m['username']?.toString());
      loginType = _clean(m['loginType']?.toString(), hideUnknown: false);
    }

    final ip = _clean(log.raw['ip']?.toString());
    final browser = _clean(log.raw['browser']?.toString());
    final platform = _clean(log.raw['platform']?.toString());

    final meta = _metaMap();
    final prettyMeta = meta == null
        ? null
        : const JsonEncoder.withIndent('  ').convert(meta);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(basePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Activity Log Details',
                      style: GoogleFonts.inter(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.92),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Inspect activity record',
                style: GoogleFonts.inter(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _sectionCard(
                        colorScheme: colorScheme,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _summaryLabel(),
                                    style: GoogleFonts.inter(
                                      fontSize: bodySize + 1,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (relative.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    relative,
                                    style: GoogleFonts.inter(
                                      fontSize: smallSize + 1,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (actionPretty != null) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      actionPretty,
                                      style: GoogleFonts.inter(
                                        fontSize: smallSize,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (actionRaw != null &&
                                actionPretty != null &&
                                actionRaw != actionPretty) ...[
                              const SizedBox(height: 10),
                              _labelValue(
                                label: 'Raw action',
                                value: actionRaw,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (absolute.isNotEmpty || relative.isNotEmpty)
                        _sectionCard(
                          colorScheme: colorScheme,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: GoogleFonts.inter(
                                  fontSize: bodySize,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _labelValue(
                                label: 'Occurred',
                                value: absolute,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                              _labelValue(
                                label: 'Relative',
                                value: relative.isEmpty ? null : relative,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ),
                      if (entity != null || entityId != null)
                        _sectionCard(
                          colorScheme: colorScheme,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entity',
                                style: GoogleFonts.inter(
                                  fontSize: bodySize,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _labelValue(
                                label: 'Name',
                                value: entity,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                              _labelValue(
                                label: 'ID',
                                value: entityId,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ),
                      if (name != null || username != null || loginType != null)
                        _sectionCard(
                          colorScheme: colorScheme,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Performed by',
                                      style: GoogleFonts.inter(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (loginType != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(
                                          0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        loginType,
                                        style: GoogleFonts.inter(
                                          fontSize: smallSize,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _labelValue(
                                label: 'Name',
                                value: name,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                              _labelValue(
                                label: 'Username',
                                value: username,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ),
                      if (ip != null || browser != null || platform != null)
                        _sectionCard(
                          colorScheme: colorScheme,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Technical info',
                                style: GoogleFonts.inter(
                                  fontSize: bodySize,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _labelValue(
                                label: 'IP',
                                value: ip,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                              _labelValue(
                                label: 'Browser',
                                value: browser,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                              _labelValue(
                                label: 'Platform',
                                value: platform,
                                labelSize: smallSize,
                                valueSize: bodySize,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ),
                      if (prettyMeta != null)
                        _sectionCard(
                          colorScheme: colorScheme,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Metadata',
                                      style: GoogleFonts.inter(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Copy',
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: prettyMeta),
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Metadata copied'),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.copy_rounded,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  minHeight: 88,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.background.withOpacity(
                                    0.55,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(
                                      0.12,
                                    ),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SelectableText(
                                    prettyMeta,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: smallSize,
                                      height: 1.4,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.88,
                                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
