import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/config/api_base_url_config.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/di/auth_providers.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';
import 'package:open_vts/features/auth/domain/use_cases/login_use_case.dart';
import 'package:open_vts/features/auth/presentation/state/login_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState();

  void showForgotPassword() => state = state.copyWith(isForgot: true, errorMessage: null);

  void showLogin() => state = state.copyWith(
        isForgot: false,
        forgotPasswordMessage: null,
        errorMessage: null,
      );

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> syncApiBaseUrl() async {
    final effectiveBaseUrl = ApiBaseUrlConfig.instance.effectiveBaseUrl;
    ref.read(authBaseUrlUpdaterProvider).updateBaseUrl(effectiveBaseUrl);
  }

  Future<Result<String, AppError>> submitForgotPassword(String identifier) async {
    if (state.isForgotSubmitting) {
      return const Result.failure(ValidationError('Forgot password request already in progress.'));
    }
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      return const Result.failure(ValidationError('Please enter your email or username.'));
    }
    state = state.copyWith(isForgotSubmitting: true, forgotPasswordMessage: null, errorMessage: null);
    final result = await ref.read(forgotPasswordUseCaseProvider)(normalized);
    return result.when(
      success: (message) {
        state = state.copyWith(isForgotSubmitting: false, forgotPasswordMessage: message);
        return Result.success(message);
      },
      failure: (error) async {
        final message = _messageFor(error, fallback: 'Unable to send reset link. Please try again.');
        state = state.copyWith(isForgotSubmitting: false, errorMessage: message);
        return Result.failure(error);
      },
    );
  }

  Future<Result<String, AppError>> submitLogin({
    required String identifier,
    required String password,
  }) async {
    if (state.isLoggingIn) {
      return const Result.failure(ValidationError('Login already in progress.'));
    }
    if (identifier.trim().isEmpty || password.trim().isEmpty) {
      return const Result.failure(ValidationError('Please enter email and password.'));
    }

    state = state.copyWith(isLoggingIn: true, errorMessage: null, successTargetPath: null);
    final result = await ref.read(loginUseCaseProvider)(
          LoginParams(identifier: identifier.trim(), password: password),
        );

    return await result.when<Future<Result<String, AppError>>>(
      success: (login) async {
        final target = _targetPathForRole(login.user.role);
        if (target == null) {
          await ref.read(logoutUseCaseProvider)();
          const error = PermissionAppError('This account role is not supported in this app.');
          state = state.copyWith(isLoggingIn: false, errorMessage: error.message);
          return const Result.failure(error);
        }

        state = state.copyWith(isLoggingIn: false, successTargetPath: target);
        return Result.success(target);
      },
      failure: (error) async {
        final message = _messageFor(
          error,
          fallback: 'Login failed. Please try again.',
          invalidCredentialsFallback: 'Invalid credentials.',
        );
        final mapped = UnknownError(message, statusCode: error.statusCode, details: error.details);
        state = state.copyWith(isLoggingIn: false, errorMessage: message);
        return Result.failure(mapped);
      },
    );
  }

  String _messageFor(
    AppError error, {
    required String fallback,
    String? invalidCredentialsFallback,
  }) {
    if ((error.statusCode == 401 || error.statusCode == 403) && invalidCredentialsFallback != null) {
      return invalidCredentialsFallback;
    }
    final message = error.message.trim();
    return message.isNotEmpty ? message : fallback;
  }

  String? _targetPathForRole(UserRole role) {
    return switch (role) {
      UserRole.superadmin => AppRoutePaths.superadminHome,
      UserRole.admin => AppRoutePaths.adminHome,
      UserRole.user || UserRole.subuser || UserRole.team || UserRole.driver => AppRoutePaths.userHome,
      UserRole.unknown => null,
    };
  }
}
