part of 'vehicle_details_screen.dart';

extension _VehicleDetailsHelpers on _VehicleDetailsScreenState {
  List<AdminVehicleLogItem> _filteredLogs() {
    var items = _logs;
    if (_logFilter != 'All') {
      items = items
          .where((l) => l.packetType.toUpperCase() == _logFilter)
          .toList();
    }
    final q = _logQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((l) {
        return l.packetType.toLowerCase().contains(q) ||
            l.imei.toLowerCase().contains(q) ||
            l.id.toLowerCase().contains(q);
      }).toList();
    }
    return items;
  }

  IconData _iconForPacketType(String packetType) {
    final v = packetType.toLowerCase();
    if (v.contains('event')) return Icons.flash_on;
    if (v.contains('position')) return Icons.location_on_outlined;
    if (v.contains('alarm')) return Icons.warning_amber_rounded;
    return Icons.insights_outlined;
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty || raw == '—') return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('d MMM y, h:mm a').format(dt.toLocal());
  }

  Widget _infoCell({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required double labelSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            softWrap: true,
            style: AppFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsShimmer(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final cardPadding = hp + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppShimmer(width: double.infinity, height: fsMain * 6.8, radius: 16),
        SizedBox(height: spacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = spacing;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                4,
                (_) => AppShimmer(
                  width: cardWidth,
                  height: fsMain * 4.8,
                  radius: 12,
                ),
              ),
            );
          },
        ),
        SizedBox(height: spacing),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = spacing;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                4,
                (_) => AppShimmer(
                  width: cardWidth,
                  height: fsMain * 4.8,
                  radius: 12,
                ),
              ),
            );
          },
        ),
        SizedBox(height: cardPadding),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required double width,
    required String title,
    required IconData icon,
    required List<String> lines,
    required double fsMeta,
    required double fsMain,
    double lineGap = 2,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: fsMain * 0.9,
        vertical: fsMain * 0.6,
      ),
      constraints: const BoxConstraints(minHeight: 90),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: fsMeta + 2,
                color: cs.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: fsMeta,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: fsMain * 0.6),
          ...List.generate(lines.length, (index) {
            final line = lines[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line,
                  softWrap: true,
                  style: AppFonts.roboto(
                    fontSize: fsMain,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (index != lines.length - 1) SizedBox(height: lineGap),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatDateOnly(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    final local = dt.toLocal();
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
    return '$day $month $year';
  }

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.toLowerCase() == 'null') return '—';
    return trimmed;
  }
}
