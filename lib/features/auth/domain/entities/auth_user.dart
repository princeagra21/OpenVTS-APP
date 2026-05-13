import 'package:open_vts/features/auth/domain/entities/user_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final Map<String, Object?> raw;

  factory AuthUser.fromRaw(Map<String, Object?> raw, {String? roleFallback}) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = raw[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    return AuthUser(
      id: pick(['id', 'userId', 'user_id', '_id', 'uuid']),
      name: pick(['name', 'fullName', 'full_name', 'username']),
      email: pick(['email', 'emailAddress']),
      role: UserRole.fromBackend(pick(['role', 'userRole', 'userType', 'type']).isEmpty ? roleFallback : pick(['role', 'userRole', 'userType', 'type'])),
      raw: raw,
    );
  }
}
