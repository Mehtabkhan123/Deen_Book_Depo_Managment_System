import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

/// SQLite implementation of [SupplierRepository]
class SqliteSupplierRepository implements SupplierRepository {
  final DatabaseHelper _dbHelper;

  SqliteSupplierRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<Supplier>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableSuppliers,
      orderBy: '${DbConstants.colSupplierName} ASC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Supplier.fromMap(row)).toList();
  }

  @override
  Future<Supplier?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableSuppliers,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Supplier.fromMap(results.first);
  }

  @override
  Future<int> create(Supplier supplier) async {
    _validateSupplier(supplier);

    final now = DateTime.now().toIso8601String();
    final toInsert = supplier.toMap();
    toInsert[DbConstants.colCreatedAt] = supplier.createdAt.isEmpty ? now : supplier.createdAt;
    toInsert[DbConstants.colUpdatedAt] = null;
    toInsert.remove(DbConstants.colId);

    return await _dbHelper.insert(DbConstants.tableSuppliers, toInsert);
  }

  @override
  Future<bool> update(Supplier supplier) async {
    if (supplier.id == null) {
      throw const ValidationException('Cannot update supplier without an ID.');
    }
    _validateSupplier(supplier);

    final toUpdate = supplier.toMap();
    toUpdate[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();
    toUpdate.remove(DbConstants.colId);
    toUpdate.remove(DbConstants.colCreatedAt);

    final rowsAffected = await _dbHelper.update(
      DbConstants.tableSuppliers,
      toUpdate,
      where: '${DbConstants.colId} = ?',
      whereArgs: [supplier.id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Supplier with ID $id not found.');
    }

    // Historical ledger safety: check purchases and supplier payments
    final purchases = await _dbHelper.query(
      DbConstants.tablePurchases,
      columns: [DbConstants.colId],
      where: '${DbConstants.colPurchaseSupplierId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (purchases.isNotEmpty) {
      throw ValidationException(
        'Cannot delete supplier "${existing.name}" because purchase invoices are linked to this supplier.',
      );
    }

    final payments = await _dbHelper.query(
      DbConstants.tableSupplierPayments,
      columns: [DbConstants.colId],
      where: '${DbConstants.colSuppPaymentSupplierId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (payments.isNotEmpty) {
      throw ValidationException(
        'Cannot delete supplier "${existing.name}" because payment transactions exist for this supplier.',
      );
    }

    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableSuppliers,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<List<Supplier>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final term = '%$trimmed%';
    final results = await _dbHelper.query(
      DbConstants.tableSuppliers,
      where: '${DbConstants.colSupplierName} LIKE ? OR '
          '${DbConstants.colSupplierPhone} LIKE ? OR '
          '${DbConstants.colSupplierEmail} LIKE ?',
      whereArgs: [term, term, term],
      orderBy: '${DbConstants.colSupplierName} ASC',
    );
    return results.map((row) => Supplier.fromMap(row)).toList();
  }

  void _validateSupplier(Supplier supplier) {
    if (supplier.name.trim().isEmpty) {
      throw const ValidationException('Supplier name cannot be empty.');
    }
    if (supplier.openingBalance < 0) {
      throw const ValidationException('Opening balance cannot be negative.');
    }
  }
}
