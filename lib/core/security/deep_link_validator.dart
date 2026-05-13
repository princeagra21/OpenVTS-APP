import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';

class DeepLinkDecision {
  const DeepLinkDecision({required this.path, this.query = const {}});

  final String path;
  final Map<String, String> query;
}

class DeepLinkValidator {
  const DeepLinkValidator({
    required Set<String> allowedRoutePrefixes,
    Set<String> allowedHosts = const {},
  })  : _allowedRoutePrefixes = allowedRoutePrefixes,
        _allowedHosts = allowedHosts;

  final Set<String> _allowedRoutePrefixes;
  final Set<String> _allowedHosts;

  static const Set<String> _sensitiveQueryKeys = <String>{
    'token',
    'access_token',
    'refresh_token',
    'id_token',
    'password',
    'otp',
    'pin',
    'secret',
    'authorization',
  };

  Result<DeepLinkDecision, AppError> validate(
    Uri uri, {
    required bool Function(String path) canOpenPath,
  }) {
    if (uri.hasScheme && uri.scheme != 'openvts' && uri.scheme != 'https') {
      return const Result.failure(ValidationError('Unsupported deep link scheme'));
    }
    if (uri.userInfo.trim().isNotEmpty) {
      return const Result.failure(ValidationError('Deep link must not include credentials'));
    }
    if (uri.scheme == 'https' && _allowedHosts.isNotEmpty) {
      final allowed = _allowedHosts.map((host) => host.toLowerCase()).toSet();
      if (!allowed.contains(uri.host.toLowerCase())) {
        return const Result.failure(ValidationError('Untrusted deep link host'));
      }
    }

    final raw = uri.toString().toLowerCase();
    final path = uri.path.isEmpty ? '/' : uri.path;
    if (path.contains('..') || raw.contains('%2f') || raw.contains('%5c')) {
      return const Result.failure(ValidationError('Unsafe deep link path'));
    }

    final unsafeQueryKey = uri.queryParameters.keys.any((key) {
      final normalized = key.trim().toLowerCase();
      return _sensitiveQueryKeys.contains(normalized) || normalized.contains('token');
    });
    if (unsafeQueryKey) {
      return const Result.failure(ValidationError('Deep link must not carry sensitive credentials'));
    }

    final routeKnown = _allowedRoutePrefixes.any(path.startsWith);
    if (!routeKnown) {
      return Result.failure(NotFoundError('Unknown deep link route: $path'));
    }
    if (!canOpenPath(path)) {
      return const Result.failure(PermissionAppError('You do not have access to this route'));
    }

    return Result.success(
      DeepLinkDecision(path: path, query: Map<String, String>.from(uri.queryParameters)),
    );
  }
}
