import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_policy.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/network/api_client.dart';

class UserPolicyRepository {
  final ApiClient api;

  const UserPolicyRepository({required this.api});

  // Postman-confirmed endpoints:
  // - GET /policies
  // - PATCH /superadmin/policy (body keys: PolicyType, PolicyText)

  Future<Result<List<UserPolicy>>> getPolicies({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/policies', cancelToken: cancelToken);
    return res.when(
      success: (data) => Result.ok(UserPolicy.fromResponse(data)),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updatePolicies(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final updates = _extractUpdates(payload);
    if (updates.isEmpty) return Result.ok(null);

    for (final update in updates) {
      final res = await api.patch(
        '/superadmin/policy',
        data: update,
        cancelToken: cancelToken,
      );

      if (res.isFailure) {
        return Result.fail(res.error ?? const Object());
      }
    }

    return Result.ok(null);
  }

  List<Map<String, String>> _extractUpdates(Map<String, dynamic> payload) {
    final out = <Map<String, String>>[];

    void addUpdate(Object? type, Object? text) {
      final policyType = type?.toString().trim() ?? '';
      final policyText = text?.toString() ?? '';
      if (policyType.isEmpty) return;
      out.add(<String, String>{
        'PolicyType': policyType,
        'PolicyText': policyText,
      });
    }

    final listPayload = payload['policies'];
    if (listPayload is List) {
      for (final item in listPayload) {
        if (item is Map<String, dynamic>) {
          addUpdate(
            item['PolicyType'] ?? item['policyType'] ?? item['type'],
            item['PolicyText'] ?? item['policyText'] ?? item['text'],
          );
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item.cast());
          addUpdate(
            map['PolicyType'] ?? map['policyType'] ?? map['type'],
            map['PolicyText'] ?? map['policyText'] ?? map['text'],
          );
        }
      }
      if (out.isNotEmpty) return out;
    }

    // Fallback shape: { "PRIVACY_POLICY": "...", ... }
    for (final entry in payload.entries) {
      if (entry.key == 'policies') continue;
      addUpdate(entry.key, entry.value);
    }

    return out;
  }
}
