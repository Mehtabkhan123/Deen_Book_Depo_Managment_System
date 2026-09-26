import '../../../../shared/models/supplier_payment.dart';

/// Contract for supplier payments
abstract class SupplierPaymentRepository {
  /// Records a new supplier payment
  Future<int> create(SupplierPayment payment);

  /// Retrieves all supplier payments ordered by payment date descending
  Future<List<SupplierPayment>> getAll({int? limit, int? offset});

  /// Retrieves a specific payment record by ID
  Future<SupplierPayment?> getById(int id);

  /// Retrieves all payments disbursed to a specific supplier
  Future<List<SupplierPayment>> getBySupplierId(int supplierId, {int? limit, int? offset});

  /// Deletes a payment record
  Future<bool> delete(int id);
}
