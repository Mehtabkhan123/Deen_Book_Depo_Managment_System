import '../../../../shared/models/category.dart';

/// Contract for category data access operations
abstract class CategoryRepository {
  /// Retrieves all categories ordered by name
  Future<List<Category>> getAll({int? limit, int? offset});

  /// Retrieves a category by its primary key ID
  Future<Category?> getById(int id);

  /// Retrieves a category by its unique name
  Future<Category?> getByName(String name);

  /// Creates a new category and returns its generated ID
  Future<int> create(Category category);

  /// Updates an existing category. Returns true if updated.
  Future<bool> update(Category category);

  /// Deletes a category by ID. Returns true if deleted.
  Future<bool> delete(int id);

  /// Searches categories by name using safe parameterized matching
  Future<List<Category>> search(String query);
}
