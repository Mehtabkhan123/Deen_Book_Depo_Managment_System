import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// SQLite implementation of [ExpenseRepository]
class SqliteExpenseRepository implements ExpenseRepository {
  final DatabaseHelper _dbHelper;

  SqliteExpenseRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<int> create(Expense expense) async {
    _validateExpense(expense);

    final now = DateTime.now().toIso8601String();
    final toInsert = expense.toMap();
    toInsert[DbConstants.colCreatedAt] =
        expense.createdAt.isEmpty ? now : expense.createdAt;
    toInsert[DbConstants.colExpenseDate] =
        expense.expenseDate.isEmpty ? now : expense.expenseDate;
    toInsert[DbConstants.colUpdatedAt] = null;
    toInsert.remove(DbConstants.colId);

    return await _dbHelper.insert(DbConstants.tableExpenses, toInsert);
  }

  @override
  Future<List<Expense>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableExpenses,
      orderBy: '${DbConstants.colExpenseDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Expense.fromMap(row)).toList();
  }

  @override
  Future<Expense?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableExpenses,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Expense.fromMap(results.first);
  }

  @override
  Future<bool> update(Expense expense) async {
    if (expense.id == null) {
      throw const ValidationException('Cannot update expense without an ID.');
    }
    _validateExpense(expense);

    final toUpdate = expense.toMap();
    toUpdate[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();
    toUpdate.remove(DbConstants.colId);
    toUpdate.remove(DbConstants.colCreatedAt);

    final rowsAffected = await _dbHelper.update(
      DbConstants.tableExpenses,
      toUpdate,
      where: '${DbConstants.colId} = ?',
      whereArgs: [expense.id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Expense with ID $id not found.');
    }
    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableExpenses,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<List<Expense>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final term = '%$trimmed%';
    final results = await _dbHelper.query(
      DbConstants.tableExpenses,
      where: '${DbConstants.colExpenseTitle} LIKE ? OR ${DbConstants.colExpenseCategory} LIKE ?',
      whereArgs: [term, term],
      orderBy: '${DbConstants.colExpenseDate} DESC',
    );
    return results.map((row) => Expense.fromMap(row)).toList();
  }

  @override
  Future<List<Expense>> getByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final results = await _dbHelper.query(
      DbConstants.tableExpenses,
      where: '${DbConstants.colExpenseDate} >= ? AND ${DbConstants.colExpenseDate} <= ?',
      whereArgs: [startDate, endDate],
      orderBy: '${DbConstants.colExpenseDate} DESC',
    );
    return results.map((row) => Expense.fromMap(row)).toList();
  }

  @override
  Future<double> getTotalExpenses({
    String? startDate,
    String? endDate,
  }) async {
    String sql = 'SELECT SUM(${DbConstants.colExpenseAmount}) as total FROM ${DbConstants.tableExpenses}';
    final List<Object?> args = [];

    if (startDate != null && endDate != null) {
      sql += ' WHERE ${DbConstants.colExpenseDate} >= ? AND ${DbConstants.colExpenseDate} <= ?';
      args.addAll([startDate, endDate]);
    } else if (startDate != null) {
      sql += ' WHERE ${DbConstants.colExpenseDate} >= ?';
      args.add(startDate);
    } else if (endDate != null) {
      sql += ' WHERE ${DbConstants.colExpenseDate} <= ?';
      args.add(endDate);
    }

    final results = await _dbHelper.rawQuery(sql, args);
    if (results.isEmpty || results.first['total'] == null) {
      return 0.0;
    }
    return (results.first['total'] as num).toDouble();
  }

  void _validateExpense(Expense expense) {
    if (expense.title.trim().isEmpty) {
      throw const ValidationException('Expense title cannot be empty.');
    }
    if (expense.amount <= 0) {
      throw const ValidationException('Expense amount must be greater than zero.');
    }
  }
}
