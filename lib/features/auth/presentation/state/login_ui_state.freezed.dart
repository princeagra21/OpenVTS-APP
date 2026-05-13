// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'login_ui_state.dart';

mixin _$LoginUiState {
  bool get isForgot;
  bool get isForgotSubmitting;
  bool get isLoggingIn;
  bool get obscurePassword;
  String? get forgotPasswordMessage;

  @JsonKey(ignore: true)
  $LoginUiStateCopyWith<LoginUiState> get copyWith =>
      throw _privateConstructorUsedError;
}

class _privateConstructorUsedError extends Error {
  @override
  String toString() =>
      'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.';
}

abstract class $LoginUiStateCopyWith<$Res> {
  factory $LoginUiStateCopyWith(
    LoginUiState value,
    $Res Function(LoginUiState) then,
  ) = _$LoginUiStateCopyWithImpl<$Res, LoginUiState>;
  $Res call({
    bool isForgot,
    bool isForgotSubmitting,
    bool isLoggingIn,
    bool obscurePassword,
    String? forgotPasswordMessage,
  });
}

class _$LoginUiStateCopyWithImpl<$Res, $Val extends LoginUiState>
    implements $LoginUiStateCopyWith<$Res> {
  _$LoginUiStateCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @override
  $Res call({
    Object? isForgot = null,
    Object? isForgotSubmitting = null,
    Object? isLoggingIn = null,
    Object? obscurePassword = null,
    Object? forgotPasswordMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
        isForgot: null == isForgot
            ? _value.isForgot
            : isForgot as bool,
        isForgotSubmitting: null == isForgotSubmitting
            ? _value.isForgotSubmitting
            : isForgotSubmitting as bool,
        isLoggingIn: null == isLoggingIn
            ? _value.isLoggingIn
            : isLoggingIn as bool,
        obscurePassword: null == obscurePassword
            ? _value.obscurePassword
            : obscurePassword as bool,
        forgotPasswordMessage: freezed == forgotPasswordMessage
            ? _value.forgotPasswordMessage
            : forgotPasswordMessage as String?,
      ) as $Val,
    );
  }
}

abstract class _$$LoginUiStateImplCopyWith<$Res>
    implements $LoginUiStateCopyWith<$Res> {
  factory _$$LoginUiStateImplCopyWith(
    _$LoginUiStateImpl value,
    $Res Function(_$LoginUiStateImpl) then,
  ) = __$$LoginUiStateImplCopyWithImpl<$Res>;
  @override
  $Res call({
    bool isForgot,
    bool isForgotSubmitting,
    bool isLoggingIn,
    bool obscurePassword,
    String? forgotPasswordMessage,
  });
}

class __$$LoginUiStateImplCopyWithImpl<$Res>
    extends _$LoginUiStateCopyWithImpl<$Res, _$LoginUiStateImpl>
    implements _$$LoginUiStateImplCopyWith<$Res> {
  __$$LoginUiStateImplCopyWithImpl(
    _$LoginUiStateImpl _value,
    $Res Function(_$LoginUiStateImpl) _then,
  ) : super(_value, _then);

  @override
  $Res call({
    Object? isForgot = null,
    Object? isForgotSubmitting = null,
    Object? isLoggingIn = null,
    Object? obscurePassword = null,
    Object? forgotPasswordMessage = freezed,
  }) {
    return _then(
      _$LoginUiStateImpl(
        isForgot: null == isForgot
            ? _value.isForgot
            : isForgot as bool,
        isForgotSubmitting: null == isForgotSubmitting
            ? _value.isForgotSubmitting
            : isForgotSubmitting as bool,
        isLoggingIn: null == isLoggingIn
            ? _value.isLoggingIn
            : isLoggingIn as bool,
        obscurePassword: null == obscurePassword
            ? _value.obscurePassword
            : obscurePassword as bool,
        forgotPasswordMessage: freezed == forgotPasswordMessage
            ? _value.forgotPasswordMessage
            : forgotPasswordMessage as String?,
      ),
    );
  }
}

class _$LoginUiStateImpl implements _LoginUiState {
  const _$LoginUiStateImpl({
    this.isForgot = false,
    this.isForgotSubmitting = false,
    this.isLoggingIn = false,
    this.obscurePassword = true,
    this.forgotPasswordMessage,
  });

  @override
  final bool isForgot;
  @override
  final bool isForgotSubmitting;
  @override
  final bool isLoggingIn;
  @override
  final bool obscurePassword;
  @override
  final String? forgotPasswordMessage;

  @override
  String toString() {
    return 'LoginUiState(isForgot: $isForgot, isForgotSubmitting: $isForgotSubmitting, isLoggingIn: $isLoggingIn, obscurePassword: $obscurePassword, forgotPasswordMessage: $forgotPasswordMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginUiStateImpl &&
            other.isForgot == isForgot &&
            other.isForgotSubmitting == isForgotSubmitting &&
            other.isLoggingIn == isLoggingIn &&
            other.obscurePassword == obscurePassword &&
            other.forgotPasswordMessage == forgotPasswordMessage);
  }

  @override
  int get hashCode => Object.hash(
        runtimeType,
        isForgot,
        isForgotSubmitting,
        isLoggingIn,
        obscurePassword,
        forgotPasswordMessage,
      );

  @JsonKey(ignore: true)
  @override
  _$$LoginUiStateImplCopyWith<_$LoginUiStateImpl> get copyWith =>
      __$$LoginUiStateImplCopyWithImpl<_$LoginUiStateImpl>(this, (i) => i);
}

abstract class _LoginUiState implements LoginUiState {
  const factory _LoginUiState({
    final bool isForgot,
    final bool isForgotSubmitting,
    final bool isLoggingIn,
    final bool obscurePassword,
    final String? forgotPasswordMessage,
  }) = _$LoginUiStateImpl;

  @override
  bool get isForgot;
  @override
  bool get isForgotSubmitting;
  @override
  bool get isLoggingIn;
  @override
  bool get obscurePassword;
  @override
  String? get forgotPasswordMessage;
  @override
  @JsonKey(ignore: true)
  _$$LoginUiStateImplCopyWith<_$LoginUiStateImpl> get copyWith;
}
