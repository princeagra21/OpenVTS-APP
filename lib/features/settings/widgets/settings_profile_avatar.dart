import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class SettingsProfileAvatar extends StatelessWidget {
  const SettingsProfileAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.size = 56,
  });

  final String name;
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    final initials = name.trim().isEmpty || name.trim() == '-'
        ? '—'
        : name
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();

    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primary,
      child: Text(
        initials,
        style: AppFonts.roboto(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
