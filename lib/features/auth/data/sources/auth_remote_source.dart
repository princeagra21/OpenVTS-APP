import 'package:open_vts/features/auth/data/repositories/auth_repository.dart' as legacy;

class AuthRemoteSource {
  const AuthRemoteSource(this.repository);

  final legacy.AuthRepository repository;

  Future<legacy.AuthLoginContext> login({
    required String identifier,
    required String password,
  }) async {
    final result = await repository.loginWithContext(
      identifier: identifier,
      password: password,
    );
    return result.when(
      success: (ctx) => ctx,
      failure: (error) => throw error,
    );
  }
}
