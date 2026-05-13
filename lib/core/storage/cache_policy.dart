class CachePolicy {
  const CachePolicy({
    required this.staleAfter,
    required this.expiresAfter,
  });

  final Duration staleAfter;
  final Duration expiresAfter;

  DateTime staleAt(DateTime now) => now.add(staleAfter);
  DateTime expiresAt(DateTime now) => now.add(expiresAfter);

  bool isFresh(DateTime now, DateTime staleAt) => now.isBefore(staleAt);
  bool isUsable(DateTime now, DateTime expiresAt) => now.isBefore(expiresAt);

  static const vehicleList = CachePolicy(
    staleAfter: Duration(minutes: 2),
    expiresAfter: Duration(hours: 12),
  );

  static const vehicleDetail = CachePolicy(
    staleAfter: Duration(minutes: 5),
    expiresAfter: Duration(hours: 24),
  );

  static const historyRange = CachePolicy(
    staleAfter: Duration(hours: 1),
    expiresAfter: Duration(days: 14),
  );
}
