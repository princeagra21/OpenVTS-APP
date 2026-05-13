class PricingPlan {
  final int id;
  final String name;
  final double price;
  final String currency;
  final int durationDays;
  final String status;
  final Map<String, Object?> raw;

  PricingPlan(this.raw)
      : id = _toInt(raw['id']),
        name = raw['name']?.toString() ?? '',
        price = _toDouble(raw['price']),
        currency = raw['currency']?.toString() ?? '',
        durationDays = _toInt(raw['durationDays']),
        status = raw['status']?.toString() ?? '';

  factory PricingPlan.fromRaw(Map<String, Object?> json) => PricingPlan(json);

  static int _toInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static double _toDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0.0;
}
