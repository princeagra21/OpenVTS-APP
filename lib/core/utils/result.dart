import 'package:open_vts/core/error/app_error.dart';

sealed class Result<S, E extends AppError> {
  const Result();

  const factory Result.success(S value) = Success<S, E>;
  const factory Result.failure(E error) = Failure<S, E>;

  bool get isSuccess => this is Success<S, E>;
  bool get isFailure => this is Failure<S, E>;

  S? get valueOrNull => switch (this) {
        Success<S, E>(:final value) => value,
        Failure<S, E>() => null,
      };

  E? get errorOrNull => switch (this) {
        Success<S, E>() => null,
        Failure<S, E>(:final error) => error,
      };

  T when<T>({
    required T Function(S value) success,
    required T Function(E error) failure,
  }) {
    return switch (this) {
      Success<S, E>(:final value) => success(value),
      Failure<S, E>(:final error) => failure(error),
    };
  }
}

final class Success<S, E extends AppError> extends Result<S, E> {
  const Success(this.value);
  final S value;
}

final class Failure<S, E extends AppError> extends Result<S, E> {
  const Failure(this.error);
  final E error;
}
