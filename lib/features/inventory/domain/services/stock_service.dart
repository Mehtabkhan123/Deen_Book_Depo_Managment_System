import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/stock_movement.dart';

/// Contract for inventory stock control, adjustments, and movement audits
abstract class StockService {
  /// Returns the current real-time stock quantity for a book
  Future<int> getCurrentStock(int bookId, {DatabaseExecutor? executor});

  /// Atomically increases stock and writes a corresponding stock movement record
  Future<StockMovement> increaseStock({
    required int bookId,
    required int quantity,
    required String movementType,
    String? referenceType,
    int? referenceId,
    String? notes,
    DatabaseExecutor? executor,
  });

  /// Atomically validates and decreases stock, writing a corresponding movement record
  /// Throws [InsufficientStockException] if quantity exceeds available stock
  Future<StockMovement> decreaseStock({
    required int bookId,
    required int quantity,
    required String movementType,
    String? referenceType,
    int? referenceId,
    String? notes,
    DatabaseExecutor? executor,
  });

  /// Adjusts stock to an explicit new quantity (creates ADJUSTMENT_IN or ADJUSTMENT_OUT)
  Future<StockMovement> adjustStock({
    required int bookId,
    required int newQuantity,
    String? notes,
    DatabaseExecutor? executor,
  });

  /// Retrieves chronological movement audit trail
  Future<List<StockMovement>> getStockMovements({int? limit, int? offset});

  /// Retrieves movement history for a specific book
  Future<List<StockMovement>> getMovementsForBook(int bookId, {int? limit, int? offset});

  /// Retrieves all books whose stock is at or below minimum threshold
  Future<List<Book>> getLowStockBooks();
}
