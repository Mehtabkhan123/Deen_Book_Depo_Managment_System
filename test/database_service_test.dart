import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:deen_book_depo/core/constants/app_constants.dart';
import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String testDbPath;
  late Directory tempDir;

  setUpAll(() {
    // Configure SQLite FFI for the test runner environment
    DatabaseService.configureFfi();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wholesale_db_test_');
    testDbPath = p.join(tempDir.path, AppConstants.databaseName);
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DatabaseService initializes and creates local database file', () async {
    final db = await DatabaseService.instance.init(overridePath: testDbPath);

    expect(db.isOpen, isTrue);
    expect(DatabaseService.instance.isOpen, isTrue);
    expect(DatabaseService.instance.databasePath, equals(testDbPath));

    final file = File(testDbPath);
    expect(await file.exists(), isTrue, reason: 'Database file must exist on disk');
  });

  test('Database contains all initial schema tables', () async {
    await DatabaseService.instance.init(overridePath: testDbPath);
    final tables = await DatabaseService.instance.getExistingTableNames();

    final expectedTables = [
      DbConstants.tableCategories,
      DbConstants.tableBooks,
      DbConstants.tableCustomers,
      DbConstants.tableSuppliers,
      DbConstants.tablePurchases,
      DbConstants.tablePurchaseItems,
      DbConstants.tableSales,
      DbConstants.tableSaleItems,
      DbConstants.tableStockMovements,
      DbConstants.tableCustomerPayments,
      DbConstants.tableSupplierPayments,
      DbConstants.tableExpenses,
      DbConstants.tableAppSettings,
    ];

    for (final expected in expectedTables) {
      expect(tables, contains(expected), reason: 'Table $expected should be created');
    }
  });

  test('Foreign key enforcement is active in SQLite', () async {
    final db = await DatabaseService.instance.init(overridePath: testDbPath);

    final fkResult = await db.rawQuery('PRAGMA foreign_keys;');
    expect(fkResult.first['foreign_keys'], equals(1), reason: 'Foreign keys must be ON');
  });

  test('DatabaseHelper can insert and query records cleanly', () async {
    await DatabaseService.instance.init(overridePath: testDbPath);
    final helper = DatabaseHelper();

    final now = DateTime.now().toIso8601String();

    // Insert category
    final categoryId = await helper.insert(
      DbConstants.tableCategories,
      {
        DbConstants.colCategoryName: 'Test Category',
        DbConstants.colCategoryDescription: 'Testing description',
        DbConstants.colCreatedAt: now,
        DbConstants.colUpdatedAt: now,
      },
    );
    expect(categoryId, greaterThan(0));

    // Insert book referencing category
    final bookId = await helper.insert(
      DbConstants.tableBooks,
      {
        DbConstants.colBookIsbn: '978-0000000001',
        DbConstants.colBookName: 'Wholesale Test Book',
        DbConstants.colBookAuthor: 'Author Test',
        DbConstants.colBookPublisher: 'Publisher Test',
        DbConstants.colBookCategoryId: categoryId,
        DbConstants.colBookPurchasePrice: 100.0,
        DbConstants.colBookRetailPrice: 150.0,
        DbConstants.colBookWholesalePrice: 120.0,
        DbConstants.colBookStockQuantity: 50,
        DbConstants.colBookMinimumStock: 5,
        DbConstants.colCreatedAt: now,
        DbConstants.colUpdatedAt: now,
      },
    );
    expect(bookId, greaterThan(0));

    // Query book
    final books = await helper.query(
      DbConstants.tableBooks,
      where: '${DbConstants.colId} = ?',
      whereArgs: [bookId],
    );
    expect(books.length, equals(1));
    expect(books.first[DbConstants.colBookName], equals('Wholesale Test Book'));
    expect(books.first[DbConstants.colBookStockQuantity], equals(50));

    // Clean up
    await helper.delete(
      DbConstants.tableBooks,
      where: '${DbConstants.colId} = ?',
      whereArgs: [bookId],
    );
    await helper.delete(
      DbConstants.tableCategories,
      where: '${DbConstants.colId} = ?',
      whereArgs: [categoryId],
    );
  });
}
