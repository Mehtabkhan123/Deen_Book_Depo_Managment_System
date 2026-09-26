import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../inventory/domain/constants/stock_movement_types.dart';
import '../../../inventory/domain/services/stock_service.dart';
import '../../domain/repositories/sale_repository.dart';

/// SQLite implementation of [SaleRepository] with atomic inventory deduction
class SqliteSaleRepository implements SaleRepository {
  final DatabaseHelper _dbHelper;
  final BookRepository bookRepository;
  final StockService stockService;

  SqliteSaleRepository({
    required this.bookRepository,
    required this.stockService,
    DatabaseHelper? dbHelper,
  })  : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<int> createSaleWithItems({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    _validateSale(sale, items);

    return await _dbHelper.transaction<int>((txn) async {
      // 1. Check duplicate invoice number
      final existing = await _dbHelper.query(
        DbConstants.tableSales,
        columns: [DbConstants.colId],
        where: '${DbConstants.colSaleInvoiceNumber} = ?',
        whereArgs: [sale.invoiceNumber.trim()],
        limit: 1,
        executor: txn,
      );

      if (existing.isNotEmpty) {
        throw DuplicateInvoiceException(sale.invoiceNumber);
      }

      // 2. Pre-validate stock availability for all items before any mutation
      final requestedTotals = <int, int>{};
      for (final item in items) {
        requestedTotals[item.bookId] =
            (requestedTotals[item.bookId] ?? 0) + item.quantity;
      }
      for (final entry in requestedTotals.entries) {
        final book = await bookRepository.getById(entry.key, executor: txn);
        if (book == null) {
          throw NotFoundException('Book with ID ${entry.key} not found.');
        }
        if (book.stockQuantity < entry.value) {
          throw InsufficientStockException(
            bookId: entry.key,
            bookName: book.name,
            requestedQuantity: entry.value,
            availableStock: book.stockQuantity,
          );
        }
      }

      // 3. Insert parent sales record
      final now = DateTime.now().toIso8601String();
      final saleMap = sale.toMap();
      saleMap[DbConstants.colCreatedAt] =
          sale.createdAt.isEmpty ? now : sale.createdAt;
      saleMap[DbConstants.colSaleDate] =
          sale.saleDate.isEmpty ? now : sale.saleDate;
      saleMap[DbConstants.colUpdatedAt] = null;
      saleMap.remove(DbConstants.colId);

      final saleId = await _dbHelper.insert(
        DbConstants.tableSales,
        saleMap,
        executor: txn,
      );

      // 4. Insert items, deduct inventory, and log stock movements
      for (final item in items) {
        final itemMap = item.toMap();
        itemMap[DbConstants.colSaleItemSaleId] = saleId;
        itemMap.remove(DbConstants.colId);

        await _dbHelper.insert(
          DbConstants.tableSaleItems,
          itemMap,
          executor: txn,
        );

        await stockService.decreaseStock(
          bookId: item.bookId,
          quantity: item.quantity,
          movementType: StockMovementTypes.sale,
          referenceType: 'SALE',
          referenceId: saleId,
          notes: 'Sales invoice #${sale.invoiceNumber}',
          executor: txn,
        );
      }

      return saleId;
    });
  }

  @override
  Future<Sale?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableSales,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  @override
  Future<Sale?> getByInvoiceNumber(String invoiceNumber) async {
    final results = await _dbHelper.query(
      DbConstants.tableSales,
      where: '${DbConstants.colSaleInvoiceNumber} = ?',
      whereArgs: [invoiceNumber.trim()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Sale.fromMap(results.first);
  }

  @override
  Future<List<SaleItem>> getItemsForSale(int saleId) async {
    final results = await _dbHelper.query(
      DbConstants.tableSaleItems,
      where: '${DbConstants.colSaleItemSaleId} = ?',
      whereArgs: [saleId],
      orderBy: '${DbConstants.colId} ASC',
    );
    return results.map((row) => SaleItem.fromMap(row)).toList();
  }

  @override
  Future<List<Sale>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableSales,
      orderBy: '${DbConstants.colSaleDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Sale.fromMap(row)).toList();
  }

  @override
  Future<List<Sale>> getByCustomer(int customerId, {int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableSales,
      where: '${DbConstants.colSaleCustomerId} = ?',
      whereArgs: [customerId],
      orderBy: '${DbConstants.colSaleDate} DESC, ${DbConstants.colId} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Sale.fromMap(row)).toList();
  }

  @override
  Future<List<Sale>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final term = '%$trimmed%';
    final results = await _dbHelper.query(
      DbConstants.tableSales,
      where: '${DbConstants.colSaleInvoiceNumber} LIKE ?',
      whereArgs: [term],
      orderBy: '${DbConstants.colSaleDate} DESC',
    );
    return results.map((row) => Sale.fromMap(row)).toList();
  }

  @override
  Future<bool> updatePaymentStatus({
    required int saleId,
    required double paidAmount,
    required double remainingAmount,
    required String paymentStatus,
  }) async {
    final rowsAffected = await _dbHelper.update(
      DbConstants.tableSales,
      {
        DbConstants.colSalePaidAmount: paidAmount,
        DbConstants.colSaleRemainingAmount: remainingAmount,
        DbConstants.colSalePaymentStatus: paymentStatus,
        DbConstants.colUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [saleId],
    );
    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final sale = await getById(id);
    if (sale == null) {
      throw NotFoundException('Sale with ID $id not found.');
    }

    return await _dbHelper.transaction<bool>((txn) async {
      final items = await _dbHelper.query(
        DbConstants.tableSaleItems,
        where: '${DbConstants.colSaleItemSaleId} = ?',
        whereArgs: [id],
        executor: txn,
      );

      // Return items back to stock
      for (final row in items) {
        final item = SaleItem.fromMap(row);
        await stockService.increaseStock(
          bookId: item.bookId,
          quantity: item.quantity,
          movementType: StockMovementTypes.returnIn,
          referenceType: 'SALE_CANCELLED',
          referenceId: id,
          notes: 'Sales invoice #${sale.invoiceNumber} cancelled/deleted',
          executor: txn,
        );
      }

      final rowsAffected = await _dbHelper.delete(
        DbConstants.tableSales,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
        executor: txn,
      );
      return rowsAffected > 0;
    });
  }

  void _validateSale(Sale sale, List<SaleItem> items) {
    if (sale.invoiceNumber.trim().isEmpty) {
      throw const ValidationException('Invoice number cannot be empty.');
    }
    if (sale.saleDate.trim().isEmpty) {
      throw const ValidationException('Sale date cannot be empty.');
    }
    if (sale.discount < 0) {
      throw const ValidationException('Overall discount cannot be negative.');
    }
    if (sale.subtotal > 0 && sale.discount > sale.subtotal) {
      throw const ValidationException('Overall discount cannot exceed subtotal.');
    }
    if (sale.paidAmount < 0) {
      throw const ValidationException('Paid amount cannot be negative.');
    }
    if (sale.total > 0 && sale.paidAmount > sale.total) {
      throw const ValidationException('Paid amount cannot exceed total sale amount.');
    }
    if (items.isEmpty) {
      throw const ValidationException('Sale must contain at least one item.');
    }
    for (final item in items) {
      if (item.bookId <= 0) {
        throw const ValidationException('Each sale item must reference a valid book ID.');
      }
      if (item.quantity <= 0) {
        throw const ValidationException('Item quantity must be greater than zero.');
      }
      if (item.unitPrice < 0) {
        throw const ValidationException('Unit price cannot be negative.');
      }
      if (item.discount < 0) {
        throw const ValidationException('Item discount cannot be negative.');
      }
      final lineSubtotal = item.quantity * item.unitPrice;
      if (item.discount > lineSubtotal) {
        throw const ValidationException('Item discount cannot exceed line subtotal.');
      }
    }
  }
}
