import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../errors/exceptions.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';

/// Database Helper providing clean data-access primitives, transaction execution,
/// and low-level exception normalization.
class DatabaseHelper {
  final DatabaseService _dbService;

  DatabaseHelper([DatabaseService? dbService])
      : _dbService = dbService ?? DatabaseService.instance;

  Database get _db => _dbService.database;

  DatabaseExecutor _resolveExecutor(DatabaseExecutor? executor) => executor ?? _db;

  /// Inserts a row into [table] and returns the inserted auto-generated row ID.
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
    DatabaseExecutor? executor,
  }) async {
    try {
      final exec = _resolveExecutor(executor);
      final id = await exec.insert(
        table,
        values,
        conflictAlgorithm: conflictAlgorithm,
      );
      AppLogger.debug('Inserted row into $table with ID: $id');
      return id;
    } catch (e, stack) {
      _handleDatabaseException('insert into $table', e, stack);
    }
  }

  /// Updates rows in [table] matching [where] clause and returns number of affected rows.
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
    DatabaseExecutor? executor,
  }) async {
    try {
      final exec = _resolveExecutor(executor);
      final count = await exec.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm,
      );
      AppLogger.debug('Updated $count rows in $table');
      return count;
    } catch (e, stack) {
      _handleDatabaseException('update $table', e, stack);
    }
  }

  /// Deletes rows in [table] matching [where] clause and returns number of affected rows.
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    DatabaseExecutor? executor,
  }) async {
    try {
      final exec = _resolveExecutor(executor);
      final count = await exec.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      AppLogger.debug('Deleted $count rows from $table');
      return count;
    } catch (e, stack) {
      _handleDatabaseException('delete from $table', e, stack);
    }
  }

  /// Queries [table] with standard filtering and ordering.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    DatabaseExecutor? executor,
  }) async {
    try {
      final exec = _resolveExecutor(executor);
      return await exec.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e, stack) {
      _handleDatabaseException('query $table', e, stack);
    }
  }

  /// Executes raw SQL query with safe parameterized arguments.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
    DatabaseExecutor? executor,
  ]) async {
    try {
      final exec = _resolveExecutor(executor);
      return await exec.rawQuery(sql, arguments);
    } catch (e, stack) {
      _handleDatabaseException('rawQuery ($sql)', e, stack);
    }
  }

  /// Executes operations in an atomic SQLite transaction.
  /// If any error or exception occurs, the transaction is automatically rolled back.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      return await _db.transaction<T>(action);
    } catch (e, stack) {
      if (e is AppException) {
        rethrow;
      }
      _handleDatabaseException('transaction', e, stack);
    }
  }

  /// Executes a batch of operations.
  Future<List<Object?>> executeBatch(
    void Function(Batch batch) batchOperation, {
    bool noResult = false,
    DatabaseExecutor? executor,
  }) async {
    try {
      final exec = _resolveExecutor(executor);
      final batch = exec.batch();
      batchOperation(batch);
      return await batch.commit(noResult: noResult);
    } catch (e, stack) {
      _handleDatabaseException('batch execution', e, stack);
    }
  }

  /// Normalizes low-level SQLite exceptions into typed application exceptions.
  Never _handleDatabaseException(String operation, Object e, StackTrace stack) {
    AppLogger.error('Failed to $operation: $e', e, stack);
    final errorStr = e.toString();
    if (errorStr.contains('UNIQUE constraint failed')) {
      throw UniqueConstraintException(
        'A record with this unique value already exists ($operation)',
        details: e,
      );
    }
    throw AppDatabaseException(
      'Database operation failed during $operation: $e',
      details: e,
    );
  }
}
