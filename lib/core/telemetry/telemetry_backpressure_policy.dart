class TelemetryBackpressurePolicy {
  const TelemetryBackpressurePolicy({
    this.flushInterval = const Duration(milliseconds: 500),
    this.maxPacketAge = const Duration(minutes: 5),
  });

  final Duration flushInterval;
  final Duration maxPacketAge;

  bool isFresh(DateTime recordedAt, DateTime now) => now.difference(recordedAt) <= maxPacketAge;
}
