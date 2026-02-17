import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/auth_repository.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugSuperadminRecentVehiclesSmokeTest {
  static const _identifier = String.fromEnvironment(
    'SMOKE_IDENTIFIER',
    defaultValue: '',
  );
  static const _password = String.fromEnvironment(
    'SMOKE_PASSWORD',
    defaultValue: '',
  );

  static Future<void> run(
    BuildContext context, {
    required CancelToken cancelToken,
  }) async {
    if (!kDebugMode) return;

    if (_identifier.trim().isEmpty || _password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set SMOKE_IDENTIFIER and SMOKE_PASSWORD via --dart-define',
          ),
        ),
      );
      return;
    }

    final tokenStorage = TokenStorage.defaultInstance();
    final api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: tokenStorage,
    );
    final auth = AuthRepository(api: api, tokenStorage: tokenStorage);
    final repo = SuperadminRepository(api: api);

    final loginRes = await auth.login(
      identifier: _identifier,
      password: _password,
      cancelToken: cancelToken,
    );

    final token = await loginRes.when(
      success: (t) async => t,
      failure: (err) async {
        _snack(context, _friendly(err));
        return null;
      },
    );

    if (token == null) return;

    final vehiclesRes = await repo.getRecentVehicles(cancelToken: cancelToken);
    vehiclesRes.when(
      success: (vehicles) {
        final keys = vehicles.isEmpty ? const <String>[] : vehicles.first.keys;
        if (kDebugMode) {
          debugPrint(
            '[SMOKE][SUPERADMIN] recentvehicles count=${vehicles.length} first.keys=$keys',
          );
        }
        _snack(context, 'Superadmin recent vehicles OK');
      },
      failure: (err) => _snack(context, _friendly(err)),
    );

    final countsRes = await repo.getTotalCounts(cancelToken: cancelToken);
    countsRes.when(
      success: (counts) {
        if (kDebugMode) {
          debugPrint('[SMOKE][SUPERADMIN] totalcounts keys=${counts.keys}');
        }
      },
      failure: (_) {},
    );

    final usersRes = await repo.getRecentUsers(cancelToken: cancelToken);
    usersRes.when(
      success: (users) {
        final keys = users.isEmpty ? const <String>[] : users.first.keys;
        if (kDebugMode) {
          debugPrint(
            '[SMOKE][SUPERADMIN] recentusers count=${users.length} first.keys=$keys',
          );
        }
      },
      failure: (_) {},
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static String _friendly(Object err) {
    if (err is ApiException) {
      if (err.statusCode == 401 || err.statusCode == 403) {
        return 'Please log in again';
      }
      return 'Network error';
    }
    return 'Network error';
  }
}
