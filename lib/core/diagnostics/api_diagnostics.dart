class SafeApiFailureSummary {
  const SafeApiFailureSummary({
    required this.endpointPattern,
    required this.method,
    required this.errorType,
    this.statusCode,
    this.requestId,
    this.durationMs,
  });

  final String endpointPattern;
  final String method;
  final String errorType;
  final int? statusCode;
  final String? requestId;
  final int? durationMs;
}

class ApiDiagnostics {
  final List<SafeApiFailureSummary> _recentFailures = <SafeApiFailureSummary>[];

  List<SafeApiFailureSummary> get recentFailures => List.unmodifiable(_recentFailures);

  void recordFailure(SafeApiFailureSummary failure) {
    _recentFailures.add(failure);
    if (_recentFailures.length > 50) {
      _recentFailures.removeAt(0);
    }
  }

  void clear() => _recentFailures.clear();
}
