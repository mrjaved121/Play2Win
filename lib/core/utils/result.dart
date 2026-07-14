import '../error/failure.dart';

/// Lightweight `Either`-style result type for use cases and repositories,
/// so failures are values (exhaustively switchable) instead of thrown
/// exceptions crossing architecture layers.
///
/// ```dart
/// final Result<int> result = await placeBetUseCase(amount: 20);
/// switch (result) {
///   case Ok<int>(:final value): ...
///   case Err<int>(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Collapses both branches into a single value.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onErr(failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
