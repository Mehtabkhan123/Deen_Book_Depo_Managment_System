import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/purchase_item.dart';
import '../../../inventory/domain/constants/stock_movement_types.dart';
import '../../../inventory/domain/services/stock_service.dart';
import '../../domain/repositories/purchase_repository.dart';

/// SQLite implementation of [PurchaseRepository] with atomic multi-step transactions
class SqlitePurchaseRepository implements PurchaseRepository {
  final DatabaseHelper _dbHelper;
  final StockService stockService;

  SqlitePurchaseRepository({
    required this.stockService,
    DatabaseHelper? dbHelper,
  })  : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<int> createPurchaseWithItems({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    _validatePurchase(purchase, items);

    return await _dbHelper.transaction<int>((txn) async {
      // 1. Check duplicate invoice number
      final existing = await _dbHelper.query(
        DbConstants.tablePurchases,
        columns: [DbConstants.colId],
        where: '${DbConstants.colPurchaseInvoiceNumber} = ?',
        whereArgs: [purchase.invoiceNumber.trim()],
        limit: 1,
        executor: txn,
      );

      if (existing.isNotEmpty) {
        throw DuplicateInvoiceException(purchase.invoiceNumber);
      }

      // 2. Insert parent purchase record
      final now = DateTime.now().toIso8601String();
      final purchaseMap = purchase.toMap();
      purchaseMap[DbConstants.colCreatedAt] =
          purchase.createdAt.isEmpty ? now : purchase.createdAt;
      purchaseMap[DbConstants.colPurchaseDate] =
          purchase.purchaseDate.isEmpty ? now : purchase.purchaseDate;
      purchaseMap[DbConstants.colUpdatedAt] = null;
      purchaseMap.remove(DbConstants.colId);

      final purchaseId = await _dbHelper.insert(
        DbConstants.tablePurchases,
        purchaseMap,
        executor: txn,
      );

      // 3. Insert purchase items, increase inventory, and log stock movements
      for (final item in items) {
        final itemMap = item.toMap();
        itemMap[DbConstants.colPurchaseItemPurchaseId] = purchaseId;
        itemMap.remove(DbConstants.colId);

        await _dbHelper.insert(
          DbConstants.tablePurchaseItems,
          itemMap,
          executor: txn,
        );

        await stockService.increaseStock(
          bookId: item.bookId,
          quantity: item.quantity,
          movementType: StockMovementTypes.purchase,
          referenceType: 'PURCHASE',
          referenceId: purchaseId,
          notes: 'Purchase invoice #${purchase.invoiceNumber}',
          executor: txn,
        );
      }

      return purchaseId;
    });
  }

  @override
  Future<Purchase?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tablePurchases,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Purchase.fromMap(results.first);
  }

  @override
  Future<Purchase?> getByInvoiceNumber(String invoiceNumber) async {
    final results = await _dbHelper.query(
      DbConstants.tablePurchases,
      where: '${DbConstants.colPurchaseInvoiceNumber} = ?',
      whereArgs: [invoiceNumber.trim()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Purchase.fromMap(results.first);
  }

  @override
  Future<List<PurchaseItem>> getItemsForPurchase(int purchaseId) async {
    final results = await _dbHelper.query(
      DbConstants.tablePurchaseItems,
      where: '${DbConstants.colPurchaseItemPurchaseId} = ?',
      whereArgs: [purchaseId],
      orderBy: '${DbConstants.colId} ASC',
    );
    return results.map((row) => PurchaseItem.fromMap(row)).toList();
  }

  @override
  Future<List<Purchase>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tablePurchases,
      orderBy: '${DbConstants.colPurchaseDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Purchase.fromMap(row)).toList();
  }

  @override
  Future<List<Purchase>> getBySupplier(int supplierId, {int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tablePurchases,
      where: '${DbConstants.colPurchaseSupplierId} = ?',
      whereArgs: [supplierId],
      orderBy: '${DbConstants.colPurchaseDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Purchase.fromMap(row)).toList();
  }

  @override
  Future<List<Purchase>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final term = '%$trimmed%';
    final results = await _dbHelper.query(
      DbConstants.tablePurchases,
      where: '${DbConstants.colPurchaseInvoiceNumber} LIKE ?',
      whereArgs: [term],
      orderBy: '${DbConstants.colPurchaseDate} DESC',
    );
    return results.map((row) => Purchase.fromMap(row)).toList();
  }

  @override
  Future<bool> updatePaymentStatus({
    required int purchaseId,
    required double paidAmount,
    required double remainingAmount,
    required String paymentStatus,
  }) async {
    final rowsAffected = await _dbHelper.update(
      DbConstants.tablePurchases,
      {
        DbConstants.colPurchasePaidAmount: paidAmount,
        DbConstants.colPurchaseRemainingAmount: remainingAmount,
        DbConstants.colPurchasePaymentStatus: paymentStatus,
        DbConstants.colUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [purchaseId],
    );
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final purchase = await getById(id);
    if (purchase == null) {
      throw NotFoundException('Purchase with ID $id not found.');
    }

    return await _dbHelper.transaction<bool>((txn) async {
      final items = await _dbHelper.query(
        DbConstants.tablePurchaseItems,
        where: '${DbConstants.colPurchaseItemPurchaseId} = ?',
        whereArgs: [id],
        executor: txn,
      );

      // Reversing stock for deleted purchase invoice
      for (final row in items) {
        final item = PurchaseItem.fromMap(row);
        await stockService.decreaseStock(
          bookId: item.bookId,
          quantity: item.quantity,
          movementType: StockMovementTypes.adjustmentOut,
          referenceType: 'PURCHASE_CANCELLED',
          referenceId: id,
          notes: 'Purchase invoice #${purchase.invoiceNumber} cancelled/deleted',
          executor: txn,
        );
      }

      final rowsAffected = await _dbHelper.delete(
        DbConstants.tablePurchases,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
        executor: txn,
      );
      return rowsAffected > 0;
    });
  }

  void _validatePurchase(Purchase purchase, List<PurchaseItem> items) {
    if (purchase.supplierId <= 0) {
      throw const ValidationException('A valid supplier ID is required for a purchase.');
    }
    if (purchase.invoiceNumber.trim().isEmpty) {
      throw const ValidationException('Invoice number cannot be empty.');
    }
    if (items.isEmpty) {
      throw const ValidationException('Purchase must contain at least one item.');
    }
    for (final item in items) {
      if (item.bookId <= 0) {
        throw const ValidationException('Each purchase item must reference a valid book ID.');
      }
      if (item.quantity <= 0) {
        throw const ValidationException('Item quantity must be greater than zero.');
      }
      if (item.unitPrice < 0) {
        throw const ValidationException('Unit price cannot be negative.');
      }
    }
  }
}
