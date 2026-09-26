import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/customer.dart';
import '../../domain/repositories/customer_repository.dart';

/// SQLite implementation of [CustomerRepository]
class SqliteCustomerRepository implements CustomerRepository {
  final DatabaseHelper _dbHelper;

  SqliteCustomerRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<Customer>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableCustomers,
      orderBy: '${DbConstants.colCustomerName} ASC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Customer.fromMap(row)).toList();
  }

  @override
  Future<Customer?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableCustomers,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  @override
  Future<int> create(Customer customer) async {
    _validateCustomer(customer);

    final now = DateTime.now().toIso8601String();
    final toInsert = customer.toMap();
    toInsert[DbConstants.colCreatedAt] = customer.createdAt.isEmpty ? now : customer.createdAt;
    toInsert[DbConstants.colUpdatedAt] = null;
    toInsert.remove(DbConstants.colId);

    return await _dbHelper.insert(DbConstants.tableCustomers, toInsert);
  }

  @override
  Future<bool> update(Customer customer) async {
    if (customer.id == null) {
      throw const ValidationException('Cannot update customer without an ID.');
    }
    _validateCustomer(customer);

    final toUpdate = customer.toMap();
    toUpdate[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();
    toUpdate.remove(DbConstants.colId);
    toUpdate.remove(DbConstants.colCreatedAt);

    final rowsAffected = await _dbHelper.update(
      DbConstants.tableCustomers,
      toUpdate,
      where: '${DbConstants.colId} = ?',
      whereArgs: [customer.id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Customer with ID $id not found.');
    }

    // Historical ledger safety: check sales and customer payments
    final sales = await _dbHelper.query(
      DbConstants.tableSales,
      columns: [DbConstants.colId],
      where: '${DbConstants.colSaleCustomerId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (sales.isNotEmpty) {
      throw ValidationException(
        'Cannot delete customer "${existing.name}" because sales transactions exist for this account.',
      );
    }

    final payments = await _dbHelper.query(
      DbConstants.tableCustomerPayments,
      columns: [DbConstants.colId],
      where: '${DbConstants.colCustPaymentCustomerId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (payments.isNotEmpty) {
      throw ValidationException(
        'Cannot delete customer "${existing.name}" because payment records exist for this account.',
      );
    }

    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableCustomers,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<List<Customer>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final term = '%$trimmed%';
    final results = await _dbHelper.query(
      DbConstants.tableCustomers,
      where: '${DbConstants.colCustomerName} LIKE ? OR '
          '${DbConstants.colCustomerPhone} LIKE ? OR '
          '${DbConstants.colCustomerEmail} LIKE ?',
      whereArgs: [term, term, term],
      orderBy: '${DbConstants.colCustomerName} ASC',
    );
    return results.map((row) => Customer.fromMap(row)).toList();
  }

  void _validateCustomer(Customer customer) {
    if (customer.name.trim().isEmpty) {
      throw const ValidationException('Customer name cannot be empty.');
    }
    if (customer.openingBalance < 0) {
      throw const ValidationException('Opening balance cannot be negative.');
    }
  }
}
