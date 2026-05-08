import 'package:flutter/material.dart';

class MapTileOption {
  final String id;
  final String title;
  final String group;
  final String urlTemplate;
  final List<String> subdomains;
  final bool darkPreview;

  const MapTileOption({
    required this.id,
    required this.title,
    required this.group,
    required this.urlTemplate,
    this.subdomains = const [],
    this.darkPreview = false,
  });
}

const List<MapTileOption> kMapTileOptions = <MapTileOption>[
  MapTileOption(
    id: 'osm',
    title: 'OpenStreetMap',
    group: 'OSM',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  MapTileOption(
    id: 'carto_light',
    title: 'CartoDB Light',
    group: 'CARTODB',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
  ),
  MapTileOption(
    id: 'carto_voyager',
    title: 'CartoDB Voyager',
    group: 'CARTODB',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
  ),
  MapTileOption(
    id: 'carto_dark',
    title: 'CartoDB Dark',
    group: 'CARTODB',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    darkPreview: true,
  ),
];

class MapLayersSheet extends StatelessWidget {
  final String selectedTileLayerId;
  final ValueChanged<MapTileOption> onSelected;

  const MapLayersSheet({
    super.key,
    required this.selectedTileLayerId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = <String, List<MapTileOption>>{};
    for (final option in kMapTileOptions) {
      grouped.putIfAbsent(option.group, () => <MapTileOption>[]).add(option);
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Map Layers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: cs.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'GOOGLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? cs.surface.withValues(alpha: 0.9) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? cs.outline.withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Layers',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Google layers are not configured here. Use official tiles or API-backed sources only.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...grouped.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          itemCount: entry.value.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                          ),
                          itemBuilder: (context, index) {
                            final option = entry.value[index];
                            final selected = option.id == selectedTileLayerId;
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => onSelected(option),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.blue
                                        : cs.outline.withValues(alpha: 0.14),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(18),
                                        ),
                                        child: Container(
                                          color: option.darkPreview
                                              ? const Color(0xFF1C1C1C)
                                              : const Color(0xFFECECEC),
                                          child: Center(
                                            child: Icon(
                                              Icons.layers_outlined,
                                              size: 38,
                                              color: option.darkPreview
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option.title,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (selected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
                if (grouped.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No layers available.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
