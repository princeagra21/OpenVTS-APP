import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(false) bool isForgot,
    @Default(false) bool isForgotSubmitting,
    @Default(false) bool isLoggingIn,
    @Default(true) bool obscurePassword,
    String? forgotPasswordMessage,
    String? errorMessage,
    String? successTargetPath,
  }) = _LoginState;
}
