import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class TicketFilters extends StatelessWidget {
  const TicketFilters({
    super.key,
    required this.searchController,
    required this.selectedTab,
    required this.onTabChanged,
    this.tabs = const <String>['All', 'Open', 'In Process', 'Closed'],
  });

  final TextEditingController searchController;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search tickets...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tabs.map((tab) {
              final selected = selectedTab == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onTabChanged(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: selected ? cs.onSurface : Colors.transparent,
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.surface : cs.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
