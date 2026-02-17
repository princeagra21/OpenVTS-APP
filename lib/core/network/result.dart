sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>() => null,
  };

  Object? get error => switch (this) {
    Success<T>() => null,
    Failure<T>(:final cause) => cause,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(Object error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final cause) => failure(cause),
    };
  }

  static Result<T> ok<T>(T data) => Success<T>(data);
  static Result<T> fail<T>(Object error) => Failure<T>(error);
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final Object cause;
  const Failure(this.cause);
}
