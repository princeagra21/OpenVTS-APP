import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/services/api_paths_facade.dart';
import 'package:open_vts/core/utils/presentation_result.dart';
import 'package:open_vts/features/admin_tools/domain/entities/server_status.dart';

class ServerStatusRepository {
  const ServerStatusRepository({required this.api});

  final LegacyApiTransport api;

  Future<Result<ServerStatusModel>> getServerStatus({
    AppCancellationHandle? cancelToken,
  }) async {
    final response = await api.get(
      SuperadminApiPaths.serverOverview,
      queryParameters: <String, dynamic>{
        'rk': DateTime.now().millisecondsSinceEpoch,
      },
      cancelToken: cancelToken,
    );

    return response.when(
      success: (data) => Result.ok(_buildStatus(data)),
      failure: (error) => Result.fail(error),
    );
  }

  ServerStatusModel _buildStatus(Object? data) {
    final payload = _payloadMap(data);
    final metrics = _metricsFrom(payload);
    final services = _servicesFrom(payload);
    return ServerStatusModel(
      overallHealth: _healthFrom(payload, metrics, services),
      services: services,
      metrics: metrics,
    );
  }

  String _healthFrom(
    Map<String, dynamic> payload,
    ServerMetrics metrics,
    Map<String, ServiceStatus> services,
  ) {
    final direct = _string(
      payload['overallHealth'] ??
          payload['health'] ??
          payload['status'] ??
          payload['state'],
    ).toLowerCase();
    if (_isError(direct)) return 'error';
    if (_isWarning(direct)) return 'warning';
    if (_isHealthy(direct)) return 'healthy';

    if (services.values.any((service) => _isError(service.status))) {
      return 'error';
    }
    if (services.values.any((service) => _isWarning(service.status)) ||
        metrics.cpuUsage >= 90 ||
        metrics.memoryUsage >= 90 ||
        metrics.diskUsage.values.any((value) => value >= 90)) {
      return 'warning';
    }
    return 'healthy';
  }

  ServerMetrics _metricsFrom(Map<String, dynamic> payload) {
    final system = _map(payload['system']).isNotEmpty
        ? _map(payload['system'])
        : payload;
    final cpu = _map(system['cpu']);
    final memory = _map(system['memory']);
    final network = _map(system['network'] ?? system['networkTraffic']);

    return ServerMetrics(
      cpuUsage: _double(
        payload['cpuUsage'] ??
            payload['cpuPercent'] ??
            cpu['usagePct'] ??
            cpu['usage'],
      ),
      memoryUsage: _memoryPercent(payload, memory),
      diskUsage: _diskUsage(
        system['disk'] ?? payload['diskUsage'] ?? payload['disk'],
      ),
      networkTraffic: network.map((key, value) => MapEntry(key, _int(value))),
    );
  }

  Map<String, ServiceStatus> _servicesFrom(Map<String, dynamic> payload) {
    final source = _map(payload['system']).isNotEmpty
        ? {...payload, ..._map(payload['system'])}
        : payload;
    final services = <String, ServiceStatus>{};
    final list = _mapList(
      source['services'] ??
          source['components'] ??
          source['checks'] ??
          source['items'],
    );

    if (list != null) {
      for (final item in list) {
        final service = _serviceFrom(item);
        services[service.name] = service;
      }
    }

    final serviceMap = _map(source['services']);
    for (final entry in serviceMap.entries) {
      final item = _map(entry.value);
      final service = _serviceFrom({
        ...item,
        if (_string(item['name']).isEmpty) 'name': entry.key,
      });
      services[service.name] = service;
    }

    return services;
  }

  ServiceStatus _serviceFrom(Map<String, dynamic> item) {
    final name = _string(item['name'] ?? item['service'] ?? item['id']);
    return ServiceStatus(
      name: name.isEmpty ? 'Service' : name,
      status: _normalizeStatus(
        item['status'] ?? item['state'] ?? item['health'],
      ),
      uptime: Duration(
        seconds: _int(
          item['uptimeSeconds'] ?? item['uptimeSec'] ?? item['uptime_s'],
        ),
      ),
      lastChecked:
          DateTime.tryParse(
            _string(
              item['lastChecked'] ?? item['checkedAt'] ?? item['updatedAt'],
            ),
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _payloadMap(Object? data) {
    final root = _map(data);
    final level1 = _map(root['data']);
    final level2 = _map(level1['data']);
    if (level2.isNotEmpty) return level2;
    if (level1.isNotEmpty) return level1;
    return root;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>>? _mapList(Object? value) {
    if (value is! List) return null;
    return value
        .whereType<Object>()
        .map(_map)
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, double> _diskUsage(Object? value) {
    final directMap = _map(value);
    if (directMap.isNotEmpty) {
      return directMap.map((key, value) => MapEntry(key, _double(value)));
    }

    final list = _mapList(value);
    if (list == null) return const <String, double>{};

    return {
      for (final item in list)
        _string(item['mount'] ?? item['path'] ?? item['name']).isEmpty
                ? '/'
                : _string(item['mount'] ?? item['path'] ?? item['name']):
            _diskPercent(item),
    };
  }

  double _memoryPercent(
    Map<String, dynamic> payload,
    Map<String, dynamic> memory,
  ) {
    final direct = _double(
      payload['memoryUsage'] ??
          payload['memoryPercent'] ??
          payload['memPercent'],
    );
    if (direct > 0) return direct;

    final total = _double(memory['total']);
    final used = _double(memory['used']);
    if (total <= 0) return 0;
    return (used / total) * 100;
  }

  double _diskPercent(Map<String, dynamic> item) {
    final direct = _double(
      item['usage'] ?? item['usagePct'] ?? item['percent'],
    );
    if (direct > 0) return direct;
    final total = _double(item['total']);
    final used = _double(item['used']);
    if (total <= 0) return 0;
    return (used / total) * 100;
  }

  String _normalizeStatus(Object? value) {
    final status = _string(value).toLowerCase();
    if (_isHealthy(status)) return 'healthy';
    if (_isWarning(status)) return 'warning';
    if (_isError(status)) return 'error';
    return status.isEmpty ? 'unknown' : status;
  }

  bool _isHealthy(String value) =>
      value == 'healthy' ||
      value == 'ok' ||
      value == 'up' ||
      value == 'running';

  bool _isWarning(String value) =>
      value == 'warning' || value == 'degraded' || value == 'paused';

  bool _isError(String value) =>
      value == 'error' ||
      value == 'down' ||
      value == 'failed' ||
      value == 'unhealthy';

  String _string(Object? value) => value == null ? '' : value.toString().trim();

  int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  double _double(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }
}
