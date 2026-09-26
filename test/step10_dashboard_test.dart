import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/theme/theme.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/data/services/customer_ledger_service_impl.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/services/customer_ledger_service.dart';
import 'package:deen_book_depo/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:deen_book_depo/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:deen_book_depo/features/expenses/data/repositories/sqlite_expense_repository.dart';
import 'package:deen_book_depo/features/expenses/domain/repositories/expense_repository.dart';
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/data/services/inventory_stock_service.dart';
import 'package:deen_book_depo/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/domain/services/stock_service.dart';
import 'package:deen_book_depo/features/payments/data/repositories/sqlite_customer_payment_repository.dart';
import 'package:deen_book_depo/features/payments/data/repositories/sqlite_supplier_payment_repository.dart';
import 'package:deen_book_depo/features/payments/domain/repositories/customer_payment_repository.dart';
import 'package:deen_book_depo/features/payments/domain/repositories/supplier_payment_repository.dart';
import 'package:deen_book_depo/features/purchases/data/repositories/sqlite_purchase_repository.dart';
import 'package:deen_book_depo/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:deen_book_depo/features/sales/data/repositories/sqlite_sale_repository.dart';
import 'package:deen_book_depo/features/sales/domain/repositories/sale_repository.dart';
import 'package:deen_book_depo/features/suppliers/data/repositories/sqlite_supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/data/services/supplier_ledger_service_impl.dart';
import 'package:deen_book_depo/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/domain/services/supplier_ledger_service.dart';
import 'package:deen_book_depo/shared/models/book.dart';
import 'package:deen_book_depo/shared/models/category.dart';
import 'package:deen_book_depo/shared/models/customer.dart';
import 'package:deen_book_depo/shared/models/customer_payment.dart';
import 'package:deen_book_depo/shared/models/expense.dart';
import 'package:deen_book_depo/shared/models/purchase.dart';
import 'package:deen_book_depo/shared/models/purchase_item.dart';
import 'package:deen_book_depo/shared/models/sale.dart';
import 'package:deen_book_depo/shared/models/sale_item.dart';
import 'package:deen_book_depo/shared/models/supplier.dart';
import 'package:deen_book_depo/shared/models/supplier_payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testDbPath;
  late DatabaseService dbService;
  late DatabaseHelper dbHelper;

  late CategoryRepository categoryRepo;
  late BookRepository bookRepo;
  late CustomerRepository customerRepo;
  late SupplierRepository supplierRepo;
  late StockMovementRepository movementRepo;
  late StockService stockService;
  late CustomerLedgerService customerLedgerService;
  late SupplierLedgerService supplierLedgerService;
  late PurchaseRepository purchaseRepo;
  late SaleRepository saleRepo;
  late CustomerPaymentRepository customerPaymentRepo;
  late SupplierPaymentRepository supplierPaymentRepo;
  late ExpenseRepository expenseRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step10_dashboard_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}dashboard_test.db';

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: testDbPath);
    dbHelper = DatabaseHelper(dbService);

    categoryRepo = SqliteCategoryRepository(dbHelper);
    bookRepo = SqliteBookRepository(dbHelper);
    customerRepo = SqliteCustomerRepository(dbHelper);
    supplierRepo = SqliteSupplierRepository(dbHelper);
    customerPaymentRepo = SqliteCustomerPaymentRepository(dbHelper);
    supplierPaymentRepo = SqliteSupplierPaymentRepository(dbHelper);
    expenseRepo = SqliteExpenseRepository(dbHelper);
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

    supplierLedgerService = SupplierLedgerServiceImpl(
      supplierRepository: supplierRepo,
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
  });

  tearDown(() async {
    await dbService.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  DashboardBloc createBloc() {
    return DashboardBloc(
      bookRepository: bookRepo,
      saleRepository: saleRepo,
      purchaseRepository: purchaseRepo,
      customerRepository: customerRepo,
      supplierRepository: supplierRepo,
      customerLedgerService: customerLedgerService,
      supplierLedgerService: supplierLedgerService,
      databaseHelper: dbHelper,
      expenseRepository: expenseRepo,
      customerPaymentRepository: customerPaymentRepo,
      supplierPaymentRepository: supplierPaymentRepo,
    );
  }

  group('Part A: Real SQLite Aggregation & Metric Computation Tests', () {
    test('1. Empty database yields all 0 metrics, 0.0 balances, and empty lists', () async {
      final bloc = createBloc();

      expect(bloc.state, isA<DashboardInitial>());
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.totalBooks,
            'totalBooks',
            equals(0),
          ).having(
            (s) => s.metrics.currentStock,
            'currentStock',
            equals(0),
          ).having(
            (s) => s.metrics.lowStockCount,
            'lowStockCount',
            equals(0),
          ).having(
            (s) => s.metrics.outOfStockCount,
            'outOfStockCount',
            equals(0),
          ).having(
            (s) => s.metrics.todaySalesCount,
            'todaySalesCount',
            equals(0),
          ).having(
            (s) => s.metrics.todaySalesTotal,
            'todaySalesTotal',
            equals(0.0),
          ).having(
            (s) => s.metrics.todayPurchasesCount,
            'todayPurchasesCount',
            equals(0),
          ).having(
            (s) => s.metrics.todayPurchasesTotal,
            'todayPurchasesTotal',
            equals(0.0),
          ).having(
            (s) => s.metrics.todayCustomerPaymentsCount,
            'todayCustomerPaymentsCount',
            equals(0),
          ).having(
            (s) => s.metrics.todayCustomerPaymentsTotal,
            'todayCustomerPaymentsTotal',
            equals(0.0),
          ).having(
            (s) => s.metrics.todaySupplierPaymentsCount,
            'todaySupplierPaymentsCount',
            equals(0),
          ).having(
            (s) => s.metrics.todaySupplierPaymentsTotal,
            'todaySupplierPaymentsTotal',
            equals(0.0),
          ).having(
            (s) => s.metrics.todayExpensesCount,
            'todayExpensesCount',
            equals(0),
          ).having(
            (s) => s.metrics.todayExpensesTotal,
            'todayExpensesTotal',
            equals(0.0),
          ).having(
            (s) => s.metrics.customerReceivables,
            'customerReceivables',
            equals(0.0),
          ).having(
            (s) => s.metrics.supplierPayables,
            'supplierPayables',
            equals(0.0),
          ).having(
            (s) => s.metrics.recentSales,
            'recentSales',
            isEmpty,
          ).having(
            (s) => s.metrics.recentPurchases,
            'recentPurchases',
            isEmpty,
          ).having(
            (s) => s.metrics.lowStockBooks,
            'lowStockBooks',
            isEmpty,
          ),
        ]),
      );

      await bloc.close();
    });

    test("2. Today's Sales aggregates only invoices billed today", () async {
      final catId = await categoryRepo.create(const Category(name: 'Islamic Studies'));
      final bookId = await bookRepo.create(Book(
        name: 'Tafseer Ibn Katheer',
        categoryId: catId,
        stockQuantity: 100,
        minimumStock: 10,
        purchasePrice: 500,
        wholesalePrice: 800,
        retailPrice: 1000,
      ));

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final yesterdayStr = '2020-01-01';

      // Sale today
      await saleRepo.createSaleWithItems(
        sale: Sale(
          invoiceNumber: 'INV-TODAY-01',
          saleDate: '${todayStr}T10:00:00.000',
          subtotal: 1600,
          total: 1600,
          paidAmount: 1600,
          remainingAmount: 0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 2,
            unitPrice: 800,
            total: 1600,
          ),
        ],
      );

      // Sale yesterday
      await saleRepo.createSaleWithItems(
        sale: Sale(
          invoiceNumber: 'INV-YEST-01',
          saleDate: '${yesterdayStr}T10:00:00.000',
          subtotal: 800,
          total: 800,
          paidAmount: 800,
          remainingAmount: 0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 1,
            unitPrice: 800,
            total: 800,
          ),
        ],
      );

      final bloc = createBloc();
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.todaySalesCount,
            'todaySalesCount',
            equals(1),
          ).having(
            (s) => s.metrics.todaySalesTotal,
            'todaySalesTotal',
            equals(1600.0),
          ),
        ]),
      );

      await bloc.close();
    });

    test("3. Today's Purchases aggregates only inward shipments received today", () async {
      final suppId = await supplierRepo.create(const Supplier(name: 'Darussalam Publishers'));
      final bookId = await bookRepo.create(const Book(
        name: 'Ar-Raheeq Al-Makhtum',
        stockQuantity: 10,
        minimumStock: 5,
        purchasePrice: 400,
      ));

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final yesterdayStr = '2020-01-01';

      // Purchase today
      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PUR-TODAY-01',
          purchaseDate: '${todayStr}T11:00:00.000',
          subtotal: 4000,
          total: 4000,
          paidAmount: 4000,
          remainingAmount: 0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 10,
            unitPrice: 400,
            total: 4000,
          ),
        ],
      );

      // Purchase yesterday
      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PUR-YEST-01',
          purchaseDate: '${yesterdayStr}T11:00:00.000',
          subtotal: 2000,
          total: 2000,
          paidAmount: 2000,
          remainingAmount: 0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 5,
            unitPrice: 400,
            total: 2000,
          ),
        ],
      );

      final bloc = createBloc();
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.todayPurchasesCount,
            'todayPurchasesCount',
            equals(1),
          ).having(
            (s) => s.metrics.todayPurchasesTotal,
            'todayPurchasesTotal',
            equals(4000.0),
          ),
        ]),
      );

      await bloc.close();
    });

    test("4. Today's Customer Payments, Supplier Payments, and Expenses", () async {
      final custId = await customerRepo.create(const Customer(name: 'Al-Huda Islamic School'));
      final suppId = await supplierRepo.create(const Supplier(name: 'Maktaba Qudoos'));

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final yesterdayStr = '2020-01-01';

      // Customer payments
      await customerPaymentRepo.create(CustomerPayment(
        customerId: custId,
        amount: 2500,
        paymentDate: '${todayStr}T14:00:00.000',
        paymentMethod: 'CASH',
      ));
      await customerPaymentRepo.create(CustomerPayment(
        customerId: custId,
        amount: 1000,
        paymentDate: '${yesterdayStr}T14:00:00.000',
        paymentMethod: 'BANK_TRANSFER',
      ));

      // Supplier payments
      await supplierPaymentRepo.create(SupplierPayment(
        supplierId: suppId,
        amount: 3200,
        paymentDate: '${todayStr}T15:00:00.000',
        paymentMethod: 'CHEQUE',
      ));
      await supplierPaymentRepo.create(SupplierPayment(
        supplierId: suppId,
        amount: 1500,
        paymentDate: '${yesterdayStr}T15:00:00.000',
        paymentMethod: 'CASH',
      ));

      // Expenses
      await expenseRepo.create(Expense(
        title: 'Warehouse Electricity Bill',
        amount: 750,
        expenseDate: '${todayStr}T16:00:00.000',
      ));
      await expenseRepo.create(Expense(
        title: 'Office Stationery',
        amount: 500,
        expenseDate: '${yesterdayStr}T16:00:00.000',
      ));

      final bloc = createBloc();
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.todayCustomerPaymentsCount,
            'todayCustomerPaymentsCount',
            equals(1),
          ).having(
            (s) => s.metrics.todayCustomerPaymentsTotal,
            'todayCustomerPaymentsTotal',
            equals(2500.0),
          ).having(
            (s) => s.metrics.todaySupplierPaymentsCount,
            'todaySupplierPaymentsCount',
            equals(1),
          ).having(
            (s) => s.metrics.todaySupplierPaymentsTotal,
            'todaySupplierPaymentsTotal',
            equals(3200.0),
          ).having(
            (s) => s.metrics.todayExpensesCount,
            'todayExpensesCount',
            equals(1),
          ).having(
            (s) => s.metrics.todayExpensesTotal,
            'todayExpensesTotal',
            equals(750.0),
          ),
        ]),
      );

      await bloc.close();
    });

    test('5. Catalog & stock classification: Total Books, Current Stock, Low Stock, Out of Stock', () async {
      // Book 1: Healthy stock (stock 50 > min 10)
      await bookRepo.create(const Book(
        name: 'Sahih Al-Bukhari Vol 1',
        stockQuantity: 50,
        minimumStock: 10,
      ));

      // Book 2: Low stock (stock 5 <= min 10 AND stock > 0)
      await bookRepo.create(const Book(
        name: 'Sahih Muslim Vol 1',
        stockQuantity: 5,
        minimumStock: 10,
      ));

      // Book 3: Out of stock (stock 0)
      await bookRepo.create(const Book(
        name: 'Sunan Abi Dawood',
        stockQuantity: 0,
        minimumStock: 5,
      ));

      final bloc = createBloc();
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.totalBooks,
            'totalBooks',
            equals(3),
          ).having(
            (s) => s.metrics.currentStock,
            'currentStock',
            equals(55),
          ).having(
            (s) => s.metrics.lowStockCount,
            'lowStockCount',
            equals(1),
          ).having(
            (s) => s.metrics.outOfStockCount,
            'outOfStockCount',
            equals(1),
          ).having(
            (s) => s.metrics.lowStockBooks.length,
            'lowStockBooks.length',
            equals(2), // Both out of stock and low stock are returned in alerts
          ),
        ]),
      );

      await bloc.close();
    });

    test('6. Customer Receivables & Supplier Payables calculated via domain ledger services', () async {
      // Customer 1 with opening balance of 5,000 (receivable)
      await customerRepo.create(const Customer(
        name: 'Iqra Book Agency',
        openingBalance: 5000.0,
      ));

      // Customer 2 with zero balance
      await customerRepo.create(const Customer(
        name: 'Modern Readers',
        openingBalance: 0.0,
      ));

      // Supplier 1 with opening balance of 8,500 (payable)
      await supplierRepo.create(const Supplier(
        name: 'Al-Bayan Printing Press',
        openingBalance: 8500.0,
      ));

      // Supplier 2 with zero balance
      await supplierRepo.create(const Supplier(
        name: 'Local Binding Depot',
        openingBalance: 0.0,
      ));

      final bloc = createBloc();
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.customerReceivables,
            'customerReceivables',
            equals(5000.0),
          ).having(
            (s) => s.metrics.supplierPayables,
            'supplierPayables',
            equals(8500.0),
          ),
        ]),
      );

      await bloc.close();
    });

    test('7. Recent 10 Sales & Recent 10 Purchases enforces LIMIT 10 and date DESC ordering', () async {
      final suppId = await supplierRepo.create(const Supplier(name: 'Main Publisher'));
      final bookId = await bookRepo.create(const Book(
        name: 'Urdu Lughat',
        stockQuantity: 500,
        purchasePrice: 200,
        wholesalePrice: 300,
      ));

      // Create 12 purchases
      for (int i = 1; i <= 12; i++) {
        final pad = i.toString().padLeft(2, '0');
        await purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PUR-0$pad',
            purchaseDate: '2026-09-${pad}T10:00:00.000',
            subtotal: 1000,
            total: 1000,
            paidAmount: 1000,
            paymentStatus: 'PAID',
          ),
          items: [
            PurchaseItem(
              purchaseId: 0,
              bookId: bookId,
              quantity: 5,
              unitPrice: 200,
              total: 1000,
            ),
          ],
        );
      }

      // Create 12 sales
      for (int i = 1; i <= 12; i++) {
        final pad = i.toString().padLeft(2, '0');
        await saleRepo.createSaleWithItems(
          sale: Sale(
            invoiceNumber: 'INV-0$pad',
            saleDate: '2026-09-${pad}T12:00:00.000',
            subtotal: 1500,
            total: 1500,
            paidAmount: 1500,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: bookId,
              quantity: 5,
              unitPrice: 300,
              total: 1500,
            ),
          ],
        );
      }

      final bloc = createBloc();
      bloc.add(const LoadDashboard());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having(
            (s) => s.metrics.recentSales.length,
            'recentSales.length == 10',
            equals(10),
          ).having(
            (s) => s.metrics.recentSales.first.invoiceNumber,
            'most recent sale invoice',
            equals('INV-012'),
          ).having(
            (s) => s.metrics.recentPurchases.length,
            'recentPurchases.length == 10',
            equals(10),
          ).having(
            (s) => s.metrics.recentPurchases.first.invoiceNumber,
            'most recent purchase invoice',
            equals('PUR-012'),
          ),
        ]),
      );

      await bloc.close();
    });

    test('8. RefreshDashboard reloads real-time metrics without resetting to Loading state', () async {
      final bloc = createBloc();

      bloc.add(const LoadDashboard());
      await pumpEventQueue();

      expect(bloc.state, isA<DashboardLoaded>());

      // Insert a new expense
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      await expenseRepo.create(Expense(
        title: 'Refresh Test Expense',
        amount: 1200,
        expenseDate: '${todayStr}T10:00:00.000',
      ));

      // Refresh
      bloc.add(const RefreshDashboard());
      await pumpEventQueue();

      expect(bloc.state, isA<DashboardLoaded>());
      final loaded = bloc.state as DashboardLoaded;
      expect(loaded.metrics.todayExpensesTotal, equals(1200.0));
      expect(loaded.metrics.todayExpensesCount, equals(1));

      await bloc.close();
    });
  });

  group('Part B: Desktop UI Widgets & Interaction Tests', () {
    testWidgets('9. DashboardPage renders PageHeader and Quick Actions Bar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = createBloc();
        final loadedFuture = bloc.stream.firstWhere((s) => s is DashboardLoaded);
        bloc.add(const LoadDashboard());
        await loadedFuture;
      });
      addTearDown(() => bloc.close());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: const DashboardPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify PageHeader
      expect(find.text('Bookstore Dashboard'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // Verify Quick Actions Bar
      expect(find.text('Quick Actions:'), findsOneWidget);
      expect(find.text('New Sale'), findsOneWidget);
      expect(find.text('New Purchase'), findsOneWidget);
      expect(find.text('Add Book'), findsOneWidget);
      expect(find.text('Add Customer'), findsOneWidget);
      expect(find.text('Add Supplier'), findsOneWidget);
    });

    testWidgets('10. Quick Actions invoke respective action callbacks', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = createBloc();
        final loadedFuture = bloc.stream.firstWhere((s) => s is DashboardLoaded);
        bloc.add(const LoadDashboard());
        await loadedFuture;
      });
      addTearDown(() => bloc.close());

      bool newSaleCalled = false;
      bool newPurchaseCalled = false;
      bool addBookCalled = false;
      bool addCustomerCalled = false;
      bool addSupplierCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: DashboardPage(
              onNewSale: () => newSaleCalled = true,
              onNewPurchase: () => newPurchaseCalled = true,
              onAddBook: () => addBookCalled = true,
              onAddCustomer: () => addCustomerCalled = true,
              onAddSupplier: () => addSupplierCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('New Sale'));
      await tester.pump();
      expect(newSaleCalled, isTrue);

      await tester.tap(find.text('New Purchase'));
      await tester.pump();
      expect(newPurchaseCalled, isTrue);

      await tester.tap(find.text('Add Book'));
      await tester.pump();
      expect(addBookCalled, isTrue);

      await tester.tap(find.text('Add Customer'));
      await tester.pump();
      expect(addCustomerCalled, isTrue);

      await tester.tap(find.text('Add Supplier'));
      await tester.pump();
      expect(addSupplierCalled, isTrue);
    });

    testWidgets('11. Refresh button dispatches RefreshDashboard', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = createBloc();
        final loadedFuture = bloc.stream.firstWhere((s) => s is DashboardLoaded);
        bloc.add(const LoadDashboard());
        await loadedFuture;
      });
      addTearDown(() => bloc.close());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: const DashboardPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap refresh
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(bloc.state, isA<DashboardLoaded>());
    });

    testWidgets("12. Renders all 5 Today's Performance cards and 6 Inventory/Balance cards", (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = createBloc();
        final loadedFuture = bloc.stream.firstWhere((s) => s is DashboardLoaded);
        bloc.add(const LoadDashboard());
        await loadedFuture;
      });
      addTearDown(() => bloc.close());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: const DashboardPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 5 Today's cards
      expect(find.text("Today's Sales"), findsOneWidget);
      expect(find.text("Today's Purchases"), findsOneWidget);
      expect(find.text("Customer Payments"), findsOneWidget);
      expect(find.text("Supplier Payments"), findsOneWidget);
      expect(find.text("Today's Expenses"), findsOneWidget);

      // 6 Inventory & Ledger Health cards
      expect(find.text('Total Books'), findsOneWidget);
      expect(find.text('Current Stock'), findsOneWidget);
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('Customer Receivables'), findsOneWidget);
      expect(find.text('Supplier Payables'), findsOneWidget);
    });

    testWidgets('13. Empty states display gracefully when lists are empty', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = createBloc();
        final loadedFuture = bloc.stream.firstWhere((s) => s is DashboardLoaded);
        bloc.add(const LoadDashboard());
        await loadedFuture;
      });
      addTearDown(() => bloc.close());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: const DashboardPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('All Stock Levels Healthy'), findsOneWidget);
      expect(find.text('No sales recorded yet'), findsOneWidget);
      expect(find.text('No purchase invoices recorded'), findsOneWidget);
    });

    testWidgets('14. Renders Recent 10 Sales, Recent 10 Purchases, and Low/Out-of-Stock alerts', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late DashboardBloc bloc;
      await tester.runAsync(() async {
        bloc = createBloc();

        // Prepare data
        final custId = await customerRepo.create(const Customer(name: 'Shaykh Zakariyya Bookshop'));
        final suppId = await supplierRepo.create(const Supplier(name: 'Kazi Publications'));

        // Low stock book and Out of stock book
        final book1Id = await bookRepo.create(const Book(
          name: 'Riyadh As-Saliheen',
          stockQuantity: 4,
          minimumStock: 10,
          purchasePrice: 600,
          wholesalePrice: 900,
        ));
        await bookRepo.create(const Book(
          name: 'Bulugh Al-Maram',
          stockQuantity: 0,
          minimumStock: 5,
          purchasePrice: 400,
          wholesalePrice: 700,
        ));

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);

        // Sale
        await saleRepo.createSaleWithItems(
          sale: Sale(
            customerId: custId,
            invoiceNumber: 'INV-1001',
            saleDate: '${todayStr}T10:30:00.000',
            subtotal: 900,
            total: 900,
            paidAmount: 900,
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(
              saleId: 0,
              bookId: book1Id,
              quantity: 1,
              unitPrice: 900,
              total: 900,
            ),
          ],
        );

        // Purchase
        await purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PUR-2001',
            purchaseDate: '${todayStr}T11:45:00.000',
            subtotal: 1200,
            total: 1200,
            paidAmount: 1200,
            paymentStatus: 'PAID',
          ),
          items: [
            PurchaseItem(
              purchaseId: 0,
              bookId: book1Id,
              quantity: 2,
              unitPrice: 600,
              total: 1200,
            ),
          ],
        );

        final loadedFuture = bloc.stream.firstWhere((s) => s is DashboardLoaded);
        bloc.add(const LoadDashboard());
        await loadedFuture;
      });
      addTearDown(() => bloc.close());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: const DashboardPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Recent Sales list item
      expect(find.text('INV-1001'), findsOneWidget);
      expect(find.textContaining('Shaykh Zakariyya Bookshop'), findsOneWidget);

      // Recent Purchases list item
      expect(find.text('PUR-2001'), findsOneWidget);
      expect(find.textContaining('Kazi Publications'), findsOneWidget);

      // Low stock & out-of-stock items
      expect(find.text('Riyadh As-Saliheen'), findsOneWidget);
      expect(find.text('Bulugh Al-Maram'), findsOneWidget);
      expect(find.text('LOW STOCK'), findsOneWidget);
      expect(find.text('OUT OF STOCK'), findsOneWidget);
    });
  });
}
