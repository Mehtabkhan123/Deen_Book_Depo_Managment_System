import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';

/// Contract for wholesale sales and invoice transaction management
abstract class SaleRepository {
  /// Executes atomic sale creation:
  /// validates stock -> inserts sale -> inserts sale items -> decreases stock -> logs stock movements
  /// Throws [InsufficientStockException] if any item lacks sufficient stock
  Future<int> createSaleWithItems({
    required Sale sale,
    required List<SaleItem> items,
  });

  /// Retrieves sales invoice by ID
  Future<Sale?> getById(int id);

  /// Retrieves sales invoice by unique invoice number
  Future<Sale?> getByInvoiceNumber(String invoiceNumber);

  /// Retrieves all items belonging to a sales invoice
  Future<List<SaleItem>> getItemsForSale(int saleId);

  /// Retrieves sales invoices ordered by date descending
  Future<List<Sale>> getAll({int? limit, int? offset});

  /// Retrieves sales invoices for a specific customer
  Future<List<Sale>> getByCustomer(int customerId, {int? limit, int? offset});

  /// Searches sales invoices by invoice number
  Future<List<Sale>> search(String query);

  /// Updates paid and remaining amounts and payment status
  Future<bool> updatePaymentStatus({
    required int saleId,
    required double paidAmount,
    required double remainingAmount,
    required String paymentStatus,
  });

  /// Cancels/deletes a sale invoice and returns stock back to inventory atomically
  Future<bool> delete(int id);
}
