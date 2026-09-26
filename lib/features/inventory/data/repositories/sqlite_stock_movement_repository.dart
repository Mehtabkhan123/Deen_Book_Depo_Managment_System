import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/stock_movement.dart';
import '../../domain/repositories/stock_movement_repository.dart';

/// SQLite implementation of [StockMovementRepository]
class SqliteStockMovementRepository implements StockMovementRepository {
  final DatabaseHelper _dbHelper;

  SqliteStockMovementRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<StockMovement>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableStockMovements,
      orderBy: '${DbConstants.colStockMovementDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => StockMovement.fromMap(row)).toList();
  }

  @override
  Future<StockMovement?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableStockMovements,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return StockMovement.fromMap(results.first);
  }

  @override
  Future<List<StockMovement>> getByBookId(int bookId, {int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableStockMovements,
      where: '${DbConstants.colStockMovementBookId} = ?',
      whereArgs: [bookId],
      orderBy: '${DbConstants.colStockMovementDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => StockMovement.fromMap(row)).toList();
  }

  @override
  Future<int> create(StockMovement movement, {DatabaseExecutor? executor}) async {
    _validateMovement(movement);

    final now = DateTime.now().toIso8601String();
    final toInsert = movement.toMap();
    toInsert[DbConstants.colCreatedAt] = movement.createdAt.isEmpty ? now : movement.createdAt;
    toInsert[DbConstants.colStockMovementDate] =
        movement.movementDate.isEmpty ? now : movement.movementDate;
    toInsert.remove(DbConstants.colId);

    return await _dbHelper.insert(
      DbConstants.tableStockMovements,
      toInsert,
      executor: executor,
    );
  }

  @override
  Future<List<StockMovement>> getByReference(String referenceType, int referenceId) async {
    final results = await _dbHelper.query(
      DbConstants.tableStockMovements,
      where: '${DbConstants.colStockMovementReferenceType} = ? AND '
          '${DbConstants.colStockMovementReferenceId} = ?',
      whereArgs: [referenceType, referenceId],
      orderBy: '${DbConstants.colStockMovementDate} DESC',
    );
    return results.map((row) => StockMovement.fromMap(row)).toList();
  }

  void _validateMovement(StockMovement movement) {
    if (movement.bookId <= 0) {
      throw const ValidationException('A valid book ID is required for a stock movement.');
    }
    if (movement.movementType.trim().isEmpty) {
      throw const ValidationException('Movement type cannot be empty.');
    }
    if (movement.quantity <= 0) {
      throw const ValidationException('Movement quantity must be greater than zero.');
    }
    if (movement.newStock < 0) {
      throw const ValidationException('Resulting new stock cannot be negative.');
    }
  }
}
