import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../shared/models/stock_movement.dart';

/// Contract for stock movement audit records
abstract class StockMovementRepository {
  /// Retrieves stock movements with optional pagination
  Future<List<StockMovement>> getAll({int? limit, int? offset});

  /// Retrieves a specific stock movement by ID
  Future<StockMovement?> getById(int id);

  /// Retrieves chronological stock movements for a specific book
  Future<List<StockMovement>> getByBookId(int bookId, {int? limit, int? offset});

  /// Inserts a stock movement audit record (can participate in a transaction)
  Future<int> create(StockMovement movement, {DatabaseExecutor? executor});

  /// Retrieves movements associated with a specific business document (e.g. 'PURCHASE', 'SALE')
  Future<List<StockMovement>> getByReference(String referenceType, int referenceId);
}
