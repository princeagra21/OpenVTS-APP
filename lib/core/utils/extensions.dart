extension NullableStringX on String? {
  bool get isBlank => this == null || this!.trim().isEmpty;
  String get orDash => isBlank ? '-' : this!.trim();
}

extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
