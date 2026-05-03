    String label,
    String value,
    double labelFs,
    double valueFs,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  _AddressData _addressData(AdminDriverDetails? details) {
    if (details == null) {
