import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/category.dart';
import '../../domain/repositories/category_repository.dart';

/// SQLite implementation of [CategoryRepository]
class SqliteCategoryRepository implements CategoryRepository {
  final DatabaseHelper _dbHelper;

  SqliteCategoryRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<Category>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableCategories,
      orderBy: '${DbConstants.colCategoryName} ASC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Category.fromMap(row)).toList();
  }

  @override
  Future<Category?> getById(int id) async {
    final results = await _dbHelper.query(
      DbConstants.tableCategories,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  @override
  Future<Category?> getByName(String name) async {
    final results = await _dbHelper.query(
      DbConstants.tableCategories,
      where: 'LOWER(${DbConstants.colCategoryName}) = LOWER(?)',
      whereArgs: [name.trim()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  @override
  Future<int> create(Category category) async {
    _validateCategory(category);

    final now = DateTime.now().toIso8601String();
    final toInsert = category.toMap();
    toInsert[DbConstants.colCreatedAt] = category.createdAt.isEmpty ? now : category.createdAt;
    toInsert[DbConstants.colUpdatedAt] = null;
    toInsert.remove(DbConstants.colId);

    try {
      return await _dbHelper.insert(DbConstants.tableCategories, toInsert);
    } on UniqueConstraintException {
      throw ValidationException('A category named "${category.name}" already exists.');
    }
  }

  @override
  Future<bool> update(Category category) async {
    if (category.id == null) {
      throw const ValidationException('Cannot update category without an ID.');
    }
    _validateCategory(category);

    final toUpdate = category.toMap();
    toUpdate[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();
    toUpdate.remove(DbConstants.colId);
    toUpdate.remove(DbConstants.colCreatedAt);

    try {
      final rowsAffected = await _dbHelper.update(
        DbConstants.tableCategories,
        toUpdate,
        where: '${DbConstants.colId} = ?',
        whereArgs: [category.id],
      );
      return rowsAffected > 0;
    } on UniqueConstraintException {
      throw ValidationException('A category named "${category.name}" already exists.');
    }
  }

  @override
  Future<bool> delete(int id) async {
    // Check if category exists
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Category with ID $id not found.');
    }

    // Check foreign key constraint before attempting deletion
    final books = await _dbHelper.query(
      DbConstants.tableBooks,
      columns: [DbConstants.colId],
      where: '${DbConstants.colBookCategoryId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (books.isNotEmpty) {
      throw ValidationException(
        'Cannot delete category "${existing.name}" because books are assigned to it.',
      );
    }

    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableCategories,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<List<Category>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final results = await _dbHelper.query(
      DbConstants.tableCategories,
      where: '${DbConstants.colCategoryName} LIKE ?',
      whereArgs: ['%$trimmed%'],
      orderBy: '${DbConstants.colCategoryName} ASC',
    );
    return results.map((row) => Category.fromMap(row)).toList();
  }

  void _validateCategory(Category category) {
    if (category.name.trim().isEmpty) {
      throw const ValidationException('Category name cannot be empty.');
    }
  }
}
