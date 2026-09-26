import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:deen_book_depo/core/constants/app_constants.dart';
import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/shared/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String testDbPath;
  late Directory tempDir;

  setUpAll(() {
    DatabaseService.configureFfi();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step2_db_test_');
    testDbPath = p.join(tempDir.path, AppConstants.databaseName);
  });

  tearDown(() async {
    await DatabaseService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Step 2: SQLite Schema & Table Verifications', () {
    test('Database opens with version 2 and creates all 12 business tables', () async {
      final db = await DatabaseService.instance.init(overridePath: testDbPath);
      expect(db.isOpen, isTrue);

      final versionResult = await db.rawQuery('PRAGMA user_version;');
      expect(versionResult.first['user_version'], equals(2));

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
        DbConstants.tableCustomerPayments,
        DbConstants.tableSupplierPayments,
        DbConstants.tableStockMovements,
        DbConstants.tableExpenses,
        DbConstants.tableAppSettings,
      ];

      for (final table in expectedTables) {
        expect(tables, contains(table), reason: 'Table $table must exist');
      }
    });

    test('Foreign key enforcement is enabled', () async {
      final db = await DatabaseService.instance.init(overridePath: testDbPath);
      final fk = await db.rawQuery('PRAGMA foreign_keys;');
      expect(fk.first['foreign_keys'], equals(1));
    });

    test('All performance indexes are created on SQLite tables', () async {
      final db = await DatabaseService.instance.init(overridePath: testDbPath);
      final indexResults = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name NOT LIKE 'sqlite_%';",
      );
      final indexNames = indexResults.map((e) => e['name'] as String).toSet();

      final requiredIndexes = [
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

      for (final idx in requiredIndexes) {
        expect(indexNames, contains(idx), reason: 'Index $idx should be present');
      }
    });

    test('Foreign key constraints restrict invalid child records and cascade correctly', () async {
      await DatabaseService.instance.init(overridePath: testDbPath);
      final helper = DatabaseHelper();
      final now = DateTime.now().toIso8601String();

      // 1. Verify foreign key violation on purchase with non-existent supplier
      expect(
        () async => await helper.insert(
          DbConstants.tablePurchases,
          {
            DbConstants.colPurchaseSupplierId: 9999, // Does not exist
            DbConstants.colPurchaseInvoiceNumber: 'INV-INVALID-01',
            DbConstants.colPurchaseDate: now,
            DbConstants.colPurchaseTotal: 500.0,
            DbConstants.colPurchasePaymentStatus: 'UNPAID',
            DbConstants.colCreatedAt: now,
          },
        ),
        throwsA(isA<Exception>()),
        reason: 'Inserting purchase for non-existent supplier must fail FK check',
      );

      // 2. Insert valid supplier & valid purchase
      final supplierId = await helper.insert(
        DbConstants.tableSuppliers,
        {
          DbConstants.colSupplierName: 'Oxford University Press',
          DbConstants.colSupplierPhone: '+92-300-1112233',
          DbConstants.colCreatedAt: now,
        },
      );
      expect(supplierId, greaterThan(0));

      final purchaseId = await helper.insert(
        DbConstants.tablePurchases,
        {
          DbConstants.colPurchaseSupplierId: supplierId,
          DbConstants.colPurchaseInvoiceNumber: 'INV-OUP-001',
          DbConstants.colPurchaseDate: now,
          DbConstants.colPurchaseTotal: 2500.0,
          DbConstants.colPurchasePaidAmount: 2500.0,
          DbConstants.colPurchaseRemainingAmount: 0.0,
          DbConstants.colPurchasePaymentStatus: 'PAID',
          DbConstants.colCreatedAt: now,
        },
      );
      expect(purchaseId, greaterThan(0));

      // 3. Insert valid category and book
      final categoryId = await helper.insert(
        DbConstants.tableCategories,
        {
          DbConstants.colCategoryName: 'Islamic Studies',
          DbConstants.colCreatedAt: now,
        },
      );
      final bookId = await helper.insert(
        DbConstants.tableBooks,
        {
          DbConstants.colBookCategoryId: categoryId,
          DbConstants.colBookName: 'Ar-Raheeq Al-Makhtum',
          DbConstants.colBookIsbn: '978-6035000000',
          DbConstants.colBookPurchasePrice: 350.0,
          DbConstants.colBookWholesalePrice: 500.0,
          DbConstants.colBookRetailPrice: 650.0,
          DbConstants.colBookStockQuantity: 100,
          DbConstants.colCreatedAt: now,
        },
      );

      // 4. Insert purchase item
      final purchaseItemId = await helper.insert(
        DbConstants.tablePurchaseItems,
        {
          DbConstants.colPurchaseItemPurchaseId: purchaseId,
          DbConstants.colPurchaseItemBookId: bookId,
          DbConstants.colPurchaseItemQuantity: 50,
          DbConstants.colPurchaseItemUnitPrice: 350.0,
          DbConstants.colPurchaseItemDiscount: 0.0,
          DbConstants.colPurchaseItemTotal: 17500.0,
        },
      );
      expect(purchaseItemId, greaterThan(0));

      // 5. Test CASCADE delete: deleting purchase should delete its purchase_items
      await helper.delete(
        DbConstants.tablePurchases,
        where: '${DbConstants.colId} = ?',
        whereArgs: [purchaseId],
      );
      final remainingItems = await helper.query(
        DbConstants.tablePurchaseItems,
        where: '${DbConstants.colId} = ?',
        whereArgs: [purchaseItemId],
      );
      expect(remainingItems.isEmpty, isTrue, reason: 'PurchaseItems must cascade delete');
    });

    test('Atomic transaction: Multi-step purchase creation succeeds atomically', () async {
      final db = await DatabaseService.instance.init(overridePath: testDbPath);
      final now = DateTime.now().toIso8601String();

      // Setup master records
      final supplier = Supplier(
        name: 'Darussalam Publications',
        phone: '042-37240024',
        createdAt: now,
      );
      final supplierId = await db.insert(DbConstants.tableSuppliers, supplier.toMap());

      final book = Book(
        name: 'Tafsir Ibn Kathir (10 Vol)',
        isbn: '978-9960892719',
        purchasePrice: 4000.0,
        wholesalePrice: 5500.0,
        retailPrice: 7000.0,
        stockQuantity: 10,
        createdAt: now,
      );
      final bookId = await db.insert(DbConstants.tableBooks, book.toMap());

      // Execute atomic transaction:
      // BEGIN TRANSACTION -> create purchase -> create item -> increase stock -> record movement -> COMMIT
      await db.transaction((txn) async {
        final pId = await txn.insert(
          DbConstants.tablePurchases,
          {
            'supplier_id': supplierId,
            'invoice_number': 'PUR-TXN-101',
            'purchase_date': now,
            'subtotal': 80000.0,
            'discount': 0.0,
            'total': 80000.0,
            'paid_amount': 50000.0,
            'remaining_amount': 30000.0,
            'payment_status': 'PARTIAL',
            'created_at': now,
          },
        );

        await txn.insert(
          DbConstants.tablePurchaseItems,
          {
            'purchase_id': pId,
            'book_id': bookId,
            'quantity': 20,
            'unit_price': 4000.0,
            'discount': 0.0,
            'total': 80000.0,
          },
        );

        // Update book stock
        await txn.rawUpdate(
          'UPDATE ${DbConstants.tableBooks} SET stock_quantity = stock_quantity + ? WHERE id = ?',
          [20, bookId],
        );

        // Create audit movement
        await txn.insert(
          DbConstants.tableStockMovements,
          {
            'book_id': bookId,
            'movement_type': 'PURCHASE',
            'quantity': 20,
            'reference_type': 'PURCHASE',
            'reference_id': pId,
            'previous_stock': 10,
            'new_stock': 30,
            'movement_date': now,
            'notes': 'Intake from PUR-TXN-101',
            'created_at': now,
          },
        );
      });

      // Verify transaction results
      final updatedBook = await db.query(
        DbConstants.tableBooks,
        where: 'id = ?',
        whereArgs: [bookId],
      );
      expect(updatedBook.first['stock_quantity'], equals(30));

      final movements = await db.query(
        DbConstants.tableStockMovements,
        where: 'book_id = ?',
        whereArgs: [bookId],
      );
      expect(movements.length, equals(1));
      expect(movements.first['movement_type'], equals('PURCHASE'));
      expect(movements.first['new_stock'], equals(30));
    });
  });

  group('Step 2: Dart Models Serialization & Deserialization', () {
    final now = DateTime.now().toIso8601String();

    test('Category model serialization and copyWith', () {
      final category = Category(
        id: 1,
        name: 'Urdu Literature',
        description: 'Classics and modern novels',
        createdAt: now,
      );

      final map = category.toMap();
      final fromMap = Category.fromMap(map);
      expect(fromMap, equals(category));

      final modified = category.copyWith(name: 'Islamic History');
      expect(modified.name, equals('Islamic History'));
      expect(modified.id, equals(1));
    });

    test('Book model serialization and low stock helper', () {
      final book = Book(
        id: 1,
        name: 'Qasas an-Nabiyyin',
        isbn: '978-0123456789',
        purchasePrice: 150.0,
        wholesalePrice: 220.0,
        retailPrice: 300.0,
        stockQuantity: 4,
        minimumStock: 10,
        createdAt: now,
      );

      expect(book.isLowStock, isTrue);

      final map = book.toMap();
      final fromMap = Book.fromMap(map);
      expect(fromMap.id, equals(1));
      expect(fromMap.name, equals('Qasas an-Nabiyyin'));
      expect(fromMap.wholesalePrice, equals(220.0));
      expect(fromMap.stockQuantity, equals(4));
    });

    test('Customer & Supplier model serialization', () {
      final customer = Customer(
        id: 10,
        name: 'Al-Huda Book Agency',
        phone: '0321-4567890',
        openingBalance: 15000.0,
        createdAt: now,
      );

      final custMap = customer.toMap();
      final custFromMap = Customer.fromMap(custMap);
      expect(custFromMap.id, equals(10));
      expect(custFromMap.openingBalance, equals(15000.0));

      final supplier = Supplier(
        id: 20,
        name: 'Maktaba-tul-Madinah',
        phone: '021-34921388',
        openingBalance: 45000.0,
        createdAt: now,
      );

      final suppMap = supplier.toMap();
      final suppFromMap = Supplier.fromMap(suppMap);
      expect(suppFromMap.id, equals(20));
      expect(suppFromMap.openingBalance, equals(45000.0));
    });

    test('CustomerPayment & SupplierPayment model serialization', () {
      final cp = CustomerPayment(
        id: 1,
        customerId: 10,
        amount: 5000.0,
        paymentDate: now,
        paymentMethod: 'CASH',
        reference: 'RCP-001',
        createdAt: now,
      );

      final cpMap = cp.toMap();
      final cpFromMap = CustomerPayment.fromMap(cpMap);
      expect(cpFromMap.amount, equals(5000.0));
      expect(cpFromMap.paymentMethod, equals('CASH'));

      final sp = SupplierPayment(
        id: 2,
        supplierId: 20,
        amount: 12000.0,
        paymentDate: now,
        paymentMethod: 'BANK_TRANSFER',
        reference: 'TXN-998877',
        createdAt: now,
      );

      final spMap = sp.toMap();
      final spFromMap = SupplierPayment.fromMap(spMap);
      expect(spFromMap.amount, equals(12000.0));
      expect(spFromMap.paymentMethod, equals('BANK_TRANSFER'));
    });

    test('StockMovement & Expense model serialization', () {
      final sm = StockMovement(
        id: 5,
        bookId: 1,
        movementType: 'SALE',
        quantity: -4,
        referenceType: 'SALE',
        referenceId: 101,
        previousStock: 20,
        newStock: 16,
        movementDate: now,
        notes: 'Sold on invoice 101',
        createdAt: now,
      );

      final smMap = sm.toMap();
      final smFromMap = StockMovement.fromMap(smMap);
      expect(smFromMap.quantity, equals(-4));
      expect(smFromMap.previousStock, equals(20));
      expect(smFromMap.newStock, equals(16));

      final expense = Expense(
        id: 1,
        title: 'Electricity Bill',
        category: 'Utilities',
        amount: 8500.0,
        expenseDate: now,
        paymentMethod: 'CASH',
        createdAt: now,
      );

      final expMap = expense.toMap();
      final expFromMap = Expense.fromMap(expMap);
      expect(expFromMap.title, equals('Electricity Bill'));
      expect(expFromMap.amount, equals(8500.0));
    });
  });
}
