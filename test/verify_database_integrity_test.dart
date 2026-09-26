import 'package:flutter_test/flutter_test.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/constants/app_constants.dart';

void main() {
  setUpAll(() {
    DatabaseService.configureFfi();
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
  });

  test('Database integrity, foreign keys, indexes, and zero-sample-data verification', () async {
    final dbService = DatabaseService.instance;
    await dbService.init();
    final db = dbService.database;

    // 1. Verify foreign keys are enabled
    final fkResult = await db.rawQuery('PRAGMA foreign_keys;');
    expect(fkResult.first.values.first, 1, reason: 'PRAGMA foreign_keys should be ON');

    // 2. Verify database version
    final versionResult = await db.rawQuery('PRAGMA user_version;');
    expect(versionResult.first.values.first, AppConstants.databaseVersion,
        reason: 'Database user_version must match AppConstants.databaseVersion');

    // 3. Verify SQLite integrity_check passes
    final integrityResult = await db.rawQuery('PRAGMA integrity_check;');
    expect(integrityResult.first.values.first, 'ok', reason: 'Integrity check must return ok');

    // 4. Verify all 12 business tables exist
    final tables = await dbService.getExistingTableNames();
    final expectedTables = [
      DbConstants.tableCategories,
      DbConstants.tableBooks,
      DbConstants.tableCustomers,
      DbConstants.tableSuppliers,
      DbConstants.tablePurchases,
      DbConstants.tablePurchaseItems,
      DbConstants.tableSales,
      DbConstants.tableSaleItems,
      DbConstants.tableCustomerPayments,
      DbConstants.tableSupplierPayments,
      DbConstants.tableStockMovements,
      DbConstants.tableExpenses,
    ];

    for (final table in expectedTables) {
      expect(tables.contains(table), isTrue, reason: 'Table $table must exist in database');
    }

    // 5. Verify indexes exist
    final indexesResult = await db.rawQuery("SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';");
    final indexNames = indexesResult.map((row) => row['name'] as String).toSet();

    final expectedIndexes = [
      'idx_books_isbn',
      'idx_books_category_id',
      'idx_books_name',
      'idx_customers_name',
      'idx_customers_phone',
      'idx_suppliers_name',
      'idx_suppliers_phone',
      'idx_purchases_supplier_id',
      'idx_purchases_invoice_number',
      'idx_purchases_date',
      'idx_purchase_items_purchase',
      'idx_purchase_items_book',
      'idx_sales_customer_id',
      'idx_sales_invoice_number',
      'idx_sales_date',
      'idx_sale_items_sale',
      'idx_sale_items_book',
      'idx_cust_pay_customer',
      'idx_cust_pay_date',
      'idx_supp_pay_supplier',
      'idx_supp_pay_date',
      'idx_stock_movements_book',
      'idx_stock_movements_date',
      'idx_stock_movements_ref',
      'idx_expenses_date',
      'idx_expenses_category',
    ];

    for (final expectedIndex in expectedIndexes) {
      expect(indexNames.contains(expectedIndex), isTrue,
          reason: 'Index $expectedIndex must exist in sqlite_master');
    }

    // 6. Verify zero sample/fake data is present (all tables must be empty)
    for (final table in expectedTables) {
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $table;');
      final count = countResult.first['count'] as int;
      expect(count, 0, reason: 'Table $table must NOT contain sample data. Found $count rows.');
    }
  });
}
