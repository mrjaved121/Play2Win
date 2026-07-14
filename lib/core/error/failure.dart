/// Base type for expected, recoverable failures surfaced from the domain
/// layer. Use case / repository return values wrap these in [Result]
/// (see `core/utils/result.dart`) instead of throwing, so presentation
/// code can exhaustively `switch` on failure kind.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Local persistence (Hive) read/write failed.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read or write local data.']);
}

/// A REST/Firebase call failed (offline, timeout, non-2xx, etc).
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network request failed.']);
}

/// Input/state didn't satisfy a business rule (e.g. bet exceeds balance).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Catch-all for anything unexpected; the original error is preserved for
/// logging but never shown to the user directly.
final class UnknownFailure extends Failure {
  const UnknownFailure(this.cause, [super.message = 'Something went wrong.']);

  final Object cause;
}
