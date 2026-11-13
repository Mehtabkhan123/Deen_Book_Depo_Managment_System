import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/errors/exceptions.dart';
import 'package:deen_book_depo/core/theme/app_theme.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/books/presentation/bloc/books_bloc.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/data/services/customer_ledger_service_impl.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/services/customer_ledger_service.dart';
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/data/services/inventory_stock_service.dart';
import 'package:deen_book_depo/features/inventory/domain/constants/stock_movement_types.dart';
import 'package:deen_book_depo/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/domain/services/stock_service.dart';
import 'package:deen_book_depo/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:deen_book_depo/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:deen_book_depo/features/sales/data/repositories/sqlite_sale_repository.dart';
import 'package:deen_book_depo/features/sales/domain/repositories/sale_repository.dart';
import 'package:deen_book_depo/features/sales/presentation/bloc/sales_bloc.dart';
import 'package:deen_book_depo/features/sales/presentation/pages/pos_billing_page.dart';
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
  late CustomerLedgerService customerLedger;
  late SaleRepository saleRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step11_pos_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}pos_test.db';

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

    customerLedger = CustomerLedgerServiceImpl(
      customerRepository: customerRepo,
      dbHelper: dbHelper,
    );

    saleRepo = SqliteSaleRepository(
      bookRepository: bookRepo,
      stockService: stockService,
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

  Future<(int, int)> setupCustomerAndBook({
    int initialStock = 50,
    double wholesalePrice = 400.0,
    double retailPrice = 500.0,
  }) async {
    final custId = await customerRepo.create(
      const Customer(
        name: 'Dar-us-Salam Booksellers',
        phone: '0300-1122334',
        address: 'Urdu Bazar, Lahore',
        openingBalance: 0.0,
      ),
    );

    final catId = await categoryRepo.create(
      const Category(name: 'Islamic Studies'),
    );

    final bookId = await bookRepo.create(
      Book(
        categoryId: catId,
        name: 'Seerat-un-Nabi Vol 1',
        isbn: '978-969-001',
        author: 'Shibli Nomani',
        publisher: 'Maktaba Quddusia',
        purchasePrice: 300.0,
        wholesalePrice: wholesalePrice,
        retailPrice: retailPrice,
        stockQuantity: initialStock,
        minimumStock: 5,
      ),
    );

    return (custId, bookId);
  }

  // ==========================================
  // Part A: Retail vs. Wholesale Sales
  // ==========================================
  group('Part A: Retail vs Wholesale POS Sales', () {
    test(
      '1. Retail Sale stores actual retail price and deducts stock',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(
          initialStock: 30,
          wholesalePrice: 400.0,
          retailPrice: 500.0,
        );

        final saleId = await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'RET-2026-001',
            saleDate: '2026-11-01',
            subtotal: 1500.0,
            total: 1500.0,
            paidAmount: 1500.0,
            paymentStatus: 'PAID',
            notes: '[RETAIL POS] Counter Cash Sale',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 3,
              unitPrice: 500.0, // Retail price applied
              total: 1500.0,
            ),
          ],
        );

        expect(saleId, greaterThan(0));

        // Verify line items record actual retail price
        final items = await saleRepo.getItemsForSale(saleId);
        expect(items.length, equals(1));
        expect(items.first.unitPrice, equals(500.0));
        expect(items.first.total, equals(1500.0));

        // Verify stock decreased from 30 to 27
        final book = await bookRepo.getById(bookId);
        expect(book?.stockQuantity, equals(27));

        // Verify stock movement
        final movements = await movementRepo.getByReference('SALE', saleId);
        expect(movements.length, equals(1));
        expect(movements.first.movementType, equals(StockMovementTypes.sale));
        expect(movements.first.quantity, equals(3));
        expect(movements.first.previousStock, equals(30));
        expect(movements.first.newStock, equals(27));
      },
    );

    test(
      '2. Wholesale Sale stores wholesale price and deducts bulk stock',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(
          initialStock: 100,
          wholesalePrice: 380.0,
          retailPrice: 500.0,
        );

        final saleId = await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'WHO-2026-001',
            saleDate: '2026-11-01',
            subtotal: 7600.0,
            total: 7600.0,
            paidAmount: 7600.0,
            paymentStatus: 'PAID',
            notes: '[WHOLESALE POS] Bulk Order',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 20,
              unitPrice: 380.0, // Wholesale price applied
              total: 7600.0,
            ),
          ],
        );

        expect(saleId, greaterThan(0));

        final items = await saleRepo.getItemsForSale(saleId);
        expect(items.first.unitPrice, equals(380.0));
        expect(items.first.quantity, equals(20));

        final book = await bookRepo.getById(bookId);
        expect(book?.stockQuantity, equals(80));
      },
    );
  });

  // ==========================================
  // Part B: Walk-in Cash vs Registered Customer Credit
  // ==========================================
  group('Part B: Walk-in vs Registered Customer Credit', () {
    test(
      '3. Walk-in Sale with null customerId succeeds and does not touch ledger',
      () async {
        final (_, bookId) = await setupCustomerAndBook(initialStock: 20);

        final saleId = await saleRepo.createSaleWithItems(
          sale: const Sale(
            customerId: null, // Walk-in customer
            invoiceNumber: 'WALK-IN-001',
            saleDate: '2026-11-01',
            subtotal: 500.0,
            total: 500.0,
            paidAmount: 500.0,
            paymentStatus: 'PAID',
            notes: '[RETAIL POS] Walk-in cash customer',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 1,
              unitPrice: 500.0,
              total: 500.0,
            ),
          ],
        );

        expect(saleId, greaterThan(0));
        final savedSale = await saleRepo.getById(saleId);
        expect(savedSale?.customerId, isNull);
        expect(savedSale?.paymentStatus, equals('PAID'));

        final book = await bookRepo.getById(bookId);
        expect(book?.stockQuantity, equals(19));
      },
    );

    test(
      '4. Registered Customer full credit sale increases customer ledger balance',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(initialStock: 25);

        final saleId = await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'CREDIT-001',
            saleDate: '2026-11-01',
            subtotal: 2000.0,
            total: 2000.0,
            paidAmount: 0.0, // Full credit
            remainingAmount: 2000.0,
            paymentStatus: 'UNPAID',
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

        expect(saleId, greaterThan(0));

        // Customer balance should now be 2000.0
        final balance = await customerLedger.getCustomerBalance(custId);
        expect(balance, equals(2000.0));
      },
    );

    test(
      '5. Registered Customer partial payment updates ledger with remaining amount',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(initialStock: 25);

        final saleId = await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'PARTIAL-001',
            saleDate: '2026-11-01',
            subtotal: 4000.0,
            total: 4000.0,
            paidAmount: 1500.0, // Partial cash received
            remainingAmount: 2500.0, // Remaining due
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

        expect(saleId, greaterThan(0));

        // Customer balance should increase exactly by 2500.0
        final balance = await customerLedger.getCustomerBalance(custId);
        expect(balance, equals(2500.0));
      },
    );
  });

  // ==========================================
  // Part C: Discounts Calculation
  // ==========================================
  group('Part C: Item-level and Overall Discounts', () {
    test(
      '6. Line item discount and overall invoice discount calculate correctly',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(initialStock: 20);

        // Line item: 4 units @ Rs. 500 = 2000 - 100 line discount = 1900
        // Overall discount = 150 -> Grand Total = 1750
        final saleId = await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'DISC-001',
            saleDate: '2026-11-01',
            subtotal: 1900.0,
            discount: 150.0,
            total: 1750.0,
            paidAmount: 1750.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 4,
              unitPrice: 500.0,
              discount: 100.0,
              total: 1900.0,
            ),
          ],
        );

        final sale = await saleRepo.getById(saleId);
        expect(sale?.subtotal, equals(1900.0));
        expect(sale?.discount, equals(150.0));
        expect(sale?.total, equals(1750.0));

        final items = await saleRepo.getItemsForSale(saleId);
        expect(items.first.discount, equals(100.0));
        expect(items.first.total, equals(1900.0));
      },
    );

    test(
      '7. Reject negative discount or discount exceeding subtotal',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(initialStock: 10);

        // Negative discount
        expect(
          () => saleRepo.createSaleWithItems(
            sale: Sale(
              customerId: custId,
              invoiceNumber: 'INVALID-DISC-1',
              saleDate: '2026-11-01',
              subtotal: 1000.0,
              discount: -50.0,
              total: 1050.0,
              paidAmount: 1050.0,
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
          throwsA(isA<ValidationException>()),
        );

        // Discount exceeds subtotal
        expect(
          () => saleRepo.createSaleWithItems(
            sale: Sale(
              customerId: custId,
              invoiceNumber: 'INVALID-DISC-2',
              saleDate: '2026-11-01',
              subtotal: 1000.0,
              discount: 1200.0,
              total: 0.0,
              paidAmount: 0.0,
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
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });

  // ==========================================
  // Part D: Stock Validation & Prevention of Over-selling
  // ==========================================
  group('Part D: Available Stock Validation', () {
    test(
      '8. InsufficientStockException thrown when sale quantity exceeds stock',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(initialStock: 8);

        expect(
          () => saleRepo.createSaleWithItems(
            sale: Sale(
              customerId: custId,
              invoiceNumber: 'OVERSOLD-001',
              saleDate: '2026-11-01',
              subtotal: 4500.0,
              total: 4500.0,
              paidAmount: 4500.0,
              paymentStatus: 'PAID',
            ),
            items: [
              SaleItem(
                saleId: 0,
                bookId: bookId,
                quantity: 9, // Stock is only 8!
                unitPrice: 500.0,
                total: 4500.0,
              ),
            ],
          ),
          throwsA(
            isA<InsufficientStockException>()
                .having((e) => e.availableStock, 'availableStock', equals(8))
                .having(
                  (e) => e.requestedQuantity,
                  'requestedQuantity',
                  equals(9),
                ),
          ),
        );

        // Stock must remain unchanged
        final book = await bookRepo.getById(bookId);
        expect(book?.stockQuantity, equals(8));
      },
    );
  });

  // ==========================================
  // Part E: Invoice Uniqueness
  // ==========================================
  group('Part E: Invoice Uniqueness', () {
    test(
      '9. Duplicate invoice number throws DuplicateInvoiceException',
      () async {
        final (custId, bookId) = await setupCustomerAndBook(initialStock: 20);

        // First sale
        await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'UNIQUE-INV-100',
            saleDate: '2026-11-01',
            subtotal: 500.0,
            total: 500.0,
            paidAmount: 500.0,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 1,
              unitPrice: 500.0,
              total: 500.0,
            ),
          ],
        );

        // Second sale with duplicate invoice number
        expect(
          () => saleRepo.createSaleWithItems(
            sale: Sale(
              customerId: custId,
              invoiceNumber: 'UNIQUE-INV-100', // DUPLICATE
              saleDate: '2026-11-01',
              subtotal: 500.0,
              total: 500.0,
              paidAmount: 500.0,
              paymentStatus: 'PAID',
            ),
            items: [
              SaleItem(
                saleId: 0,
                bookId: bookId,
                quantity: 1,
                unitPrice: 500.0,
                total: 500.0,
              ),
            ],
          ),
          throwsA(isA<DuplicateInvoiceException>()),
        );
      },
    );
  });

  // ==========================================
  // Part F: Transaction Rollback Integrity
  // ==========================================
  group('Part F: Atomic Transaction Rollback', () {
    test(
      '10. Multi-item sale rollback: item 2 fails, item 1 stock is restored',
      () async {
        final (custId, bookId1) = await setupCustomerAndBook(initialStock: 10);

        // Create a second book with only 2 stock
        final bookId2 = await bookRepo.create(
          const Book(
            name: 'Mukhtasar Al-Quduri',
            isbn: '978-969-002',
            wholesalePrice: 200.0,
            retailPrice: 250.0,
            stockQuantity: 2, // Low stock
            minimumStock: 1,
          ),
        );

        // Multi-item sale where item 2 requests 5 units (exceeding stock of 2)
        expect(
          () => saleRepo.createSaleWithItems(
            sale: Sale(
              customerId: custId,
              invoiceNumber: 'ROLLBACK-001',
              saleDate: '2026-11-01',
              subtotal: 2250.0,
              total: 2250.0,
              paidAmount: 2250.0,
              paymentStatus: 'PAID',
            ),
            items: [
              SaleItem(
                saleId: 0,
                bookId: bookId1,
                quantity: 2,
                unitPrice: 500.0,
                total: 1000.0,
              ),
              SaleItem(
                saleId: 0,
                bookId: bookId2,
                quantity: 5,
                unitPrice: 250.0,
                total: 1250.0,
              ), // Fails!
            ],
          ),
          throwsA(isA<InsufficientStockException>()),
        );

        // Verify Book 1 stock was NOT decremented
        final book1 = await bookRepo.getById(bookId1);
        expect(book1?.stockQuantity, equals(10));

        // Verify Book 2 stock remained intact
        final book2 = await bookRepo.getById(bookId2);
        expect(book2?.stockQuantity, equals(2));

        // Verify no sale inserted
        final sales = await saleRepo.getAll();
        expect(sales, isEmpty);

        // Verify no movements recorded
        final movements = await movementRepo.getAll();
        expect(movements, isEmpty);
      },
    );
  });

  // ==========================================
  // Part G: Desktop POS UI Widget Tests
  // ==========================================
  group('Part G: POS Desktop UI Widget Tests', () {
    testWidgets(
      '11. PosBillingPage renders header, tier switcher, search bar and settlement drawer',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final (custId, bookId) = await setupCustomerAndBook(
          initialStock: 40,
          wholesalePrice: 350.0,
          retailPrice: 450.0,
        );

        late SalesBloc salesBloc;
        late BooksBloc booksBloc;
        late NavigationBloc navBloc;

        await tester.runAsync(() async {
          salesBloc = SalesBloc(
            saleRepository: saleRepo,
            customerRepository: customerRepo,
            bookRepository: bookRepo,
          );
          booksBloc = BooksBloc(bookRepository: bookRepo);
          navBloc = NavigationBloc();

          salesBloc.add(const LoadSales());
          await salesBloc.stream.firstWhere((s) => s is SalesLoaded);
        });

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SalesBloc>.value(value: salesBloc),
              BlocProvider<BooksBloc>.value(value: booksBloc),
              BlocProvider<NavigationBloc>.value(value: navBloc),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PosBillingPage(),
            ),
          ),
        );

        await tester.runAsync(() async {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await tester.pump();
        });

        // Verify POS Terminal Title & Subtitle
        expect(find.text('POS Billing Terminal'), findsOneWidget);
        expect(
          find.text('High-Speed Wholesale & Retail Counter Checkout'),
          findsOneWidget,
        );

        // Verify Tier Switcher
        expect(find.text('RETAIL SALE'), findsOneWidget);
        expect(find.text('WHOLESALE SALE'), findsOneWidget);

        // Verify Barcode / Search Input
        expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);

        // Verify Empty Cart State initially
        expect(find.text('Cart is Empty'), findsOneWidget);

        // Verify Financial Settlement Drawer
        expect(find.text('Customer & Channel'), findsOneWidget);
        expect(find.text('Walk-in Cash'), findsOneWidget);
        expect(find.text('Registered Client'), findsOneWidget);
        expect(find.text('Financial Settlement'), findsOneWidget);
        expect(find.text('GRAND TOTAL'), findsOneWidget);
        expect(find.text('COMPLETE & SAVE SALE'), findsOneWidget);

        await tester.runAsync(() async {
          await salesBloc.close();
          await booksBloc.close();
          await navBloc.close();
        });
      },
    );

    testWidgets(
      '12. PosBillingPage switches between Retail and Wholesale pricing tiers',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await setupCustomerAndBook(
          initialStock: 40,
          wholesalePrice: 350.0,
          retailPrice: 450.0,
        );

        late SalesBloc salesBloc;
        late BooksBloc booksBloc;
        late NavigationBloc navBloc;

        await tester.runAsync(() async {
          salesBloc = SalesBloc(
            saleRepository: saleRepo,
            customerRepository: customerRepo,
            bookRepository: bookRepo,
          );
          booksBloc = BooksBloc(bookRepository: bookRepo);
          navBloc = NavigationBloc();

          salesBloc.add(const LoadSales());
          await salesBloc.stream.firstWhere((s) => s is SalesLoaded);
        });

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<SalesBloc>.value(value: salesBloc),
              BlocProvider<BooksBloc>.value(value: booksBloc),
              BlocProvider<NavigationBloc>.value(value: navBloc),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const PosBillingPage(),
            ),
          ),
        );

        await tester.runAsync(() async {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await tester.pump();

          // Tap Wholesale Sale button
          await tester.tap(find.text('WHOLESALE SALE'));
          await tester.pump();

          // Tap Retail Sale button
          await tester.tap(find.text('RETAIL SALE'));
          await tester.pump();
        });

        expect(find.text('RETAIL SALE'), findsOneWidget);

        await tester.runAsync(() async {
          await salesBloc.close();
          await booksBloc.close();
          await navBloc.close();
        });
      },
    );
  });
}
