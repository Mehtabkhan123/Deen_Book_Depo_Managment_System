import '../../../../shared/models/customer.dart';

/// Contract for customer data access and ledger lookups
abstract class CustomerRepository {
  /// Retrieves all customers ordered by name
  Future<List<Customer>> getAll({int? limit, int? offset});

  /// Retrieves a customer by ID
  Future<Customer?> getById(int id);

  /// Creates a new customer record and returns its ID
  Future<int> create(Customer customer);

  /// Updates existing customer details
  Future<bool> update(Customer customer);

  /// Deletes a customer if no sales or payment transactions exist
  Future<bool> delete(int id);

  /// Searches customers by name or phone number
  Future<List<Customer>> search(String query);
}
