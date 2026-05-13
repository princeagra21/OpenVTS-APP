import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';

abstract interface class AuthRepository {
  Future<Result<LoginResponse, AppError>> login({
    required String identifier,
    required String password,
  });

  Future<Result<AuthUser?, AppError>> restoreSession();

  Future<Result<AuthUser?, AppError>> refreshSession();

  Future<Result<String, AppError>> forgotPassword({required String identifier});

  Future<Result<void, AppError>> logout();
}
