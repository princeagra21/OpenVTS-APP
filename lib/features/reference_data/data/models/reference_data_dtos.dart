class CountryDto {
  const CountryDto({required this.name, required this.isoCode});

  final String name;
  final String isoCode;

  factory CountryDto.fromJson(Map<String, dynamic> json) {
    return CountryDto(
      name: _s(json['name'] ?? json['label'] ?? json['countryName']),
      isoCode: _s(json['isoCode'] ?? json['countryCode'] ?? json['code']).toUpperCase(),
    );
  }
}

class StateDto {
  const StateDto({required this.value, required this.label});

  final String value;
  final String label;

  factory StateDto.fromJson(Map<String, dynamic> json) {
    return StateDto(
      value: _s(json['code'] ?? json['stateCode'] ?? json['isoCode'] ?? json['id'] ?? json['value']),
      label: _s(json['name'] ?? json['stateName'] ?? json['label'] ?? json['title']),
    );
  }
}

class CityDto {
  const CityDto({required this.value, required this.label});

  final String value;
  final String label;

  factory CityDto.fromJson(Map<String, dynamic> json) {
    return CityDto(
      value: _s(json['code'] ?? json['cityCode'] ?? json['id'] ?? json['value']),
      label: _s(json['name'] ?? json['cityName'] ?? json['label'] ?? json['title']),
    );
  }
}

class MobilePrefixDto {
  const MobilePrefixDto({required this.countryCode, required this.code});

  final String countryCode;
  final String code;

  factory MobilePrefixDto.fromJson(Map<String, dynamic> json) {
    return MobilePrefixDto(
      countryCode: _s(json['country'] ?? json['countryCode'] ?? json['isoCode']).toUpperCase(),
      code: _s(json['code'] ?? json['mobilePrefix'] ?? json['prefix']),
    );
  }
}

String _s(Object? value) {
  if (value == null) return '';
  final text = value.toString().trim();
  return text.toLowerCase() == 'null' ? '' : text;
}


class GenericReferenceDto {
  const GenericReferenceDto({required this.value, required this.label});

  final String value;
  final String label;

  factory GenericReferenceDto.fromJson(Map<String, dynamic> json) {
    return GenericReferenceDto(
      value: _s(json['value'] ?? json['code'] ?? json['id'] ?? json['key'] ?? json['format'] ?? json['name']),
      label: _s(json['label'] ?? json['name'] ?? json['title'] ?? json['displayName'] ?? json['format'] ?? json['value']),
    );
  }
}

class TimezoneDto {
  const TimezoneDto({required this.value, required this.label});

  final String value;
  final String label;

  factory TimezoneDto.fromJson(Map<String, dynamic> json) {
    final value = _s(json['offset'] ?? json['value'] ?? json['code'] ?? json['id'] ?? json['name']);
    return TimezoneDto(
      value: value,
      label: _s(json['label'] ?? json['title'] ?? json['name'] ?? value),
    );
  }
}
