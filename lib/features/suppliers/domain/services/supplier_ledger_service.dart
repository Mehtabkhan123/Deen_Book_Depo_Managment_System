import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/supplier_payment.dart';
import '../models/supplier_ledger_entry.dart';

/// Contract for supplier payables, balance calculation, and statement history
abstract class SupplierLedgerService {
  /// Computes real-time balance payable:
  /// Opening Balance + Credit Purchases - Supplier Payments
  Future<double> getSupplierBalance(int supplierId);

  /// Retrieves chronological statement of supplier payables and payments with running balance
  Future<List<SupplierLedgerEntry>> getSupplierTransactions(int supplierId);

  /// Retrieves all payments disbursed to supplier
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId);

  /// Retrieves all purchase invoices from supplier
  Future<List<Purchase>> getSupplierPurchases(int supplierId);
}
