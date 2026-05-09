class ServerStatusModel {
  const ServerStatusModel({
    required this.overallHealth,
    required this.services,
    required this.metrics,
  });

  final String overallHealth;
  final Map<String, ServiceStatus> services;
  final ServerMetrics metrics;
}

class ServiceStatus {
  const ServiceStatus({
    required this.name,
    required this.status,
    required this.uptime,
    required this.lastChecked,
  });

  final String name;
  final String status; // 'healthy', 'warning', 'error'
  final Duration uptime;
  final DateTime lastChecked;
}

class ServerMetrics {
  const ServerMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkTraffic,
  });

  final double cpuUsage;
  final double memoryUsage;
  final Map<String, double> diskUsage;
  final Map<String, int> networkTraffic;
}

class ServerStatusState {
  const ServerStatusState({
    required this.status,
    required this.isLoading,
    required this.lastUpdated,
    required this.errorMessage,
  });

  const ServerStatusState.initial()
    : status = null,
      isLoading = false,
      lastUpdated = null,
      errorMessage = null;

  final ServerStatusModel? status;
  final bool isLoading;
  final DateTime? lastUpdated;
  final String? errorMessage;

  ServerStatusState copyWith({
    ServerStatusModel? status,
    bool? isLoading,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return ServerStatusState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}