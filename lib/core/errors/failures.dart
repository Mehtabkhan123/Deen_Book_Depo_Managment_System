/// Base Failure class for Clean Architecture Repositories / BLoCs
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Returned when a database read/write/transaction fails
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Returned when an entity is not found in the local repository
class RecordNotFoundFailure extends Failure {
  const RecordNotFoundFailure(super.message, {super.code});
}

/// Returned when data fails business logic validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Returned when an operation is cancelled or aborted
class OperationCancelledFailure extends Failure {
  const OperationCancelledFailure(super.message, {super.code});
}
