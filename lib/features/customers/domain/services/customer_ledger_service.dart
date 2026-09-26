import '../../../../shared/models/customer_payment.dart';
import '../../../../shared/models/sale.dart';
import '../models/customer_ledger_entry.dart';

/// Contract for customer ledger calculations and transaction history
abstract class CustomerLedgerService {
  /// Computes real-time balance:
  /// Opening Balance + Total Sales - Total Customer Payments
  Future<double> getCustomerBalance(int customerId);

  /// Retrieves chronological statement of ledger entries with running balance
  Future<List<CustomerLedgerEntry>> getCustomerTransactions(int customerId);

  /// Retrieves all payments received from customer
  Future<List<CustomerPayment>> getCustomerPayments(int customerId);

  /// Retrieves all sales invoices billed to customer
  Future<List<Sale>> getCustomerSales(int customerId);
}
