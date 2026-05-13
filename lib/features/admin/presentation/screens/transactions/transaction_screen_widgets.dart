part of 'transaction_screen.dart';

extension _TransactionScreenWidgets on _TransactionScreenState {
  Widget _summaryCard(
    BuildContext context, {
    required double width,
    required String title,
    required String value,
    required double titleSize,
    required double valueSize,
    required IconData icon,
    required double padding,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding - 2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: titleSize,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              Icon(icon, size: titleSize + 2, color: cs.onSurface),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppFonts.roboto(
              fontSize: valueSize,
              height: 24 / 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required double scale,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerHighest
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
