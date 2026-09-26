import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/book.dart';
import '../../domain/repositories/book_repository.dart';

/// SQLite implementation of [BookRepository]
class SqliteBookRepository implements BookRepository {
  final DatabaseHelper _dbHelper;

  SqliteBookRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<List<Book>> getAll({int? limit, int? offset}) async {
    final results = await _dbHelper.query(
      DbConstants.tableBooks,
      orderBy: '${DbConstants.colBookName} ASC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Book.fromMap(row)).toList();
  }

  @override
  Future<Book?> getById(int id, {DatabaseExecutor? executor}) async {
    final results = await _dbHelper.query(
      DbConstants.tableBooks,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
      executor: executor,
    );
    if (results.isEmpty) return null;
    return Book.fromMap(results.first);
  }

  @override
  Future<Book?> getByIsbn(String isbn) async {
    final trimmed = isbn.trim();
    if (trimmed.isEmpty) return null;

    final results = await _dbHelper.query(
      DbConstants.tableBooks,
      where: '${DbConstants.colBookIsbn} = ?',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Book.fromMap(results.first);
  }

  @override
  Future<int> create(Book book) async {
    _validateBook(book);

    final now = DateTime.now().toIso8601String();
    final toInsert = book.toMap();
    toInsert[DbConstants.colCreatedAt] = book.createdAt.isEmpty ? now : book.createdAt;
    toInsert[DbConstants.colUpdatedAt] = null;
    toInsert.remove(DbConstants.colId);

    try {
      return await _dbHelper.insert(DbConstants.tableBooks, toInsert);
    } on UniqueConstraintException {
      throw ValidationException('A book with this ISBN already exists.');
    }
  }

  @override
  Future<bool> update(Book book) async {
    if (book.id == null) {
      throw const ValidationException('Cannot update a book without an ID.');
    }
    _validateBook(book);

    final toUpdate = book.toMap();
    toUpdate[DbConstants.colUpdatedAt] = DateTime.now().toIso8601String();
    toUpdate.remove(DbConstants.colId);
    toUpdate.remove(DbConstants.colCreatedAt);

    try {
      final rowsAffected = await _dbHelper.update(
        DbConstants.tableBooks,
        toUpdate,
        where: '${DbConstants.colId} = ?',
        whereArgs: [book.id],
      );
      return rowsAffected > 0;
    } on UniqueConstraintException {
      throw ValidationException('A book with this ISBN already exists.');
    }
  }

  @override
  Future<bool> delete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw NotFoundException('Book with ID $id not found.');
    }

    // Verify historical audit preservation: purchase_items, sale_items, stock_movements
    final purchaseItems = await _dbHelper.query(
      DbConstants.tablePurchaseItems,
      columns: [DbConstants.colId],
      where: '${DbConstants.colPurchaseItemBookId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (purchaseItems.isNotEmpty) {
      throw ValidationException(
        'Cannot delete "${existing.name}" because historical purchase transactions exist for this book.',
      );
    }

    final saleItems = await _dbHelper.query(
      DbConstants.tableSaleItems,
      columns: [DbConstants.colId],
      where: '${DbConstants.colSaleItemBookId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (saleItems.isNotEmpty) {
      throw ValidationException(
        'Cannot delete "${existing.name}" because historical sales transactions exist for this book.',
      );
    }

    final rowsAffected = await _dbHelper.delete(
      DbConstants.tableBooks,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    return rowsAffected > 0;
  }

  @override
  Future<List<Book>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    final term = '%$trimmed%';
    final results = await _dbHelper.query(
      DbConstants.tableBooks,
      where: '${DbConstants.colBookName} LIKE ? OR '
          '${DbConstants.colBookIsbn} LIKE ? OR '
          '${DbConstants.colBookAuthor} LIKE ? OR '
          '${DbConstants.colBookPublisher} LIKE ?',
      whereArgs: [term, term, term, term],
      orderBy: '${DbConstants.colBookName} ASC',
    );
    return results.map((row) => Book.fromMap(row)).toList();
  }

  @override
  Future<List<Book>> getByCategory(int categoryId) async {
    final results = await _dbHelper.query(
      DbConstants.tableBooks,
      where: '${DbConstants.colBookCategoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${DbConstants.colBookName} ASC',
    );
    return results.map((row) => Book.fromMap(row)).toList();
  }

  @override
  Future<List<Book>> getLowStockBooks() async {
    final results = await _dbHelper.query(
      DbConstants.tableBooks,
      where: '${DbConstants.colBookStockQuantity} <= ${DbConstants.colBookMinimumStock}',
      orderBy: '${DbConstants.colBookStockQuantity} ASC',
    );
    return results.map((row) => Book.fromMap(row)).toList();
  }

  @override
  Future<List<Book>> searchAndFilter({String? query, int? categoryId}) async {
    final trimmed = query?.trim() ?? '';
    final hasQuery = trimmed.isNotEmpty;
    final hasCategory = categoryId != null;

    if (!hasQuery && !hasCategory) {
      return getAll();
    }

    if (!hasQuery && hasCategory) {
      return getByCategory(categoryId);
    }

    final term = '%$trimmed%';
    final searchClause = '(${DbConstants.colBookName} LIKE ? OR '
        '${DbConstants.colBookIsbn} LIKE ? OR '
        '${DbConstants.colBookAuthor} LIKE ? OR '
        '${DbConstants.colBookPublisher} LIKE ?)';

    if (hasCategory) {
      final results = await _dbHelper.query(
        DbConstants.tableBooks,
        where: '${DbConstants.colBookCategoryId} = ? AND $searchClause',
        whereArgs: [categoryId, term, term, term, term],
        orderBy: '${DbConstants.colBookName} ASC',
      );
      return results.map((row) => Book.fromMap(row)).toList();
    } else {
      final results = await _dbHelper.query(
        DbConstants.tableBooks,
        where: searchClause,
        whereArgs: [term, term, term, term],
        orderBy: '${DbConstants.colBookName} ASC',
      );
      return results.map((row) => Book.fromMap(row)).toList();
    }
  }

  @override
  Future<bool> updateStock(int bookId, int newStock, {DatabaseExecutor? executor}) async {
    if (newStock < 0) {
      throw const ValidationException('Stock quantity cannot be negative.');
    }
    final rowsAffected = await _dbHelper.update(
      DbConstants.tableBooks,
      {
        DbConstants.colBookStockQuantity: newStock,
        DbConstants.colUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [bookId],
      executor: executor,
    );
    return rowsAffected > 0;
  }

  void _validateBook(Book book) {
    if (book.name.trim().isEmpty) {
      throw const ValidationException('Book title cannot be empty.');
    }
    if (book.purchasePrice < 0) {
      throw const ValidationException('Purchase price cannot be negative.');
    }
    if (book.wholesalePrice < 0) {
      throw const ValidationException('Wholesale price cannot be negative.');
    }
    if (book.retailPrice < 0) {
      throw const ValidationException('Retail price cannot be negative.');
    }
    if (book.stockQuantity < 0) {
      throw const ValidationException('Stock quantity cannot be negative.');
    }
    if (book.minimumStock < 0) {
      throw const ValidationException('Minimum stock threshold cannot be negative.');
    }
  }
}
