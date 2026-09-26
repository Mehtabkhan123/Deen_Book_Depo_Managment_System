/// Base class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => '$runtimeType: $message${code != null ? ' ($code)' : ''}';
}

/// Thrown when a SQLite database operation fails
class AppDatabaseException extends AppException {
  const AppDatabaseException(super.message, {super.code, super.details});
}

/// Common alias for AppDatabaseException for clean repository layer error handling
typedef DatabaseException = AppDatabaseException;

/// Thrown when a requested record is not found in the local database
class RecordNotFoundException extends AppException {
  const RecordNotFoundException(super.message, {super.code, super.details});
}

/// Common alias for RecordNotFoundException
typedef NotFoundException = RecordNotFoundException;

/// Thrown when validation rules fail before database execution
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Thrown when an inventory deduction exceeds available physical stock
class InsufficientStockException extends AppException {
  final int bookId;
  final String bookName;
  final int requestedQuantity;
  final int availableStock;

  const InsufficientStockException({
    required this.bookId,
    required this.bookName,
    required this.requestedQuantity,
    required this.availableStock,
    String? message,
  }) : super(
          message ??
              'Insufficient stock for "$bookName" (ID: $bookId). Requested: $requestedQuantity, Available: $availableStock',
          code: 'INSUFFICIENT_STOCK',
        );
}

/// Thrown when attempting to save an invoice with an invoice number that already exists
class DuplicateInvoiceException extends AppException {
  final String invoiceNumber;

  const DuplicateInvoiceException(this.invoiceNumber, {super.details})
      : super(
          'Invoice number "$invoiceNumber" already exists. Duplicate invoices are not allowed.',
          code: 'DUPLICATE_INVOICE',
        );
}

/// Thrown when a database constraint is violated (e.g. UNIQUE constraint, foreign key restriction)
class UniqueConstraintException extends AppException {
  const UniqueConstraintException(super.message, {super.code, super.details});
}

/// Thrown when local database migration or schema creation fails
class DatabaseMigrationException extends AppException {
  const DatabaseMigrationException(super.message, {super.code, super.details});
}
