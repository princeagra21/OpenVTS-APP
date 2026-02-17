import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/profile.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/auth_repository.dart';
import 'package:fleet_stack/core/repositories/user_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugAuthProfileSmokeTestButton extends StatefulWidget {
  const DebugAuthProfileSmokeTestButton({super.key});

  @override
  State<DebugAuthProfileSmokeTestButton> createState() =>
      _DebugAuthProfileSmokeTestButtonState();
}

class _DebugAuthProfileSmokeTestButtonState
    extends State<DebugAuthProfileSmokeTestButton> {
  static const _identifier = String.fromEnvironment(
    'SMOKE_IDENTIFIER',
    defaultValue: '',
  );
  static const _password = String.fromEnvironment(
    'SMOKE_PASSWORD',
    defaultValue: '',
  );

  final CancelToken _cancelToken = CancelToken();
  bool _running = false;

  ApiClient? _api;
  AuthRepository? _authRepo;
  UserRepository? _userRepo;

  @override
  void dispose() {
    _cancelToken.cancel('DebugAuthProfileSmokeTestButton disposed');
    super.dispose();
  }

  Future<void> _run() async {
    if (!kDebugMode) return;
    if (_running) return;

    if (_identifier.trim().isEmpty || _password.trim().isEmpty) {
      _snack('Set SMOKE_IDENTIFIER and SMOKE_PASSWORD via --dart-define');
      return;
    }

    setState(() => _running = true);

    try {
      final tokenStorage = TokenStorage.defaultInstance();
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: tokenStorage,
      );
      _authRepo ??= AuthRepository(api: _api!, tokenStorage: tokenStorage);
      _userRepo ??= UserRepository(api: _api!);

      final loginRes = await _authRepo!.login(
        identifier: _identifier,
        password: _password,
        cancelToken: _cancelToken,
      );

      if (!mounted) return;

      final tokenOrErr = await loginRes.when(
        success: (token) async {
          _snack('Login OK');
          _log('Login OK (token length=${token.length})');
          return token;
        },
        failure: (err) async {
          _snack(_friendlyError(err));
          _log('Login failed: ${_friendlyError(err)}');
          return null;
        },
      );

      if (tokenOrErr == null) return;

      final profileRes = await _userRepo!.getProfile(cancelToken: _cancelToken);
      if (!mounted) return;

      profileRes.when(
        success: (profile) {
          _snack('Profile OK');
          _logProfile(profile);
        },
        failure: (err) {
          _snack(_friendlyError(err));
          _log('Profile failed: ${_friendlyError(err)}');
        },
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _friendlyError(Object err) {
    if (err is ApiException) {
      if (err.statusCode == 401) return 'Unauthorized';
      // Keep message short; do not log details.
      return err.message;
    }
    return 'Network error';
  }

  void _log(String msg) {
    // Debug only: avoids polluting production logs.
    if (kDebugMode) debugPrint('[SMOKE] $msg');
  }

  void _logProfile(Profile profile) {
    // Keys only; no sensitive values.
    _log('Profile OK keys=${profile.keys}');

    // Also log which fields we could infer (redacted).
    final safe = <String, String>{
      'id': profile.id.isEmpty ? '' : '<present>',
      'email': profile.email.isEmpty ? '' : '<present>',
      'name': profile.name.isEmpty ? '' : '<present>',
      'phone': profile.phone.isEmpty ? '' : '<present>',
      'role': profile.role.isEmpty ? '' : '<present>',
    }..removeWhere((k, v) => v.isEmpty);
    _log('Profile inferred fields=${safe.keys.toList()..sort()}');
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _running ? null : _run,
        child: _running
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Auth + Profile Smoke Test'),
      ),
    );
  }
}
