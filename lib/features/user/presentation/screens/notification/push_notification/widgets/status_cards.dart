import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';

class PushNotificationLoadingList extends StatelessWidget {
  const PushNotificationLoadingList({
    super.key,
    required this.width,
    required this.padding,
  });

  final double width;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: padding,
        mainAxisSpacing: 12,
        childAspectRatio: 4.5,
      ),
      itemBuilder: (context, index) =>
          _LoadingCard(width: width, padding: padding),
    );
  }
}

class PushNotificationEmptyCard extends StatelessWidget {
  const PushNotificationEmptyCard({
    super.key,
    required this.padding,
    required this.colorScheme,
  });

  final double padding;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding * 1.2, vertical: padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No notification settings found',
            style: AppFonts.roboto(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enable channels from the backend to manage alert delivery here.',
            style: AppFonts.roboto(color: colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.width, required this.padding});

  final double width;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final iconContainerSize = AdaptiveUtils.getAvatarSize(width) * 1.1;
    final cardPadding = EdgeInsets.symmetric(
      horizontal: padding * 1.2,
      vertical: padding * 0.7,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: cardPadding,
        child: Row(
          children: [
            AppShimmer(width: iconContainerSize, height: iconContainerSize, radius: 14),
            SizedBox(width: padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppShimmer(width: 140, height: 14, radius: 7),
                  SizedBox(height: 6),
                  AppShimmer(width: 200, height: 12, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

