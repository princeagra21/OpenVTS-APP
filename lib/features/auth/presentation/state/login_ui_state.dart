import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_ui_state.freezed.dart';

@freezed
abstract class LoginUiState with _$LoginUiState {
  const factory LoginUiState({
    @Default(false) bool isForgot,
    @Default(false) bool isForgotSubmitting,
    @Default(false) bool isLoggingIn,
    @Default(true) bool obscurePassword,
    String? forgotPasswordMessage,
  }) = _LoginUiState;
}
