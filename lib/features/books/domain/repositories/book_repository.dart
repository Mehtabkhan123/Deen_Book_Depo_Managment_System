import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../shared/models/book.dart';

/// Contract for book catalog data access and inventory queries
abstract class BookRepository {
  /// Retrieves all books ordered by name
  Future<List<Book>> getAll({int? limit, int? offset});

  /// Retrieves a book by ID
  Future<Book?> getById(int id, {DatabaseExecutor? executor});

  /// Retrieves a book by its ISBN
  Future<Book?> getByIsbn(String isbn);

  /// Creates a new book record and returns its ID
  Future<int> create(Book book);

  /// Updates existing book metadata and prices
  Future<bool> update(Book book);

  /// Deletes a book if it has no existing purchase or sales transactions
  Future<bool> delete(int id);

  /// Multi-field search by name, ISBN, author, or publisher
  Future<List<Book>> search(String query);

  /// Retrieves books belonging to a specific category
  Future<List<Book>> getByCategory(int categoryId);

  /// Retrieves books whose current stock is at or below their minimum stock threshold
  Future<List<Book>> getLowStockBooks();

  /// Searches books by query and optionally filters by category
  Future<List<Book>> searchAndFilter({String? query, int? categoryId});

  /// Updates current stock quantity directly (can participate in a transaction)
  Future<bool> updateStock(int bookId, int newStock, {DatabaseExecutor? executor});
}
