import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/customer_payment.dart';
import '../../domain/repositories/customer_payment_repository.dart';

/// SQLite implementation of [CustomerPaymentRepository]
class SqliteCustomerPaymentRepository implements CustomerPaymentRepository {
  final DatabaseHelper _dbHelper;

  SqliteCustomerPaymentRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<int> create(CustomerPayment payment) async {
    _validatePayment(payment);

    final now = DateTime.now().toIso8601String();
    final toInsert = payment.toMap();
    toInsert[DbConstants.colCreatedAt] =
        payment.createdAt.isEmpty ? now : payment.createdAt;
    toInsert[DbConstants.colCustPaymentDate] =
        payment.paymentDate.isEmpty ? now : payment.paymentDate;
    toInsert.remove(DbConstants.colId);

    return await _dbHelper.insert(DbConstants.tableCustomerPayments, toInsert);
  }

  @override
  Future<List<CustomerPayment>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableCustomerPayments,
      orderBy: '${DbConstants.colCustPaymentDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => CustomerPayment.fromMap(row)).toList();
  }

  @override
  Future<CustomerPayment?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableCustomerPayments,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CustomerPayment.fromMap(results.first);
  }

  @override
  Future<List<CustomerPayment>> getByCustomerId(int customerId, {int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableCustomerPayments,
      where: '${DbConstants.colCustPaymentCustomerId} = ?',
      whereArgs: [customerId],
      orderBy: '${DbConstants.colCustPaymentDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => CustomerPayment.fromMap(row)).toList();
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Payment record with ID $id not found.');
    }
    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableCustomerPayments,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  void _validatePayment(CustomerPayment payment) {
    if (payment.customerId <= 0) {
      throw const ValidationException('A valid customer ID is required.');
    }
    if (payment.amount <= 0) {
      throw const ValidationException('Payment amount must be greater than zero.');
    }
    if (payment.paymentMethod.trim().isEmpty) {
      throw const ValidationException('Payment method cannot be empty.');
    }
  }
}
