import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_device_list_item.dart';
import 'package:fleet_stack/core/models/device_type_option.dart';
import 'package:fleet_stack/core/models/sim_option.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminDevicesRepository {
  final ApiClient api;

  const AdminDevicesRepository({required this.api});

  Future<Result<List<AdminDeviceListItem>>> getDevices({
    String? search,
    String? status,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      '/admin/devices',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['devices', 'deviceslist', 'items', 'results'],
        );
        final out = list
            .whereType<Map>()
            .map(
              (item) => AdminDeviceListItem.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<DeviceTypeOption>>> getDeviceTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/devicestypes', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['devicetypes', 'deviceTypes', 'items', 'results'],
        );
        final out = list
            .whereType<Map>()
            .map(
              (item) => DeviceTypeOption.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SimOption>>> getSims({CancelToken? cancelToken}) async {
    final res = await api.get('/admin/simcards', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['simcards', 'sims', 'items', 'results'],
        );
        final out = list
            .whereType<Map>()
            .map(
              (item) => SimOption.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SimOption>>> getQuickSimCards({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/quicksimcards', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          listKeys: const ['simcards', 'sims', 'items', 'results'],
        );
        final out = list
            .whereType<Map>()
            .map(
              (item) => SimOption.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, dynamic>>> getDeviceDetails(
    String deviceId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/devices/$deviceId', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        Map<String, dynamic> toMap(Object? value) {
          if (value is Map<String, dynamic>) return value;
          if (value is Map) return Map<String, dynamic>.from(value.cast());
          return const <String, dynamic>{};
        }

        final root = toMap(data);
        final dataNode = toMap(root['data']);
        final nested = toMap(dataNode['data']);
        final device = toMap(dataNode['device']);

        if (nested.isNotEmpty) return Result.ok(nested);
        if (device.isNotEmpty) return Result.ok(device);
        if (dataNode.isNotEmpty) return Result.ok(dataNode);
        return Result.ok(root);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> addDevice({
    required String imei,
    required String deviceTypeId,
    String? simId,
    String? simNumber,
    String? providerId,
    String? imsi,
    String? iccid,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'imei': imei.trim(),
      'deviceTypeId': _toNumOrString(deviceTypeId.trim()),
    };

    final sim = (simId ?? '').trim();
    if (sim.isNotEmpty) {
      payload['simId'] = _toNumOrString(sim);
    }
    final simNo = (simNumber ?? '').trim();
    if (simNo.isNotEmpty) {
      payload['simNumber'] = simNo;
    }
    final provider = (providerId ?? '').trim();
    if (provider.isNotEmpty) {
      payload['providerId'] = _toNumOrString(provider);
    }
    final imsiValue = (imsi ?? '').trim();
    if (imsiValue.isNotEmpty) {
      payload['imsi'] = imsiValue;
    }
    final iccidValue = (iccid ?? '').trim();
    if (iccidValue.isNotEmpty) {
      payload['iccid'] = iccidValue;
    }

    final res = await api.post(
      '/admin/devices',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> addDeviceAndSim({
    required String imei,
    required String deviceTypeId,
    required String simNumber,
    String? providerId,
    String? imsi,
    String? iccid,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'imei': imei.trim(),
      'deviceTypeId': _toNumOrString(deviceTypeId.trim()),
      'simNumber': simNumber.trim(),
    };

    final provider = (providerId ?? '').trim();
    if (provider.isNotEmpty) {
      payload['providerId'] = _toNumOrString(provider);
    }
    final imsiValue = (imsi ?? '').trim();
    if (imsiValue.isNotEmpty) {
      payload['imsi'] = imsiValue;
    }
    final iccidValue = (iccid ?? '').trim();
    if (iccidValue.isNotEmpty) {
      payload['iccid'] = iccidValue;
    }

    final res = await api.post(
      '/admin/deviceandsim',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateDeviceStatus(
    String deviceId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await updateDevice(
      deviceId,
      <String, dynamic>{'isActive': isActive},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateDevice(
    String deviceId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/devices/$deviceId',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Object _toNumOrString(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    return value;
  }

  List _extractList(Object? data, {List<String> listKeys = const <String>[]}) {
    final keys = <String>['data', 'items', 'result', 'results', ...listKeys];

    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }

      for (final value in map.values) {
        if (value is Map || value is List) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0) ?? const [];
  }
}
