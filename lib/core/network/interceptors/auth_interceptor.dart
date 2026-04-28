import 'package:dio/dio.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorageBase tokenStorage;

  AuthInterceptor({required this.tokenStorage});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If already set by caller, respect it.
    if (options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }

    if (!_shouldConsiderAuthForRequest(options)) {
      handler.next(options);
      return;
    }

    // Only attach tokens for role endpoints.
    if (!_isRoleEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    final token = await tokenStorage.readAccessToken();
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  bool _shouldConsiderAuthForRequest(RequestOptions options) {
    // Never attach auth to requests that go to a different host than the API baseUrl.
    // This prevents leaking tokens to absolute URLs (e.g. agent.fleetstack.in webhooks).
    final reqUri = options.uri;
    if (reqUri.hasAuthority) {
      final baseUrl = options.baseUrl;
      final baseUri = Uri.tryParse(baseUrl);
      if (baseUri == null || !baseUri.hasAuthority) return false;
      if (baseUri.host.toLowerCase() != reqUri.host.toLowerCase()) return false;
    }

    return !isPublicPath(options.path);
  }

  bool _isRoleEndpoint(String path) {
    final p = _normalizePathStatic(path).toLowerCase();
    return isRolePath(p) || p.startsWith('/geocoding/reverse');
  }

  static bool isRolePath(String path) {
    final p = _normalizePathStatic(path).toLowerCase();
    return p.startsWith('/admin') ||
        p.startsWith('/user') ||
        p.startsWith('/superadmin');
  }

  static bool isPublicPath(String path) {
    final p = _normalizePathStatic(path).toLowerCase();

    // Explicit public prefixes.
    if (p.startsWith('/auth')) return true;
    if (p.startsWith('/health')) return true;

    // Common reference endpoints (as seen in the Postman collection).
    const publicExact = <String>{
      '/devicestypes',
      '/vehicletypes',
      '/mobileprefix',
      '/countries',
      '/currencies',
      '/simproviders',
      '/timezones',
      '/languages',
      '/dateformats',
      '/version',
      '/status',
      '/policies',
      '/branding',
    };
    if (publicExact.contains(p)) return true;

    // Pattern-like reference endpoints.
    if (p.startsWith('/states/')) return true;
    if (p.startsWith('/cities/')) return true;
    if (p.startsWith('/documenttypes/')) return true;
    if (p.startsWith('/policies/')) return true;

    return false;
  }

  static String _normalizePathStatic(String path) {
    if (path.isEmpty) return '/';
    return path.startsWith('/') ? path : '/$path';
  }
}
