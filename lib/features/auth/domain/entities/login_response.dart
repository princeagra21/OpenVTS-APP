import 'package:open_vts/features/auth/domain/entities/auth_user.dart';

/// Domain result for a successful login.
///
/// Raw access/refresh tokens are intentionally not exposed here. The data
/// repository stores tokens in secure storage before returning this object, so
/// presentation only receives the authenticated user/session state it needs.
class LoginResponse {
  const LoginResponse({
    required this.user,
  });

  final AuthUser user;
}
