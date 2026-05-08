import 'package:flutter/material.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/design_system/components/open_vts_loading_view.dart';

class SettingsProfileLoading extends StatelessWidget {
  const SettingsProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({
      double height = 16,
      double width = double.infinity,
      double radius = 8,
    }) {
      return AppShimmer(width: width, height: height, radius: radius);
    }

    Widget cardSkeleton() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            const AppShimmer(width: 36, height: 36, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(width: 96, height: 14),
                  const SizedBox(height: 6),
                  block(width: 140, height: 12),
                ],
              ),
            ),
            block(width: 72, height: 28, radius: 10),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: OpenVtsLoadingView(label: 'Loading profile'),
        ),
        const SizedBox(height: 12),
        cardSkeleton(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: cardSkeleton()),
          ],
        ),
        const SizedBox(height: 12),
        cardSkeleton(),
      ],
    );
  }
}
