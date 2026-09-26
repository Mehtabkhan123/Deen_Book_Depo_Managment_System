import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/purchase_item.dart';

/// Contract for wholesale purchases and invoice transaction management
abstract class PurchaseRepository {
  /// Executes atomic purchase creation:
  /// inserts purchase -> inserts items -> increases book stock -> logs stock movements
  Future<int> createPurchaseWithItems({
    required Purchase purchase,
    required List<PurchaseItem> items,
  });

  /// Retrieves purchase invoice by ID
  Future<Purchase?> getById(int id);

  /// Retrieves purchase invoice by unique invoice number
  Future<Purchase?> getByInvoiceNumber(String invoiceNumber);

  /// Retrieves all items belonging to a purchase invoice
  Future<List<PurchaseItem>> getItemsForPurchase(int purchaseId);

  /// Retrieves purchases ordered by date descending
  Future<List<Purchase>> getAll({int? limit, int? offset});

  /// Retrieves purchases for a specific supplier
  Future<List<Purchase>> getBySupplier(int supplierId, {int? limit, int? offset});

  /// Searches purchases by invoice number
  Future<List<Purchase>> search(String query);

  /// Updates paid and remaining amounts and payment status
  Future<bool> updatePaymentStatus({
    required int purchaseId,
    required double paidAmount,
    required double remainingAmount,
    required String paymentStatus,
  });

  /// Cancels/deletes a purchase invoice and reverses associated stock increases atomically
  Future<bool> delete(int id);
}
