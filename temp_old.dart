          _keyValueRow(
            context,
            "Address ID",
            addressData.id,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "Line",
            addressData.line,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "City",
            addressData.city,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "State",
            addressData.state,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "Postal",
            addressData.postal,
            labelFs,
            detailValueFs,
          ),
          const SizedBox(height: 8),
          _keyValueRow(
            context,
            "Country",
            addressData.country,
            labelFs,
            detailValueFs,
          ),
        ],
      ),
    );
  }

  Widget _keyValueRow(
    BuildContext context,
    String label,
    String value,
    double labelFs,
    double valueFs,
  ) {
