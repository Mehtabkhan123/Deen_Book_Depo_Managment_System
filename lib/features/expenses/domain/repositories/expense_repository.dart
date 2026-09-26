import '../../../../shared/models/expense.dart';

/// Contract for operating expense records and accounting filters
abstract class ExpenseRepository {
  /// Records a new expense entry
  Future<int> create(Expense expense);

  /// Retrieves expenses ordered by expense date descending
  Future<List<Expense>> getAll({int? limit, int? offset});

  /// Retrieves an expense by ID
  Future<Expense?> getById(int id);

  /// Updates an existing expense entry
  Future<bool> update(Expense expense);

  /// Deletes an expense entry by ID
  Future<bool> delete(int id);

  /// Searches and filters expenses by title keyword or category
  Future<List<Expense>> search(String query);

  /// Filters expenses within an ISO date range
  Future<List<Expense>> getByDateRange({
    required String startDate,
    required String endDate,
  });

  /// Calculates total expense amount, optionally within a date range
  Future<double> getTotalExpenses({
    String? startDate,
    String? endDate,
  });
}
