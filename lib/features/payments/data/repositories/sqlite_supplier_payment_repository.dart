import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/supplier_payment.dart';
import '../../domain/repositories/supplier_payment_repository.dart';

/// SQLite implementation of [SupplierPaymentRepository]
class SqliteSupplierPaymentRepository implements SupplierPaymentRepository {
  final DatabaseHelper _dbHelper;

  SqliteSupplierPaymentRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<int> create(SupplierPayment payment) async {
    _validatePayment(payment);

    final now = DateTime.now().toIso8601String();
    final toInsert = payment.toMap();
    toInsert[DbConstants.colCreatedAt] =
        payment.createdAt.isEmpty ? now : payment.createdAt;
    toInsert[DbConstants.colSuppPaymentDate] =
        payment.paymentDate.isEmpty ? now : payment.paymentDate;
    toInsert.remove(DbConstants.colId);

    return await _dbHelper.insert(DbConstants.tableSupplierPayments, toInsert);
  }

  @override
  Future<List<SupplierPayment>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableSupplierPayments,
      orderBy: '${DbConstants.colSuppPaymentDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => SupplierPayment.fromMap(row)).toList();
  }

  @override
  Future<SupplierPayment?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableSupplierPayments,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SupplierPayment.fromMap(results.first);
  }

  @override
  Future<List<SupplierPayment>> getBySupplierId(int supplierId, {int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableSupplierPayments,
      where: '${DbConstants.colSuppPaymentSupplierId} = ?',
      whereArgs: [supplierId],
      orderBy: '${DbConstants.colSuppPaymentDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => SupplierPayment.fromMap(row)).toList();
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Payment record with ID $id not found.');
    }
    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableSupplierPayments,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  void _validatePayment(SupplierPayment payment) {
    if (payment.supplierId <= 0) {
      throw const ValidationException('A valid supplier ID is required.');
    }
    if (payment.amount <= 0) {
      throw const ValidationException('Payment amount must be greater than zero.');
    }
    if (payment.paymentMethod.trim().isEmpty) {
      throw const ValidationException('Payment method cannot be empty.');
    }
  }
}
