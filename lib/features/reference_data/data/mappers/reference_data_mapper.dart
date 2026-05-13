import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/reference_data/data/models/reference_data_dtos.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

class ReferenceDataMapper {
  const ReferenceDataMapper();

  List<CountryDto> countriesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['countries'],
    ).map(_countryDto).toList(growable: false);
  }

  List<StateDto> statesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['states'],
    ).map(_stateDto).toList(growable: false);
  }

  List<CityDto> citiesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['cities'],
    ).map(_cityDto).toList(growable: false);
  }

  List<MobilePrefixDto> mobilePrefixesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['prefixes', 'mobilePrefixes'],
    ).map(_mobilePrefixDto).toList(growable: false);
  }

  List<GenericReferenceDto> genericReferencesFromResponse(
    Object? raw, {
    Iterable<String> preferredKeys = const <String>[],
  }) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: preferredKeys,
    ).map(_genericReferenceDto).toList(growable: false);
  }

  List<TimezoneDto> timezonesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['timezones'],
    ).map(_timezoneDto).toList(growable: false);
  }

  CountryOption country(CountryDto dto) => CountryOption(
        name: dto.name,
        isoCode: dto.isoCode,
      );

  ReferenceOption state(StateDto dto) => ReferenceOption(
        value: dto.value,
        label: dto.label,
      );

  ReferenceOption city(CityDto dto) => ReferenceOption(
        value: dto.value,
        label: dto.label,
      );

  MobilePrefixOption mobilePrefix(MobilePrefixDto dto) => MobilePrefixOption(
        countryCode: dto.countryCode,
        code: dto.code,
      );

  ReferenceOption genericReference(GenericReferenceDto dto) => ReferenceOption(
        value: dto.value,
        label: dto.label,
      );

  TimezoneOption timezone(TimezoneDto dto) => TimezoneOption(
        value: dto.value,
        label: dto.label,
      );

  CountryDto _countryDto(Object? value) {
    if (value is CountryDto) return value;
    return CountryDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  StateDto _stateDto(Object? value) {
    if (value is StateDto) return value;
    return StateDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  CityDto _cityDto(Object? value) {
    if (value is CityDto) return value;
    return CityDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  MobilePrefixDto _mobilePrefixDto(Object? value) {
    if (value is MobilePrefixDto) return value;
    return MobilePrefixDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  GenericReferenceDto _genericReferenceDto(Object? value) {
    if (value is GenericReferenceDto) return value;
    return GenericReferenceDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }

  TimezoneDto _timezoneDto(Object? value) {
    if (value is TimezoneDto) return value;
    return TimezoneDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }
}
