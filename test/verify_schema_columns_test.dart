import 'package:flutter_test/flutter_test.dart';
import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/database/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify all 12 tables have exact required columns in SQLite', () async {
    DatabaseService.configureFfi();
    final db = await DatabaseService.instance.init();

    Future<List<String>> getColumns(String table) async {
      final info = await db.rawQuery('PRAGMA table_info($table);');
      return info.map((col) => col['name'] as String).toList();
    }

    // 1. categories
    expect(await getColumns(DbConstants.tableCategories), [
      'id', 'name', 'description', 'created_at', 'updated_at'
    ]);

    // 2. books
    expect(await getColumns(DbConstants.tableBooks), [
      'id', 'category_id', 'name', 'isbn', 'author', 'publisher',
      'purchase_price', 'wholesale_price', 'retail_price',
      'stock_quantity', 'minimum_stock', 'created_at', 'updated_at'
    ]);

    // 3. customers
    expect(await getColumns(DbConstants.tableCustomers), [
      'id', 'name', 'phone', 'address', 'email', 'opening_balance', 'notes',
      'created_at', 'updated_at'
    ]);

    // 4. suppliers
    expect(await getColumns(DbConstants.tableSuppliers), [
      'id', 'name', 'phone', 'address', 'email', 'opening_balance', 'notes',
      'created_at', 'updated_at'
    ]);

    // 5. purchases
    expect(await getColumns(DbConstants.tablePurchases), [
      'id', 'supplier_id', 'invoice_number', 'purchase_date',
      'subtotal', 'discount', 'total', 'paid_amount', 'remaining_amount',
      'payment_status', 'notes', 'created_at', 'updated_at'
    ]);

    // 6. purchase_items
    expect(await getColumns(DbConstants.tablePurchaseItems), [
      'id', 'purchase_id', 'book_id', 'quantity', 'unit_price', 'discount', 'total'
    ]);

    // 7. sales
    expect(await getColumns(DbConstants.tableSales), [
      'id', 'customer_id', 'invoice_number', 'sale_date',
      'subtotal', 'discount', 'total', 'paid_amount', 'remaining_amount',
      'payment_status', 'notes', 'created_at', 'updated_at'
    ]);

    // 8. sale_items
    expect(await getColumns(DbConstants.tableSaleItems), [
      'id', 'sale_id', 'book_id', 'quantity', 'unit_price', 'discount', 'total'
    ]);

    // 9. customer_payments
    expect(await getColumns(DbConstants.tableCustomerPayments), [
      'id', 'customer_id', 'amount', 'payment_date', 'payment_method',
      'reference', 'notes', 'created_at'
    ]);

    // 10. supplier_payments
    expect(await getColumns(DbConstants.tableSupplierPayments), [
      'id', 'supplier_id', 'amount', 'payment_date', 'payment_method',
      'reference', 'notes', 'created_at'
    ]);

    // 11. stock_movements
    expect(await getColumns(DbConstants.tableStockMovements), [
      'id', 'book_id', 'movement_type', 'quantity', 'reference_type',
      'reference_id', 'previous_stock', 'new_stock', 'movement_date',
      'notes', 'created_at'
    ]);

    // 12. expenses
    expect(await getColumns(DbConstants.tableExpenses), [
      'id', 'title', 'category', 'amount', 'expense_date', 'payment_method',
      'notes', 'created_at', 'updated_at'
    ]);

    await DatabaseService.instance.close();
  });
}
