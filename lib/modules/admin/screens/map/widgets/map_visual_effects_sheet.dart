import 'package:flutter/material.dart';

enum MapVisualEffect {
  none,
  grayscale,
  nightMode,
  matrix,
  highContrast,
  vintage,
  blueprint,
}

class MapVisualEffectsSheet extends StatelessWidget {
  final MapVisualEffect selectedEffect;
  final ValueChanged<MapVisualEffect> onSelected;

  const MapVisualEffectsSheet({
    super.key,
    required this.selectedEffect,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                      'VISUAL EFFECTS',
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
              ...MapVisualEffect.values.map(
                (effect) {
                  final selected = effect == selectedEffect;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelected(effect),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? Colors.blue
                                : cs.outline.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _effectColor(effect),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _effectLabel(effect),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected ? Colors.blue : cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _effectLabel(MapVisualEffect effect) {
  switch (effect) {
    case MapVisualEffect.none:
      return 'None';
    case MapVisualEffect.grayscale:
      return 'Grayscale';
    case MapVisualEffect.nightMode:
      return 'Night Mode';
    case MapVisualEffect.matrix:
      return 'Matrix/Hacker';
    case MapVisualEffect.highContrast:
      return 'High Contrast';
    case MapVisualEffect.vintage:
      return 'Vintage';
    case MapVisualEffect.blueprint:
      return 'Blueprint';
  }
}

Color _effectColor(MapVisualEffect effect) {
  switch (effect) {
    case MapVisualEffect.none:
      return Colors.grey;
    case MapVisualEffect.grayscale:
      return Colors.blueGrey;
    case MapVisualEffect.nightMode:
      return const Color(0xFF2D4B8E);
    case MapVisualEffect.matrix:
      return const Color(0xFF1B8F3A);
    case MapVisualEffect.highContrast:
      return Colors.black;
    case MapVisualEffect.vintage:
      return const Color(0xFFB07A4A);
    case MapVisualEffect.blueprint:
      return const Color(0xFF1985FF);
  }
}

ColorFilter? mapVisualEffectFilter(MapVisualEffect effect, {bool pseudo3d = false}) {
  if (pseudo3d) {
    return const ColorFilter.matrix(<double>[
      1.06, 0, 0, 0, 2,
      0, 1.06, 0, 0, 2,
      0, 0, 1.10, 0, 2,
      0, 0, 0, 1, 0,
    ]);
  }

  switch (effect) {
    case MapVisualEffect.none:
      return null;
    case MapVisualEffect.grayscale:
      return const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case MapVisualEffect.nightMode:
      return const ColorFilter.matrix(<double>[
        0.9, 0, 0, 0, -20,
        0, 0.95, 0, 0, -10,
        0, 0, 1.15, 0, 18,
        0, 0, 0, 1, 0,
      ]);
    case MapVisualEffect.matrix:
      return const ColorFilter.matrix(<double>[
        0.5, 0.2, 0.0, 0, 0,
        0.0, 1.2, 0.0, 0, 0,
        0.0, 0.2, 0.5, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case MapVisualEffect.highContrast:
      return const ColorFilter.matrix(<double>[
        1.35, 0, 0, 0, -20,
        0, 1.35, 0, 0, -20,
        0, 0, 1.35, 0, -20,
        0, 0, 0, 1, 0,
      ]);
    case MapVisualEffect.vintage:
      return const ColorFilter.matrix(<double>[
        1.20, 0.10, 0.05, 0, 10,
        0.05, 1.05, 0.05, 0, 5,
        0.00, 0.10, 0.90, 0, -5,
        0, 0, 0, 1, 0,
      ]);
    case MapVisualEffect.blueprint:
      return const ColorFilter.matrix(<double>[
        0.7, 0.9, 1.2, 0, 0,
        0.2, 0.9, 1.3, 0, 0,
        0.0, 0.7, 1.5, 0, 0,
        0, 0, 0, 1, 0,
      ]);
  }
}
