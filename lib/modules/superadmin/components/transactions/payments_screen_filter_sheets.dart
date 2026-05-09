part of 'payments_screen.dart';

extension _PaymentsScreenFilterSheets on _PaymentsScreenState {
  Future<void> _pickAdminFilter(
    BuildContext context,
    ColorScheme cs,
    double scale,
  ) async {
    final chosen = await showModalBottomSheet<AdminListItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Admin',
                  style: AppFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        title: Text(
                          'All Admins',
                          style: AppFonts.roboto(
                            fontSize: 14 * scale,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () =>
                            Navigator.pop(ctx, const AdminListItem({})),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _admins.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final admin = _admins[index];
                            final title = admin.name.isNotEmpty
                                ? admin.name
                                : admin.email.isNotEmpty
                                ? admin.email
                                : admin.id;
                            final subtitle = admin.email.isNotEmpty
                                ? admin.email
                                : admin.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      style: AppFonts.roboto(
                                        fontSize: 14 * scale,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      style: AppFonts.roboto(
                                        fontSize: 12 * scale,
                                        height: 16 / 12,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.pop(ctx, admin),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null) {
      setState(() {
        if (chosen.id.isEmpty) {
          _allAdminsSelected = true;
          _selectedAdmin = null;
        } else {
          _selectedAdmin = chosen;
          _allAdminsSelected = false;
        }
      });
      _onFilterChanged();
    }
  }

  Future<void> _pickDateRangeFilter(
    BuildContext context,
    ColorScheme cs,
    double scale,
  ) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final items = [
          'All Time',
          'Today',
          'Last 7 days',
          'Last 30 days',
          'This month',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Date Range',
                  style: AppFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.4,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        title: Text(
                          item,
                          style: AppFonts.roboto(
                            fontSize: 14 * scale,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null) {
      setState(() {
        if (chosen == 'All Time') {
          _selectedRange = null;
        } else {
          _selectedRange = chosen;
        }
      });
      _onFilterChanged();
    }
  }
}
