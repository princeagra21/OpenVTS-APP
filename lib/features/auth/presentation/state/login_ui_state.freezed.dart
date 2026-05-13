// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoginUiState {
  bool get isForgot;
  bool get isForgotSubmitting;
  bool get isLoggingIn;
  bool get obscurePassword;
  String? get forgotPasswordMessage;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LoginUiStateCopyWith<LoginUiState> get copyWith =>
      _$LoginUiStateCopyWithImpl<LoginUiState>(
          this as LoginUiState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LoginUiState &&
            (identical(other.isForgot, isForgot) ||
                other.isForgot == isForgot) &&
            (identical(other.isForgotSubmitting, isForgotSubmitting) ||
                other.isForgotSubmitting == isForgotSubmitting) &&
            (identical(other.isLoggingIn, isLoggingIn) ||
                other.isLoggingIn == isLoggingIn) &&
            (identical(other.obscurePassword, obscurePassword) ||
                other.obscurePassword == obscurePassword) &&
            (identical(other.forgotPasswordMessage, forgotPasswordMessage) ||
                other.forgotPasswordMessage == forgotPasswordMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isForgot, isForgotSubmitting,
      isLoggingIn, obscurePassword, forgotPasswordMessage);

  @override
  String toString() {
    return 'LoginUiState(isForgot: $isForgot, isForgotSubmitting: $isForgotSubmitting, isLoggingIn: $isLoggingIn, obscurePassword: $obscurePassword, forgotPasswordMessage: $forgotPasswordMessage)';
  }
}

/// @nodoc
abstract mixin class $LoginUiStateCopyWith<$Res> {
  factory $LoginUiStateCopyWith(
          LoginUiState value, $Res Function(LoginUiState) _then) =
      _$LoginUiStateCopyWithImpl;
  @useResult
  $Res call(
      {bool isForgot,
      bool isForgotSubmitting,
      bool isLoggingIn,
      bool obscurePassword,
      String? forgotPasswordMessage});
}

/// @nodoc
class _$LoginUiStateCopyWithImpl<$Res> implements $LoginUiStateCopyWith<$Res> {
  _$LoginUiStateCopyWithImpl(this._self, this._then);

  final LoginUiState _self;
  final $Res Function(LoginUiState) _then;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isForgot = null,
    Object? isForgotSubmitting = null,
    Object? isLoggingIn = null,
    Object? obscurePassword = null,
    Object? forgotPasswordMessage = freezed,
  }) {
    return _then(_self.copyWith(
      isForgot: null == isForgot
          ? _self.isForgot
          : isForgot // ignore: cast_nullable_to_non_nullable
              as bool,
      isForgotSubmitting: null == isForgotSubmitting
          ? _self.isForgotSubmitting
          : isForgotSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoggingIn: null == isLoggingIn
          ? _self.isLoggingIn
          : isLoggingIn // ignore: cast_nullable_to_non_nullable
              as bool,
      obscurePassword: null == obscurePassword
          ? _self.obscurePassword
          : obscurePassword // ignore: cast_nullable_to_non_nullable
              as bool,
      forgotPasswordMessage: freezed == forgotPasswordMessage
          ? _self.forgotPasswordMessage
          : forgotPasswordMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [LoginUiState].
extension LoginUiStatePatterns on LoginUiState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LoginUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_LoginUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LoginUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(bool isForgot, bool isForgotSubmitting, bool isLoggingIn,
            bool obscurePassword, String? forgotPasswordMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
        return $default(
            _that.isForgot,
            _that.isForgotSubmitting,
            _that.isLoggingIn,
            _that.obscurePassword,
            _that.forgotPasswordMessage);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(bool isForgot, bool isForgotSubmitting, bool isLoggingIn,
            bool obscurePassword, String? forgotPasswordMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState():
        return $default(
            _that.isForgot,
            _that.isForgotSubmitting,
            _that.isLoggingIn,
            _that.obscurePassword,
            _that.forgotPasswordMessage);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(bool isForgot, bool isForgotSubmitting, bool isLoggingIn,
            bool obscurePassword, String? forgotPasswordMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
        return $default(
            _that.isForgot,
            _that.isForgotSubmitting,
            _that.isLoggingIn,
            _that.obscurePassword,
            _that.forgotPasswordMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LoginUiState implements LoginUiState {
  const _LoginUiState(
      {this.isForgot = false,
      this.isForgotSubmitting = false,
      this.isLoggingIn = false,
      this.obscurePassword = true,
      this.forgotPasswordMessage});

  @override
  @JsonKey()
  final bool isForgot;
  @override
  @JsonKey()
  final bool isForgotSubmitting;
  @override
  @JsonKey()
  final bool isLoggingIn;
  @override
  @JsonKey()
  final bool obscurePassword;
  @override
  final String? forgotPasswordMessage;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LoginUiStateCopyWith<_LoginUiState> get copyWith =>
      __$LoginUiStateCopyWithImpl<_LoginUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LoginUiState &&
            (identical(other.isForgot, isForgot) ||
                other.isForgot == isForgot) &&
            (identical(other.isForgotSubmitting, isForgotSubmitting) ||
                other.isForgotSubmitting == isForgotSubmitting) &&
            (identical(other.isLoggingIn, isLoggingIn) ||
                other.isLoggingIn == isLoggingIn) &&
            (identical(other.obscurePassword, obscurePassword) ||
                other.obscurePassword == obscurePassword) &&
            (identical(other.forgotPasswordMessage, forgotPasswordMessage) ||
                other.forgotPasswordMessage == forgotPasswordMessage));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isForgot, isForgotSubmitting,
      isLoggingIn, obscurePassword, forgotPasswordMessage);

  @override
  String toString() {
    return 'LoginUiState(isForgot: $isForgot, isForgotSubmitting: $isForgotSubmitting, isLoggingIn: $isLoggingIn, obscurePassword: $obscurePassword, forgotPasswordMessage: $forgotPasswordMessage)';
  }
}

/// @nodoc
abstract mixin class _$LoginUiStateCopyWith<$Res>
    implements $LoginUiStateCopyWith<$Res> {
  factory _$LoginUiStateCopyWith(
          _LoginUiState value, $Res Function(_LoginUiState) _then) =
      __$LoginUiStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isForgot,
      bool isForgotSubmitting,
      bool isLoggingIn,
      bool obscurePassword,
      String? forgotPasswordMessage});
}

/// @nodoc
class __$LoginUiStateCopyWithImpl<$Res>
    implements _$LoginUiStateCopyWith<$Res> {
  __$LoginUiStateCopyWithImpl(this._self, this._then);

  final _LoginUiState _self;
  final $Res Function(_LoginUiState) _then;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isForgot = null,
    Object? isForgotSubmitting = null,
    Object? isLoggingIn = null,
    Object? obscurePassword = null,
    Object? forgotPasswordMessage = freezed,
  }) {
    return _then(_LoginUiState(
      isForgot: null == isForgot
          ? _self.isForgot
          : isForgot // ignore: cast_nullable_to_non_nullable
              as bool,
      isForgotSubmitting: null == isForgotSubmitting
          ? _self.isForgotSubmitting
          : isForgotSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoggingIn: null == isLoggingIn
          ? _self.isLoggingIn
          : isLoggingIn // ignore: cast_nullable_to_non_nullable
              as bool,
      obscurePassword: null == obscurePassword
          ? _self.obscurePassword
          : obscurePassword // ignore: cast_nullable_to_non_nullable
              as bool,
      forgotPasswordMessage: freezed == forgotPasswordMessage
          ? _self.forgotPasswordMessage
          : forgotPasswordMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
