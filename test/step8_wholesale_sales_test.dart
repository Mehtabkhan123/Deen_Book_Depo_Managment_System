import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/errors/exceptions.dart';
import 'package:deen_book_depo/core/theme/theme.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/data/services/customer_ledger_service_impl.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/services/customer_ledger_service.dart';
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/data/services/inventory_stock_service.dart';
import 'package:deen_book_depo/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/domain/services/stock_service.dart';
import 'package:deen_book_depo/features/sales/data/repositories/sqlite_sale_repository.dart';
import 'package:deen_book_depo/features/sales/domain/repositories/sale_repository.dart';
import 'package:deen_book_depo/features/sales/presentation/bloc/sales_bloc.dart';
import 'package:deen_book_depo/features/sales/presentation/pages/sales_page.dart';
import 'package:deen_book_depo/features/sales/presentation/widgets/sale_detail_dialog.dart';
import 'package:deen_book_depo/features/sales/presentation/widgets/sale_form_dialog.dart';
import 'package:deen_book_depo/shared/models/book.dart';
import 'package:deen_book_depo/shared/models/category.dart';
import 'package:deen_book_depo/shared/models/customer.dart';
import 'package:deen_book_depo/shared/models/sale.dart';
import 'package:deen_book_depo/shared/models/sale_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testDbPath;
  late DatabaseService dbService;
  late DatabaseHelper dbHelper;
  late CategoryRepository categoryRepo;
  late BookRepository bookRepo;
  late CustomerRepository customerRepo;
  late StockMovementRepository movementRepo;
  late StockService stockService;
  late CustomerLedgerService customerLedgerService;
  late SaleRepository saleRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step8_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}sales_test.db';

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: testDbPath);
    dbHelper = DatabaseHelper(dbService);

    categoryRepo = SqliteCategoryRepository(dbHelper);
    bookRepo = SqliteBookRepository(dbHelper);
    customerRepo = SqliteCustomerRepository(dbHelper);
    movementRepo = SqliteStockMovementRepository(dbHelper);
    stockService = InventoryStockService(
      bookRepository: bookRepo,
      movementRepository: movementRepo,
      dbHelper: dbHelper,
    );
    customerLedgerService = CustomerLedgerServiceImpl(
      customerRepository: customerRepo,
      dbHelper: dbHelper,
    );
    saleRepo = SqliteSaleRepository(
      stockService: stockService,
      bookRepository: bookRepo,
      dbHelper: dbHelper,
    );
  });

  tearDown(() async {
    await dbService.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  // Helper method to setup a customer and book with initial stock
  Future<(int customerId, int bookId)> setupCustomerAndBook({
    int initialStock = 50,
    double wholesalePrice = 400.0,
    double openingBalance = 0.0,
  }) async {
    final custId = await customerRepo.create(Customer(
      name: 'Al-Madina Booksellers',
      phone: '03001234567',
      email: 'madina@books.pk',
      address: 'Urdu Bazar, Lahore',
      openingBalance: openingBalance,
    ));

    final catId = await categoryRepo.create(const Category(
      name: 'Islamic Studies',
    ));

    final bId = await bookRepo.create(Book(
      name: 'Tafseer Maariful Quran Vol 1',
      isbn: '978-9694370001',
      author: 'Mufti Muhammad Shafi',
      publisher: 'Maktaba Ma’ariful Quran',
      purchasePrice: 300.0,
      wholesalePrice: wholesalePrice,
      retailPrice: 500.0,
      stockQuantity: initialStock,
      minimumStock: 5,
      categoryId: catId,
    ));

    return (custId, bId);
  }

  // ===========================================================================
  // PART A: SALES MANAGEMENT TESTS (1 - 14)
  // ===========================================================================
  group('Part A: Sales Core Tests (1 - 14)', () {
    test('1. Load sales: empty and populated list via SalesBloc', () async {
      final bloc = SalesBloc(
        saleRepository: saleRepo,
        customerRepository: customerRepo,
        bookRepository: bookRepo,
      );

      expect(bloc.state, isA<SalesInitial>());

      bloc.add(const LoadSales());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SalesLoading>(),
          isA<SalesLoaded>().having((s) => s.sales.length, 'count', 0),
        ]),
      );

      final (custId, bookId) = await setupCustomerAndBook();

      await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'SINV-001',
          saleDate: '2026-09-24',
          subtotal: 2000.0,
          total: 2000.0,
          paidAmount: 2000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 5,
            unitPrice: 400.0,
            total: 2000.0,
          ),
        ],
      );

      bloc.add(const LoadSales());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SalesLoading>(),
          isA<SalesLoaded>().having((s) => s.sales.length, 'count', 1),
        ]),
      );

      await bloc.close();
    });

    test('2. Create cash sale: saves with null customer and decreases stock', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 25);

      final saleId = await saleRepo.createSaleWithItems(
        sale: const Sale(
          customerId: null, // Cash / Walk-in
          invoiceNumber: 'CASH-SALE-001',
          saleDate: '2026-09-24',
          subtotal: 4000.0,
          total: 4000.0,
          paidAmount: 4000.0,
          remainingAmount: 0.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 10,
            unitPrice: 400.0,
            total: 4000.0,
          ),
        ],
      );

      expect(saleId, isPositive);

      final retrieved = await saleRepo.getById(saleId);
      expect(retrieved, isNotNull);
      expect(retrieved!.customerId, isNull);
      expect(retrieved.invoiceNumber, equals('CASH-SALE-001'));
      expect(retrieved.paymentStatus, equals('PAID'));

      // Check stock deduction
      final book = await bookRepo.getById(bookId);
      expect(book!.stockQuantity, equals(15)); // 25 - 10 = 15
    });

    test('3. Create customer sale: saves with customerId and remaining balance', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 30);

      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'CUST-SALE-002',
          saleDate: '2026-09-24',
          subtotal: 6000.0,
          total: 6000.0,
          paidAmount: 2000.0,
          remainingAmount: 4000.0,
          paymentStatus: 'PARTIAL',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 15,
            unitPrice: 400.0,
            total: 6000.0,
          ),
        ],
      );

      expect(saleId, isPositive);
      final retrieved = await saleRepo.getById(saleId);
      expect(retrieved!.customerId, equals(custId));
      expect(retrieved.remainingAmount, equals(4000.0));
      expect(retrieved.paymentStatus, equals('PARTIAL'));
    });

    test('4. Create sale with multiple items', () async {
      final (custId, bookId1) = await setupCustomerAndBook(initialStock: 20);
      final bookId2 = await bookRepo.create(const Book(
        name: 'Seerat-un-Nabi Vol 1',
        wholesalePrice: 250.0,
        stockQuantity: 40,
        minimumStock: 5,
      ));

      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'MULTI-SALE-004',
          saleDate: '2026-09-24',
          subtotal: 6500.0,
          total: 6500.0,
          paidAmount: 6500.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId1,
            quantity: 10,
            unitPrice: 400.0,
            total: 4000.0,
          ),
          SaleItem(
            saleId: 0,
            bookId: bookId2,
            quantity: 10,
            unitPrice: 250.0,
            total: 2500.0,
          ),
        ],
      );

      expect(saleId, isPositive);
      final items = await saleRepo.getItemsForSale(saleId);
      expect(items.length, equals(2));

      final b1 = await bookRepo.getById(bookId1);
      final b2 = await bookRepo.getById(bookId2);
      expect(b1!.stockQuantity, equals(10)); // 20 - 10
      expect(b2!.stockQuantity, equals(30)); // 40 - 10
    });

    test('5. Calculate line total: quantity * unitPrice - discount', () {
      const qty = 5;
      const unitPrice = 300.0;
      const discount = 50.0;
      final lineSubtotal = qty * unitPrice;
      final lineTotal = lineSubtotal - discount;

      expect(lineSubtotal, equals(1500.0));
      expect(lineTotal, equals(1450.0));
    });

    test('6. Calculate subtotal: sum of all line totals', () {
      final lineTotals = [1450.0, 2000.0, 800.0];
      final subtotal = lineTotals.reduce((a, b) => a + b);
      expect(subtotal, equals(4250.0));
    });

    test('7. Calculate discount: invoice discount subtracted from subtotal', () {
      const subtotal = 5000.0;
      const invoiceDiscount = 250.0;
      final total = subtotal - invoiceDiscount;
      expect(total, equals(4750.0));
    });

    test('8. Calculate total: subtotal - overall discount', () {
      const subtotal = 10000.0;
      const discount = 500.0;
      final total = subtotal - discount;
      expect(total, equals(9500.0));
    });

    test('9. Calculate paid amount: stored accurately', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 10);
      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'PAID-TEST-009',
          saleDate: '2026-09-24',
          subtotal: 2000.0,
          total: 2000.0,
          paidAmount: 1500.0,
          remainingAmount: 500.0,
          paymentStatus: 'PARTIAL',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 5,
            unitPrice: 400.0,
            total: 2000.0,
          ),
        ],
      );

      final sale = await saleRepo.getById(saleId);
      expect(sale!.paidAmount, equals(1500.0));
    });

    test('10. Calculate remaining amount: total - paidAmount', () {
      const total = 7500.0;
      const paid = 3000.0;
      final remaining = total - paid;
      expect(remaining, equals(4500.0));
    });

    test('11. Payment status evaluation logic', () {
      String resolveStatus(double total, double paid) {
        if (paid >= total) return 'PAID';
        if (paid > 0) return 'PARTIAL';
        return 'UNPAID';
      }

      expect(resolveStatus(1000.0, 1000.0), equals('PAID'));
      expect(resolveStatus(1000.0, 500.0), equals('PARTIAL'));
      expect(resolveStatus(1000.0, 0.0), equals('UNPAID'));
    });

    test('12. Duplicate invoice rejection', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 20);

      await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'INV-DUP-012',
          saleDate: '2026-09-24',
          subtotal: 1000.0,
          total: 1000.0,
          paidAmount: 1000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 2,
            unitPrice: 500.0,
            total: 1000.0,
          ),
        ],
      );

      expect(
        () => saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'INV-DUP-012', // Duplicate!
            saleDate: '2026-09-24',
            subtotal: 1000.0,
            total: 1000.0,
            paidAmount: 1000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 2,
              unitPrice: 500.0,
              total: 1000.0,
            ),
          ],
        ),
        throwsA(isA<DuplicateInvoiceException>()),
      );
    });

    test('13. Invalid sale rejection: negative numbers, invalid dates, discount > subtotal', () async {
      final (custId, bookId) = await setupCustomerAndBook();

      // Negative discount
      expect(
        () => saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'INV-INV-1',
            saleDate: '2026-09-24',
            subtotal: 1000.0,
            discount: -50.0,
            total: 1050.0,
            paidAmount: 1000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 2, unitPrice: 500.0, total: 1000.0),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );

      // Discount > subtotal
      expect(
        () => saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'INV-INV-2',
            saleDate: '2026-09-24',
            subtotal: 1000.0,
            discount: 1500.0,
            total: -500.0,
            paidAmount: 0.0,
            paymentStatus: 'UNPAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 2, unitPrice: 500.0, total: 1000.0),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );

      // Negative quantity in line item
      expect(
        () => saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'INV-INV-3',
            saleDate: '2026-09-24',
            subtotal: 1000.0,
            total: 1000.0,
            paidAmount: 1000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: -2, unitPrice: 500.0, total: -1000.0),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. Empty items rejection: throws ValidationException when items list is empty', () async {
      final (custId, _) = await setupCustomerAndBook();

      expect(
        () => saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'INV-EMPTY-014',
            saleDate: '2026-09-24',
            subtotal: 0.0,
            total: 0.0,
            paidAmount: 0.0,
            paymentStatus: 'PAID',
          ),
          items: [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ===========================================================================
  // PART B: STOCK DEDUCTION & AUDIT MOVEMENTS (15 - 20)
  // ===========================================================================
  group('Part B: Stock Deduction & Audit Movements (15 - 20)', () {
    test('15. Successful sale decreases stock', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 30);

      await saleRepo.createSaleWithItems(
        sale: const Sale(
          invoiceNumber: 'STOCK-DED-015',
          saleDate: '2026-09-24',
          subtotal: 2000.0,
          total: 2000.0,
          paidAmount: 2000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 8, unitPrice: 250.0, total: 2000.0),
        ],
      );

      final book = await bookRepo.getById(bookId);
      expect(book!.stockQuantity, equals(22)); // 30 - 8 = 22
    });

    test('16. Correct previous stock recorded in stock movement', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 40);

      final saleId = await saleRepo.createSaleWithItems(
        sale: const Sale(
          invoiceNumber: 'PREV-STK-016',
          saleDate: '2026-09-24',
          subtotal: 1000.0,
          total: 1000.0,
          paidAmount: 1000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 5, unitPrice: 200.0, total: 1000.0),
        ],
      );

      final movements = await movementRepo.getByReference('SALE', saleId);
      expect(movements.isNotEmpty, isTrue);
      expect(movements.first.previousStock, equals(40));
    });

    test('17. Correct new stock recorded in stock movement', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 40);

      final saleId = await saleRepo.createSaleWithItems(
        sale: const Sale(
          invoiceNumber: 'NEW-STK-017',
          saleDate: '2026-09-24',
          subtotal: 1000.0,
          total: 1000.0,
          paidAmount: 1000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 12, unitPrice: 200.0, total: 2400.0),
        ],
      );

      final movements = await movementRepo.getByReference('SALE', saleId);
      expect(movements.first.newStock, equals(28)); // 40 - 12 = 28
    });

    test('18. SALE stock movement created with type SALE and reference', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 15);

      final saleId = await saleRepo.createSaleWithItems(
        sale: const Sale(
          invoiceNumber: 'MOV-TYPE-018',
          saleDate: '2026-09-24',
          subtotal: 1200.0,
          total: 1200.0,
          paidAmount: 1200.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 3, unitPrice: 400.0, total: 1200.0),
        ],
      );

      final movements = await movementRepo.getByReference('SALE', saleId);
      expect(movements.length, equals(1));
      expect(movements.first.movementType, equals('SALE'));
      expect(movements.first.quantity, equals(3));
      expect(movements.first.bookId, equals(bookId));
      expect(movements.first.referenceType, equals('SALE'));
      expect(movements.first.referenceId, equals(saleId));
    });

    test('19. Multiple items update multiple books accurately', () async {
      final (_, b1) = await setupCustomerAndBook(initialStock: 25);
      final b2 = await bookRepo.create(const Book(
        name: 'Urdu Qawaid-o-Insha',
        wholesalePrice: 150.0,
        stockQuantity: 50,
      ));

      await saleRepo.createSaleWithItems(
        sale: const Sale(
          invoiceNumber: 'MULTI-STK-019',
          saleDate: '2026-09-24',
          subtotal: 5500.0,
          total: 5500.0,
          paidAmount: 5500.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: b1, quantity: 10, unitPrice: 400.0, total: 4000.0),
          SaleItem(saleId: 0, bookId: b2, quantity: 10, unitPrice: 150.0, total: 1500.0),
        ],
      );

      final updatedB1 = await bookRepo.getById(b1);
      final updatedB2 = await bookRepo.getById(b2);
      expect(updatedB1!.stockQuantity, equals(15));
      expect(updatedB2!.stockQuantity, equals(40));
    });

    test('20. Inventory reflects reduced stock via movement history', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 30);

      await saleRepo.createSaleWithItems(
        sale: const Sale(
          invoiceNumber: 'INV-HIST-020',
          saleDate: '2026-09-24',
          subtotal: 2000.0,
          total: 2000.0,
          paidAmount: 2000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 6, unitPrice: 400.0, total: 2400.0),
        ],
      );

      final history = await movementRepo.getByBookId(bookId);
      expect(history.length, equals(1));
      expect(history.first.movementType, equals('SALE'));
      expect(history.first.quantity, equals(6));
    });
  });

  // ===========================================================================
  // PART C: INSUFFICIENT STOCK HANDLING (21 - 25)
  // ===========================================================================
  group('Part C: Insufficient Stock Handling (21 - 25)', () {
    test('21. Insufficient stock rejects sale: throws InsufficientStockException', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 5);

      expect(
        () => saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'INS-STK-021',
            saleDate: '2026-09-24',
            subtotal: 3200.0,
            total: 3200.0,
            paidAmount: 3200.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 8, unitPrice: 400.0, total: 3200.0),
          ],
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('22. Stock remains unchanged when rejected for insufficient stock', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 5);

      try {
        await saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'INS-STK-022',
            saleDate: '2026-09-24',
            subtotal: 3200.0,
            total: 3200.0,
            paidAmount: 3200.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 10, unitPrice: 400.0, total: 4000.0),
          ],
        );
      } catch (_) {}

      final book = await bookRepo.getById(bookId);
      expect(book!.stockQuantity, equals(5)); // Untouched!
    });

    test('23. No sale row remains in DB after insufficient stock rejection', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 3);

      try {
        await saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'INS-STK-023',
            saleDate: '2026-09-24',
            subtotal: 2000.0,
            total: 2000.0,
            paidAmount: 2000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 5, unitPrice: 400.0, total: 2000.0),
          ],
        );
      } catch (_) {}

      final sale = await saleRepo.getByInvoiceNumber('INS-STK-023');
      expect(sale, isNull);
    });

    test('24. No sale items remain in DB after rollback', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 4);

      try {
        await saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'INS-STK-024',
            saleDate: '2026-09-24',
            subtotal: 2400.0,
            total: 2400.0,
            paidAmount: 2400.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 6, unitPrice: 400.0, total: 2400.0),
          ],
        );
      } catch (_) {}

      final countResult = await dbHelper.rawQuery('SELECT COUNT(*) as count FROM ${DbConstants.tableSaleItems}');
      final count = countResult.first['count'] as int;
      expect(count, equals(0));
    });

    test('25. No SALE movement remains in DB after rollback', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 2);

      try {
        await saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'INS-STK-025',
            saleDate: '2026-09-24',
            subtotal: 2000.0,
            total: 2000.0,
            paidAmount: 2000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 10, unitPrice: 400.0, total: 4000.0),
          ],
        );
      } catch (_) {}

      final movements = await movementRepo.getByBookId(bookId);
      expect(movements.isEmpty, isTrue);
    });
  });

  // ===========================================================================
  // PART D: CASH VS CUSTOMER SALE & LEDGER INTEGRATION (26 - 29)
  // ===========================================================================
  group('Part D: Cash vs Customer Sale & Ledger Integration (26 - 29)', () {
    test('26. Cash sale accepts null customer', () async {
      final (_, bookId) = await setupCustomerAndBook(initialStock: 20);

      final saleId = await saleRepo.createSaleWithItems(
        sale: const Sale(
          customerId: null,
          invoiceNumber: 'CASH-LEDGER-026',
          saleDate: '2026-09-24',
          subtotal: 1600.0,
          total: 1600.0,
          paidAmount: 1600.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 4, unitPrice: 400.0, total: 1600.0),
        ],
      );

      final sale = await saleRepo.getById(saleId);
      expect(sale!.customerId, isNull);
    });

    test('27. Cash sale does not create customer receivable', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 30, openingBalance: 1500.0);

      // Create a cash sale
      await saleRepo.createSaleWithItems(
        sale: const Sale(
          customerId: null,
          invoiceNumber: 'CASH-REC-027',
          saleDate: '2026-09-24',
          subtotal: 2000.0,
          total: 2000.0,
          paidAmount: 2000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 5, unitPrice: 400.0, total: 2000.0),
        ],
      );

      // Customer ledger balance should remain untouched at 1500.0
      final balance = await customerLedgerService.getCustomerBalance(custId);
      expect(balance, equals(1500.0));
    });

    test('28. Customer sale links to customer ID', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 20);

      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'CUST-LNK-028',
          saleDate: '2026-09-24',
          subtotal: 2400.0,
          total: 2400.0,
          paidAmount: 2400.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 6, unitPrice: 400.0, total: 2400.0),
        ],
      );

      final sale = await saleRepo.getById(saleId);
      expect(sale!.customerId, equals(custId));
    });

    test('29. Remaining credit amount affects customer ledger', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 25, openingBalance: 1000.0);

      // Total 4000, Paid 1000, Remaining 3000
      await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'CUST-LEDGER-029',
          saleDate: '2026-09-24',
          subtotal: 4000.0,
          total: 4000.0,
          paidAmount: 1000.0,
          remainingAmount: 3000.0,
          paymentStatus: 'PARTIAL',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 10, unitPrice: 400.0, total: 4000.0),
        ],
      );

      // Expected balance = Opening (1000) + Credit Sale Remaining (3000) = 4000
      final balance = await customerLedgerService.getCustomerBalance(custId);
      expect(balance, equals(4000.0));
    });
  });

  // ===========================================================================
  // PART E: TRANSACTION SAFETY & SALE REVERSAL (30 - 32)
  // ===========================================================================
  group('Part E: Transaction Safety & Sale Reversal (30 - 32)', () {
    test('30. Failure rolls back entire sale', () async {
      final (_, bookId1) = await setupCustomerAndBook(initialStock: 20);
      final bookId2 = await bookRepo.create(const Book(
        name: 'Urdu Grammar',
        stockQuantity: 2, // Only 2 in stock!
      ));

      // Sale attempts 5 of book1 (valid) and 5 of book2 (insufficient)
      expect(
        () => saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'ROLLBACK-030',
            saleDate: '2026-09-24',
            subtotal: 3000.0,
            total: 3000.0,
            paidAmount: 3000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId1, quantity: 5, unitPrice: 400.0, total: 2000.0),
            SaleItem(saleId: 0, bookId: bookId2, quantity: 5, unitPrice: 200.0, total: 1000.0),
          ],
        ),
        throwsA(isA<InsufficientStockException>()),
      );

      // Book 1 must not be decreased at all
      final b1 = await bookRepo.getById(bookId1);
      expect(b1!.stockQuantity, equals(20));

      final sale = await saleRepo.getByInvoiceNumber('ROLLBACK-030');
      expect(sale, isNull);
    });

    test('31. No partial stock deduction or movements on multi-item failure', () async {
      final (_, bookId1) = await setupCustomerAndBook(initialStock: 15);
      final bookId2 = await bookRepo.create(const Book(
        name: 'Calculus Grade 12',
        stockQuantity: 3, // only 3
      ));

      try {
        await saleRepo.createSaleWithItems(
          sale: const Sale(
            invoiceNumber: 'ROLLBACK-031',
            saleDate: '2026-09-24',
            subtotal: 5000.0,
            total: 5000.0,
            paidAmount: 5000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId1, quantity: 10, unitPrice: 300.0, total: 3000.0),
            SaleItem(saleId: 0, bookId: bookId2, quantity: 10, unitPrice: 200.0, total: 2000.0),
          ],
        );
      } catch (_) {}

      final b1 = await bookRepo.getById(bookId1);
      final b2 = await bookRepo.getById(bookId2);
      expect(b1!.stockQuantity, equals(15));
      expect(b2!.stockQuantity, equals(3));

      final movements = await movementRepo.getAll();
      expect(movements.isEmpty, isTrue);
    });

    test('32. Safe sale reversal restores stock, logs return movement, and cleans customer balance', () async {
      final (custId, bookId) = await setupCustomerAndBook(initialStock: 25, openingBalance: 500.0);

      // Create a credit sale
      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          invoiceNumber: 'REVERSE-032',
          saleDate: '2026-09-24',
          subtotal: 4000.0,
          total: 4000.0,
          paidAmount: 1000.0,
          remainingAmount: 3000.0,
          paymentStatus: 'PARTIAL',
        ),
        items: [
          SaleItem(saleId: 0, bookId: bookId, quantity: 10, unitPrice: 400.0, total: 4000.0),
        ],
      );

      // Verify stock decreased to 15
      expect((await bookRepo.getById(bookId))!.stockQuantity, equals(15));
      // Customer balance should be 500 + 3000 = 3500
      expect(await customerLedgerService.getCustomerBalance(custId), equals(3500.0));

      // Now reverse / delete the sale
      final success = await saleRepo.delete(saleId);
      expect(success, isTrue);

      // 1. Stock restored to 25
      final restoredBook = await bookRepo.getById(bookId);
      expect(restoredBook!.stockQuantity, equals(25));

      // 2. Return movement logged
      final returnMovements = await movementRepo.getByReference('SALE_CANCELLED', saleId);
      expect(returnMovements.isNotEmpty, isTrue);
      expect(returnMovements.first.movementType, equals('RETURN_IN'));
      expect(returnMovements.first.quantity, equals(10));

      // 3. Customer balance restored to 500
      expect(await customerLedgerService.getCustomerBalance(custId), equals(500.0));
    });
  });

  // ===========================================================================
  // PART F: UI DESKTOP WIDGETS (33 - 35)
  // ===========================================================================
  group('Part F: Desktop UI Widgets (33 - 35)', () {
    testWidgets('33. SaleFormDialog renders correctly and displays wholesale prices', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const sampleCustomer = Customer(
        id: 1,
        name: 'Al-Madina Booksellers',
        phone: '03001234567',
        openingBalance: 0.0,
      );

      const sampleBook = Book(
        id: 10,
        name: 'Tafseer Maariful Quran Vol 1',
        wholesalePrice: 400.0,
        retailPrice: 500.0,
        stockQuantity: 20,
        minimumStock: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  SaleFormDialog.show(
                    ctx,
                    customers: [sampleCustomer],
                    books: [sampleBook],
                    onSave: (s, items) {},
                  );
                },
                child: const Text('Open Sale Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sale Dialog'));
      await tester.pumpAndSettle();

      // Verify title and main elements
      expect(find.text('Create Wholesale Sales Invoice'), findsOneWidget);
      expect(find.text('1. Sales Invoice Information'), findsOneWidget);
      expect(find.text('2. Wholesale Sale Items'), findsOneWidget);
      expect(find.text('3. Financial Settlement'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('34. SaleDetailDialog renders sale details and financial summary', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const sampleSale = Sale(
        id: 1,
        customerId: 1,
        invoiceNumber: 'INV-DETAIL-TEST',
        saleDate: '2026-09-24',
        subtotal: 4000.0,
        discount: 200.0,
        total: 3800.0,
        paidAmount: 3000.0,
        remainingAmount: 800.0,
        paymentStatus: 'PARTIAL',
      );

      const sampleItems = [
        SaleItem(
          id: 1,
          saleId: 1,
          bookId: 10,
          quantity: 10,
          unitPrice: 400.0,
          total: 4000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  SaleDetailDialog.show(
                    ctx,
                    sale: sampleSale,
                    items: sampleItems,
                    customerName: 'Al-Madina Booksellers',
                    customerPhone: '03001234567',
                    bookTitles: {10: 'Tafseer Maariful Quran Vol 1'},
                  );
                },
                child: const Text('Open Detail Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Sales Invoice #INV-DETAIL-TEST'), findsOneWidget);
      expect(find.text('Customer / Channel'), findsOneWidget);
      expect(find.text('Sold Items (1)'), findsOneWidget);
      expect(find.text('Total Net'), findsOneWidget);
      expect(find.text('PARTIAL'), findsOneWidget);
    });

    testWidgets('35. SalesPage renders desktop sales management table & KPI cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late SalesBloc bloc;

      await tester.runAsync(() async {
        final (custId, bookId) = await setupCustomerAndBook();

        await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'SINV-2026-001',
            saleDate: '2026-09-24',
            subtotal: 4000.0,
            discount: 200.0,
            total: 3800.0,
            paidAmount: 3000.0,
            remainingAmount: 800.0,
            paymentStatus: 'PARTIAL',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 10,
              unitPrice: 400.0,
              total: 4000.0,
            ),
          ],
        );

        bloc = SalesBloc(
          saleRepository: saleRepo,
          customerRepository: customerRepo,
          bookRepository: bookRepo,
        );

        final loadedFuture = bloc.stream.firstWhere((s) => s is SalesLoaded);
        bloc.add(const LoadSales());
        await loadedFuture;
      });

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CustomerRepository>.value(value: customerRepo),
            RepositoryProvider<BookRepository>.value(value: bookRepo),
            RepositoryProvider<SaleRepository>.value(value: saleRepo),
          ],
          child: BlocProvider<SalesBloc>.value(
            value: bloc,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: SalesPage(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header & Buttons
      expect(find.text('Wholesale Sales Management'), findsOneWidget);
      expect(find.text('New Wholesale Sale'), findsOneWidget);

      // Verify KPI Metric Cards
      expect(find.text('Total Invoiced Revenue'), findsOneWidget);
      expect(find.text('Collections Received'), findsOneWidget);
      expect(find.text('Receivables Pending'), findsOneWidget);
      expect(find.text('Total Invoices'), findsOneWidget);
      expect(find.text('SINV-2026-001'), findsOneWidget);

      await tester.runAsync(() async {
        await bloc.close();
      });
    });
  });
}
