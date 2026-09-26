import '../../../../shared/models/customer_payment.dart';

/// Contract for customer payments and receipts
abstract class CustomerPaymentRepository {
  /// Records a new customer payment
  Future<int> create(CustomerPayment payment);

  /// Retrieves all customer payments ordered by payment date descending
  Future<List<CustomerPayment>> getAll({int? limit, int? offset});

  /// Retrieves a specific payment record by ID
  Future<CustomerPayment?> getById(int id);

  /// Retrieves all payments received from a specific customer
  Future<List<CustomerPayment>> getByCustomerId(int customerId, {int? limit, int? offset});

  /// Deletes a payment record
  Future<bool> delete(int id);
}
