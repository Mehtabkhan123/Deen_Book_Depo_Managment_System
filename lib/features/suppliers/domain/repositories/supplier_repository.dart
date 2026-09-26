import '../../../../shared/models/supplier.dart';

/// Contract for supplier data access and ledger lookups
abstract class SupplierRepository {
  /// Retrieves all suppliers ordered by name
  Future<List<Supplier>> getAll({int? limit, int? offset});

  /// Retrieves a supplier by ID
  Future<Supplier?> getById(int id);

  /// Creates a new supplier record and returns its ID
  Future<int> create(Supplier supplier);

  /// Updates existing supplier details
  Future<bool> update(Supplier supplier);

  /// Deletes a supplier if no purchases or payment transactions exist
  Future<bool> delete(int id);

  /// Searches suppliers by name or phone number
  Future<List<Supplier>> search(String query);
}
