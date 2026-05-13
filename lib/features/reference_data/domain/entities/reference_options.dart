class ReferenceOption {
  const ReferenceOption({required this.value, required this.label});

  final String value;
  final String label;
}

class CountryOption {
  const CountryOption({required this.name, required this.isoCode});

  final String name;
  final String isoCode;
}

class MobilePrefixOption {
  const MobilePrefixOption({required this.countryCode, required this.code});

  final String countryCode;
  final String code;
}

class TimezoneOption {
  const TimezoneOption({required this.value, required this.label});

  final String value;
  final String label;
}
