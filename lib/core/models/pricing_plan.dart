class PricingPlan {
  final int id;
  final String name;
  final double price;
  final String currency;
  final int durationDays;
  final String status;
  final Map<String, dynamic> raw;

  PricingPlan(this.raw)
      : id = raw['id'] ?? 0,
        name = raw['name'] ?? '',
        price = (raw['price'] as num?)?.toDouble() ?? 0.0,
        currency = raw['currency'] ?? '',
        durationDays = raw['durationDays'] ?? 0,
        status = raw['status']?.toString() ?? '';

  factory PricingPlan.fromRaw(Map<String, dynamic> json) => PricingPlan(json);
}
