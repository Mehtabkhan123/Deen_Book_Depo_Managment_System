import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/errors/exceptions.dart';
import 'package:deen_book_depo/features/repositories.dart';
import 'package:deen_book_depo/features/services.dart';
import 'package:deen_book_depo/shared/models/models.dart';

void main() {
  late Directory tempDir;
  late String dbPath;
  late DatabaseService dbService;
  late DatabaseHelper dbHelper;

  // Repositories
  late CategoryRepository categoryRepo;
  late BookRepository bookRepo;
  late CustomerRepository customerRepo;
  late SupplierRepository supplierRepo;
  late StockMovementRepository movementRepo;
  late StockService stockService;
  late PurchaseRepository purchaseRepo;
  late SaleRepository saleRepo;
  late CustomerPaymentRepository customerPaymentRepo;
  late SupplierPaymentRepository supplierPaymentRepo;
  late ExpenseRepository expenseRepo;
  late CustomerLedgerService customerLedgerService;
  late SupplierLedgerService supplierLedgerService;

  setUpAll(() {
    DatabaseService.configureFfi();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step3_repo_test_');
    dbPath = p.join(tempDir.path, 'wholesale_test.db');

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: dbPath);
    dbHelper = DatabaseHelper(dbService);

    categoryRepo = SqliteCategoryRepository(dbHelper);
    bookRepo = SqliteBookRepository(dbHelper);
    customerRepo = SqliteCustomerRepository(dbHelper);
    supplierRepo = SqliteSupplierRepository(dbHelper);
    movementRepo = SqliteStockMovementRepository(dbHelper);
    stockService = InventoryStockService(
      bookRepository: bookRepo,
      movementRepository: movementRepo,
      dbHelper: dbHelper,
    );
    purchaseRepo = SqlitePurchaseRepository(
      stockService: stockService,
      dbHelper: dbHelper,
    );
    saleRepo = SqliteSaleRepository(
      bookRepository: bookRepo,
      stockService: stockService,
      dbHelper: dbHelper,
    );
    customerPaymentRepo = SqliteCustomerPaymentRepository(dbHelper);
    supplierPaymentRepo = SqliteSupplierPaymentRepository(dbHelper);
    expenseRepo = SqliteExpenseRepository(dbHelper);
    customerLedgerService = CustomerLedgerServiceImpl(
      customerRepository: customerRepo,
      dbHelper: dbHelper,
    );
    supplierLedgerService = SupplierLedgerServiceImpl(
      supplierRepository: supplierRepo,
      dbHelper: dbHelper,
    );
  });

  tearDown(() async {
    await dbService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Category CRUD Operations', () {
    test('1-4: Create, Read, Update, Delete Category & Search', () async {
      // 1. Create
      final category = Category(name: 'Islamic History', description: 'Historical works');
      final catId = await categoryRepo.create(category);
      expect(catId, greaterThan(0));

      // 2. Read
      final fetched = await categoryRepo.getById(catId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Islamic History');

      // Search
      final searchResults = await categoryRepo.search('History');
      expect(searchResults.length, 1);
      expect(searchResults.first.name, 'Islamic History');

      // 3. Update
      final updatedCategory = fetched.copyWith(description: 'Updated description');
      final updateSuccess = await categoryRepo.update(updatedCategory);
      expect(updateSuccess, isTrue);

      final verifyUpdate = await categoryRepo.getById(catId);
      expect(verifyUpdate!.description, 'Updated description');

      // 4. Delete
      final deleteSuccess = await categoryRepo.delete(catId);
      expect(deleteSuccess, isTrue);

      final verifyDelete = await categoryRepo.getById(catId);
      expect(verifyDelete, isNull);
    });

    test('Category validation rejects empty name and duplicate names', () async {
      expect(
        () => categoryRepo.create(const Category(name: '   ')),
        throwsA(isA<ValidationException>()),
      );

      await categoryRepo.create(const Category(name: 'Fiqh'));
      expect(
        () => categoryRepo.create(const Category(name: 'Fiqh')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Book CRUD & Inventory Queries', () {
    test('5-9: Create, Read, Update, Search, and Low-stock Book queries', () async {
      final catId = await categoryRepo.create(const Category(name: 'Tafseer'));

      // 5. Create
      final book = Book(
        categoryId: catId,
        name: 'Tafseer Ibn Kathir Complete',
        isbn: '978-0123456789',
        author: 'Ibn Kathir',
        publisher: 'Darussalam',
        purchasePrice: 2000.0,
        wholesalePrice: 2500.0,
        retailPrice: 3000.0,
        stockQuantity: 5,
        minimumStock: 10,
      );
      final bookId = await bookRepo.create(book);
      expect(bookId, greaterThan(0));

      // 6. Read
      final fetched = await bookRepo.getById(bookId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Tafseer Ibn Kathir Complete');
      expect(fetched.stockQuantity, 5);

      // 7. Update
      final updated = fetched.copyWith(wholesalePrice: 2600.0);
      final updateSuccess = await bookRepo.update(updated);
      expect(updateSuccess, isTrue);

      final verifyUpdate = await bookRepo.getById(bookId);
      expect(verifyUpdate!.wholesalePrice, 2600.0);

      // 8. Search (by name, author, publisher, ISBN)
      expect((await bookRepo.search('Kathir')).length, 1);
      expect((await bookRepo.search('978-0123456789')).length, 1);
      expect((await bookRepo.search('Darussalam')).length, 1);
      expect((await bookRepo.search('NonExistent')).length, 0);

      // 9. Low-stock query: stock is 5, minimumStock is 10 -> should be included
      final lowStock = await bookRepo.getLowStockBooks();
      expect(lowStock.length, 1);
      expect(lowStock.first.id, bookId);

      // If stock increases above threshold, low-stock query excludes it
      await bookRepo.updateStock(bookId, 15);
      final updatedLowStock = await bookRepo.getLowStockBooks();
      expect(updatedLowStock.length, 0);
    });

    test('Book validation rejects invalid pricing or empty title', () async {
      expect(
        () => bookRepo.create(const Book(name: '', purchasePrice: 100)),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => bookRepo.create(const Book(name: 'Book', purchasePrice: -50)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Customer & Supplier Management', () {
    test('10-11: Create customer & supplier', () async {
      // 10. Customer
      final customer = const Customer(
        name: 'Al-Madina Booksellers',
        phone: '+923001234567',
        address: 'Urdu Bazar, Lahore',
        openingBalance: 15000.0,
      );
      final customerId = await customerRepo.create(customer);
      expect(customerId, greaterThan(0));

      final fetchedCustomer = await customerRepo.getById(customerId);
      expect(fetchedCustomer!.name, 'Al-Madina Booksellers');
      expect(fetchedCustomer.openingBalance, 15000.0);

      // 11. Supplier
      final supplier = const Supplier(
        name: 'Maktaba Shamila Publishers',
        phone: '+923119876543',
        address: 'Karachi, Pakistan',
        openingBalance: 50000.0,
      );
      final supplierId = await supplierRepo.create(supplier);
      expect(supplierId, greaterThan(0));

      final fetchedSupplier = await supplierRepo.getById(supplierId);
      expect(fetchedSupplier!.name, 'Maktaba Shamila Publishers');
      expect(fetchedSupplier.openingBalance, 50000.0);
    });
  });

  group('Transactional Operations (Purchases & Sales)', () {
    test('12: Purchase transaction creates invoice, items, increases stock, and creates stock movements', () async {
      final supplierId = await supplierRepo.create(const Supplier(name: 'Global Publisher'));
      final bookId = await bookRepo.create(const Book(
        name: 'Sahih Al-Bukhari 7 Vol',
        purchasePrice: 4000.0,
        wholesalePrice: 5000.0,
        stockQuantity: 10,
      ));

      final purchase = Purchase(
        supplierId: supplierId,
        invoiceNumber: 'INV-PUR-2026-001',
        purchaseDate: DateTime.now().toIso8601String(),
        subtotal: 40000.0,
        discount: 1000.0,
        total: 39000.0,
        paidAmount: 20000.0,
        remainingAmount: 19000.0,
        paymentStatus: 'PARTIAL',
      );

      final items = [
        const PurchaseItem(
          purchaseId: 0,
          bookId: 0, // Will be overridden or set
          quantity: 10,
          unitPrice: 4000.0,
          discount: 100.0,
          total: 39000.0,
        ).copyWith(bookId: bookId),
      ];

      final purchaseId = await purchaseRepo.createPurchaseWithItems(
        purchase: purchase,
        items: items,
      );
      expect(purchaseId, greaterThan(0));

      // Verify purchase & items
      final savedPurchase = await purchaseRepo.getById(purchaseId);
      expect(savedPurchase, isNotNull);
      expect(savedPurchase!.total, 39000.0);

      final savedItems = await purchaseRepo.getItemsForPurchase(purchaseId);
      expect(savedItems.length, 1);
      expect(savedItems.first.quantity, 10);

      // Verify stock increased from 10 to 20
      final updatedBook = await bookRepo.getById(bookId);
      expect(updatedBook!.stockQuantity, 20);

      // Verify stock movement created
      final movements = await movementRepo.getByBookId(bookId);
      expect(movements.length, 1);
      expect(movements.first.movementType, StockMovementTypes.purchase);
      expect(movements.first.quantity, 10);
      expect(movements.first.previousStock, 10);
      expect(movements.first.newStock, 20);
    });

    test('13: Sale transaction creates invoice, items, decreases stock, and creates stock movements', () async {
      final customerId = await customerRepo.create(const Customer(name: 'Iqra Academy'));
      final bookId = await bookRepo.create(const Book(
        name: 'Riyad Us Saliheen',
        wholesalePrice: 1200.0,
        stockQuantity: 30,
      ));

      final sale = Sale(
        customerId: customerId,
        invoiceNumber: 'INV-SALE-2026-001',
        saleDate: DateTime.now().toIso8601String(),
        subtotal: 12000.0,
        discount: 500.0,
        total: 11500.0,
        paidAmount: 5000.0,
        remainingAmount: 6500.0,
        paymentStatus: 'PARTIAL',
      );

      final items = [
        const SaleItem(
          saleId: 0,
          bookId: 0,
          quantity: 10,
          unitPrice: 1200.0,
          discount: 50.0,
          total: 11500.0,
        ).copyWith(bookId: bookId),
      ];

      final saleId = await saleRepo.createSaleWithItems(
        sale: sale,
        items: items,
      );
      expect(saleId, greaterThan(0));

      // Verify sale & items
      final savedSale = await saleRepo.getById(saleId);
      expect(savedSale, isNotNull);
      expect(savedSale!.remainingAmount, 6500.0);

      final savedItems = await saleRepo.getItemsForSale(saleId);
      expect(savedItems.length, 1);
      expect(savedItems.first.quantity, 10);

      // Verify stock decreased from 30 to 20
      final updatedBook = await bookRepo.getById(bookId);
      expect(updatedBook!.stockQuantity, 20);

      // Verify stock movement created
      final movements = await movementRepo.getByBookId(bookId);
      expect(movements.length, 1);
      expect(movements.first.movementType, StockMovementTypes.sale);
      expect(movements.first.quantity, 10);
      expect(movements.first.previousStock, 30);
      expect(movements.first.newStock, 20);
    });

    test('14: Sale with insufficient stock rolls back completely without partial creation', () async {
      final customerId = await customerRepo.create(const Customer(name: 'Walk-in Buyer'));
      final bookId = await bookRepo.create(const Book(
        name: 'Rare Classical Manuscript',
        wholesalePrice: 10000.0,
        stockQuantity: 3, // Only 3 copies available
      ));

      final sale = Sale(
        customerId: customerId,
        invoiceNumber: 'INV-SALE-OVERDRAFT',
        saleDate: DateTime.now().toIso8601String(),
        total: 50000.0,
        paymentStatus: 'UNPAID',
      );

      final items = [
        const SaleItem(
          saleId: 0,
          bookId: 0,
          quantity: 5, // Requesting 5, but stock is 3!
          unitPrice: 10000.0,
          total: 50000.0,
        ).copyWith(bookId: bookId),
      ];

      // Must throw InsufficientStockException
      expect(
        () => saleRepo.createSaleWithItems(sale: sale, items: items),
        throwsA(isA<InsufficientStockException>()),
      );

      // Verify rollback: invoice was NOT created
      final verifySale = await saleRepo.getByInvoiceNumber('INV-SALE-OVERDRAFT');
      expect(verifySale, isNull);

      // Verify rollback: stock remains untouched at 3
      final verifyBook = await bookRepo.getById(bookId);
      expect(verifyBook!.stockQuantity, 3);

      // Verify rollback: no stock movements recorded
      final movements = await movementRepo.getByBookId(bookId);
      expect(movements, isEmpty);
    });
  });

  group('Payment Operations & Ledger Calculations', () {
    test('15: Customer payment recording and ledger balance update', () async {
      final customerId = await customerRepo.create(const Customer(
        name: 'Al-Huda Book Center',
        openingBalance: 10000.0,
      ));

      // Customer makes a payment of 4000
      final payment = CustomerPayment(
        customerId: customerId,
        amount: 4000.0,
        paymentDate: DateTime.now().toIso8601String(),
        paymentMethod: 'CASH',
        reference: 'RCP-001',
      );
      final paymentId = await customerPaymentRepo.create(payment);
      expect(paymentId, greaterThan(0));

      // Ledger calculation: Opening Balance (10000) - Payment (4000) = 6000
      final balance = await customerLedgerService.getCustomerBalance(customerId);
      expect(balance, 6000.0);

      // Verify statement transactions
      final statement = await customerLedgerService.getCustomerTransactions(customerId);
      expect(statement.length, 2); // Opening Balance + Payment
      expect(statement.last.runningBalance, 6000.0);
    });

    test('16: Supplier payment recording and ledger balance update', () async {
      final supplierId = await supplierRepo.create(const Supplier(
        name: 'Darul Uloom Press',
        openingBalance: 25000.0,
      ));

      // Disburse payment of 10000
      final payment = SupplierPayment(
        supplierId: supplierId,
        amount: 10000.0,
        paymentDate: DateTime.now().toIso8601String(),
        paymentMethod: 'BANK_TRANSFER',
        reference: 'TXN-998877',
      );
      final paymentId = await supplierPaymentRepo.create(payment);
      expect(paymentId, greaterThan(0));

      // Ledger calculation: Opening Balance (25000) - Payment (10000) = 15000
      final balance = await supplierLedgerService.getSupplierBalance(supplierId);
      expect(balance, 15000.0);

      final statement = await supplierLedgerService.getSupplierTransactions(supplierId);
      expect(statement.length, 2); // Opening Balance + Payment
      expect(statement.last.runningBalance, 15000.0);
    });
  });

  group('Expense CRUD & Aggregations', () {
    test('17: Expense CRUD and date-range total calculation', () async {
      final expense = const Expense(
        title: 'Store Electricity Bill',
        category: 'Utilities',
        amount: 8500.0,
        expenseDate: '2026-09-01T10:00:00',
        paymentMethod: 'CASH',
      );
      final expenseId = await expenseRepo.create(expense);
      expect(expenseId, greaterThan(0));

      final fetched = await expenseRepo.getById(expenseId);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Store Electricity Bill');

      // Update
      final updated = fetched.copyWith(amount: 9000.0);
      await expenseRepo.update(updated);
      final verifyUpdate = await expenseRepo.getById(expenseId);
      expect(verifyUpdate!.amount, 9000.0);

      // Add second expense
      await expenseRepo.create(const Expense(
        title: 'Packing Cartons',
        category: 'Supplies',
        amount: 3000.0,
        expenseDate: '2026-09-15T12:00:00',
        paymentMethod: 'CASH',
      ));

      // Total sum query
      final total = await expenseRepo.getTotalExpenses();
      expect(total, 12000.0);

      // Date range query
      final filteredTotal = await expenseRepo.getTotalExpenses(
        startDate: '2026-09-01T00:00:00',
        endDate: '2026-09-10T23:59:59',
      );
      expect(filteredTotal, 9000.0);

      // Delete
      final deleteSuccess = await expenseRepo.delete(expenseId);
      expect(deleteSuccess, isTrue);
      expect(await expenseRepo.getById(expenseId), isNull);
    });
  });
}
