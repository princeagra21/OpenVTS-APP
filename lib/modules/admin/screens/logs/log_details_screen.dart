import 'dart:convert';

import 'package:fleet_stack/core/models/admin_log_item.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminLogDetailsScreen extends StatelessWidget {
  final AdminLogItem log;

  const AdminLogDetailsScreen({super.key, required this.log});

  String _safe(String value) {
    final text = value.trim();
    return text.isEmpty ? '—' : text;
  }

  String _fromRaw(List<String> keys) {
    for (final key in keys) {
      final value = log.raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
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
    return DateTime.tryParse(value)?.toLocal();
  }

  String _prettyDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('EEE, MMM d, yyyy, hh:mm:ss a').format(dt);
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _friendlyAction(String raw) {
    final action = raw.trim();
    if (action.isEmpty) return 'Activity';
    final parts = action.split('.');
    if (parts.length >= 2) {
      final entity = parts[parts.length - 2].replaceAll('_', ' ');
      final op = parts.last.replaceAll('_', ' ');
      return '${_titleCase(entity)} · ${_titleCase(op)}';
    }
    return _titleCase(action.replaceAll('.', ' ').replaceAll('_', ' '));
  }

  String _titleCase(String value) {
    final words = value
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return words
        .map(
          (w) =>
              '${w.substring(0, 1).toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }

  Map<String, dynamic> _metaMap() {
    final meta = log.raw['meta'];
    if (meta is Map<String, dynamic>) return meta;
    if (meta is Map) return Map<String, dynamic>.from(meta.cast());
    return const <String, dynamic>{};
  }

  String _metadataJson() {
    final meta = _metaMap();
    if (meta.isEmpty) return '{}';
    return const JsonEncoder.withIndent('  ').convert(meta);
  }

  Widget _infoCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final labelFs = AdaptiveUtils.getTitleFontSize(width);
    final valueFs = labelFs + 1.5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final action = _fromRaw(['action']);
    final entity = _fromRaw(['entity', 'entityName']);
    final ip = _fromRaw(['ip', 'ipAddress']);
    final browser = _fromRaw(['browser', 'userAgent']);
    final platform = _fromRaw(['platform', 'os', 'device']);
    final created = _parseDate(log.time);
    final userMap = log.raw['user'];
    String userName = '';
    String userUsername = '';
    String userLoginType = '';
    if (userMap is Map) {
      final m = Map<String, dynamic>.from(userMap.cast());
      userName = (m['name'] ?? '').toString();
      userUsername = (m['username'] ?? '').toString();
      userLoginType = (m['loginType'] ?? '').toString();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hp,
                AppUtils.appBarHeightCustom + 20,
                hp,
                24,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.surfaceVariant
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.event_note_outlined,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity Log Details',
                                style: GoogleFonts.roboto(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(width) +
                                      1,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _friendlyAction(action.isEmpty ? log.message : action),
                                style: GoogleFonts.roboto(
                                  fontSize:
                                      AdaptiveUtils.getTitleFontSize(width) + 1,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _infoCard(
                            context,
                            label: 'Entity',
                            value: _safe(entity.isEmpty ? log.entity : entity),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoCard(
                            context,
                            label: 'Platform',
                            value: _safe(platform),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      context,
                      label: 'Action',
                      value:
                          '${_friendlyAction(action.isEmpty ? log.message : action)}\n${_safe(action.isEmpty ? log.message : action)}',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _infoCard(
                            context,
                            label: 'IP Address',
                            value: _safe(ip),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _infoCard(
                            context,
                            label: 'Browser',
                            value: _safe(browser),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      context,
                      label: 'Time',
                      value: '${_prettyDate(created)}\n${_timeAgo(created)}',
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      context,
                      label: 'Performed by',
                      value:
                          '${_safe(userName)} @${_safe(userUsername)} · ${_safe(userLoginType)}',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metadata',
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.onSurface.withOpacity(0.08),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _metadataJson(),
                                style: GoogleFonts.roboto(
                                  fontSize:
                                      AdaptiveUtils.getTitleFontSize(width) +
                                      0.5,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
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
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Activity Log Details',
              leadingIcon: Icons.event_note_outlined,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
