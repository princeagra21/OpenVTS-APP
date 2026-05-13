// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'login_state.dart';

mixin _$LoginState {
  bool get isForgot;
  bool get isForgotSubmitting;
  bool get isLoggingIn;
  bool get obscurePassword;
  String? get forgotPasswordMessage;
  String? get errorMessage;
  String? get successTargetPath;
  LoginState copyWith({
    bool? isForgot,
    bool? isForgotSubmitting,
    bool? isLoggingIn,
    bool? obscurePassword,
    String? forgotPasswordMessage,
    String? errorMessage,
    String? successTargetPath,
  });
}

class _LoginState implements LoginState {
  const _LoginState({
    this.isForgot = false,
    this.isForgotSubmitting = false,
    this.isLoggingIn = false,
    this.obscurePassword = true,
    this.forgotPasswordMessage,
    this.errorMessage,
    this.successTargetPath,
  });

  @override final bool isForgot;
  @override final bool isForgotSubmitting;
  @override final bool isLoggingIn;
  @override final bool obscurePassword;
  @override final String? forgotPasswordMessage;
  @override final String? errorMessage;
  @override final String? successTargetPath;

  @override
  LoginState copyWith({
    bool? isForgot,
    bool? isForgotSubmitting,
    bool? isLoggingIn,
    bool? obscurePassword,
    Object? forgotPasswordMessage = _sentinel,
    Object? errorMessage = _sentinel,
    Object? successTargetPath = _sentinel,
  }) {
    return _LoginState(
      isForgot: isForgot ?? this.isForgot,
      isForgotSubmitting: isForgotSubmitting ?? this.isForgotSubmitting,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      forgotPasswordMessage: identical(forgotPasswordMessage, _sentinel) ? this.forgotPasswordMessage : forgotPasswordMessage as String?,
      errorMessage: identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      successTargetPath: identical(successTargetPath, _sentinel) ? this.successTargetPath : successTargetPath as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is _LoginState &&
      other.isForgot == isForgot &&
      other.isForgotSubmitting == isForgotSubmitting &&
      other.isLoggingIn == isLoggingIn &&
      other.obscurePassword == obscurePassword &&
      other.forgotPasswordMessage == forgotPasswordMessage &&
      other.errorMessage == errorMessage &&
      other.successTargetPath == successTargetPath;

  @override
  int get hashCode => Object.hash(isForgot, isForgotSubmitting, isLoggingIn, obscurePassword, forgotPasswordMessage, errorMessage, successTargetPath);
}

const Object _sentinel = Object();
