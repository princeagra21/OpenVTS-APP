part of 'vehicle_details_screen.dart';

extension _VehicleDetailsActivityTabs on _VehicleDetailsScreenState {
  Widget _buildUsersTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final cardPadding = AdaptiveUtils.getHorizontalPadding(width) + 4;
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingUsers)
            const AppShimmer(width: double.infinity, height: 110, radius: 16)
          else if (_linkedUsers.isEmpty)
            Text(
              'No linked users.',
              style: AppFonts.roboto(
                fontSize: fsSecondary,
                color: cs.onSurface.withOpacity(0.7),
              ),
            )
          else
            ..._linkedUsers.map((user) {
              final name = user.fullName.isNotEmpty ? user.fullName : '—';
              final email = user.email.isNotEmpty ? user.email : '—';
              final phone = user.fullPhone.isNotEmpty ? user.fullPhone : '—';
              final initials = user.initials;
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: spacing),
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40 * (fsMain / 14),
                      height: 40 * (fsMain / 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surfaceContainerHighest
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials.isNotEmpty ? initials : '--',
                        style: AppFonts.roboto(
                          fontSize: fsMain,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppFonts.roboto(
                              fontSize: fsMain,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          SizedBox(height: spacing * 0.4),
                          Text(
                            email,
                            style: AppFonts.roboto(
                              fontSize: fsSecondary,
                              height: 16 / 12,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: spacing * 0.4),
                          Text(
                            phone,
                            style: AppFonts.roboto(
                              fontSize: fsSecondary,
                              height: 16 / 12,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final headerSize = 18 * scale;
    final labelSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final items = _filteredLogs();
    final rangeLabel = _logDateRange == null
        ? 'Date range'
        : '${DateFormat('d MMM').format(_logDateRange!.start)}'
              ' - ${DateFormat('d MMM').format(_logDateRange!.end)}';

    if (_loadingLogs) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Text(
                  'Vehicle Logs',
                  style: AppFonts.roboto(
                    fontSize: headerSize,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadingLogs ? null : _loadLogs,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _logsSearchController,
            onChanged: (v) => updateLocalUiState(this, () => _logQuery = v),
            decoration: InputDecoration(
              hintText: 'Search logs...',
              hintStyle: AppFonts.roboto(
                fontSize: labelSize,
                color: cs.onSurface.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.onSurface.withOpacity(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.onSurface.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
            style: AppFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (_logFilter == value) return;
                    updateLocalUiState(this, () => _logFilter = value);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'All', child: Text('All')),
                    PopupMenuItem(value: 'EVENT', child: Text('Event')),
                    PopupMenuItem(value: 'POSITION', child: Text('Position')),
                    PopupMenuItem(value: 'ALARM', child: Text('Alarm')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _logFilter,
                          style: AppFonts.roboto(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    DateTime? start = _logDateRange?.start;
                    DateTime? end = _logDateRange?.end;
                    final picked = await showDialog<DateTimeRange>(
                      context: context,
                      builder: (ctx) {
                        var selection = <DateTime?>[start, end];
                        return Dialog(
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: StatefulBuilder(
                              builder: (context, setDialogState) {
                                return CalendarDatePicker2(
                                  config: CalendarDatePicker2Config(
                                    calendarType: CalendarDatePicker2Type.range,
                                    currentDate: now,
                                    selectedDayHighlightColor: cs.primary,
                                    firstDate: DateTime(2020, 1, 1),
                                    lastDate: DateTime(2035, 12, 31),
                                  ),
                                  value: selection,
                                  onValueChanged: (values) {
                                    setDialogState(() {
                                      selection = values;
                                    });
                                    if (values.length >= 2) {
                                      Navigator.of(ctx).pop(
                                        DateTimeRange(
                                          start: values[0],
                                          end: values[1],
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                    if (picked == null) return;
                    updateLocalUiState(this, () => _logDateRange = picked);
                    _loadLogs();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.roboto(
                              fontSize: labelSize,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            child: items.isEmpty
                ? Text(
                    'No logs found.',
                    style: AppFonts.roboto(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  )
                : Column(
                    children: items.map((log) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey.shade50
                                        : cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _iconForPacketType(log.packetType),
                                    size: 18,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Event type: ${log.packetType.isNotEmpty ? log.packetType : '—'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.roboto(
                                          fontSize: headerSize - 1,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.grey.shade50
                                              : cs.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'Event time: ${_formatDateTime(log.deviceTime)}',
                                          style: AppFonts.roboto(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCell(
                                    label: 'Latitude',
                                    value: log.latitude,
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _infoCell(
                                    label: 'Longitude',
                                    value: log.longitude,
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoCell(
                                    label: 'Ignition',
                                    value: log.ignition,
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _infoCell(
                                    label: 'ACC / Valid',
                                    value: '${log.acc} / ${log.valid}',
                                    colorScheme: cs,
                                    labelSize: labelSize,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
