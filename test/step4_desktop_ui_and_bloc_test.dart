import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/routing/app_destinations.dart';
import 'package:deen_book_depo/core/theme/theme.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/books/presentation/bloc/books_bloc.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/categories/presentation/bloc/category_bloc.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:deen_book_depo/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:deen_book_depo/features/purchases/data/repositories/sqlite_purchase_repository.dart';
import 'package:deen_book_depo/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:deen_book_depo/features/sales/data/repositories/sqlite_sale_repository.dart';
import 'package:deen_book_depo/features/sales/domain/repositories/sale_repository.dart';
import 'package:deen_book_depo/features/services.dart';
import 'package:deen_book_depo/features/suppliers/data/repositories/sqlite_supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'package:deen_book_depo/shared/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testDbPath;
  late DatabaseService dbService;
  late DatabaseHelper dbHelper;

  late BookRepository bookRepo;
  late CategoryRepository categoryRepo;
  late CustomerRepository customerRepo;
  late SupplierRepository supplierRepo;
  late PurchaseRepository purchaseRepo;
  late SaleRepository saleRepo;
  late CustomerLedgerService customerLedger;
  late SupplierLedgerService supplierLedger;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step4_bloc_ui_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}wholesale_test.db';

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: testDbPath);
    dbHelper = DatabaseHelper(dbService);

    categoryRepo = SqliteCategoryRepository(dbHelper);
    bookRepo = SqliteBookRepository(dbHelper);
    customerRepo = SqliteCustomerRepository(dbHelper);
    supplierRepo = SqliteSupplierRepository(dbHelper);
    final movementRepo = SqliteStockMovementRepository(dbHelper);

    final stockService = InventoryStockService(
      bookRepository: bookRepo,
      movementRepository: movementRepo,
      dbHelper: dbHelper,
    );

    customerLedger = CustomerLedgerServiceImpl(
      customerRepository: customerRepo,
      dbHelper: dbHelper,
    );

    supplierLedger = SupplierLedgerServiceImpl(
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

  group('1. NavigationBloc Tests', () {
    test('Initial state is dashboard and sidebar is expanded', () {
      final bloc = NavigationBloc();
      expect(bloc.state.activeDestinationId, equals(AppDestinations.dashboard));
      expect(bloc.state.isSidebarCollapsed, isFalse);
      expect(bloc.state.activeDestination.title, equals('Dashboard'));
      bloc.close();
    });

    test('NavigateTo updates active destination correctly', () async {
      final bloc = NavigationBloc();

      expectLater(
        bloc.stream.map((s) => s.activeDestinationId),
        emitsInOrder([AppDestinations.books, AppDestinations.sales]),
      );

      bloc.add(const NavigateTo(AppDestinations.books));
      await pumpEventQueue();
      bloc.add(const NavigateTo(AppDestinations.sales));
      await pumpEventQueue();

      expect(bloc.state.activeDestinationId, equals(AppDestinations.sales));
      expect(bloc.state.activeDestination.title, equals('Sales'));
      bloc.close();
    });

    test('ToggleSidebar toggles collapsed state', () async {
      final bloc = NavigationBloc();

      expectLater(
        bloc.stream.map((s) => s.isSidebarCollapsed),
        emitsInOrder([true, false]),
      );

      bloc.add(const ToggleSidebar());
      await pumpEventQueue();
      expect(bloc.state.isSidebarCollapsed, isTrue);

      bloc.add(const ToggleSidebar());
      await pumpEventQueue();
      expect(bloc.state.isSidebarCollapsed, isFalse);

      bloc.close();
    });
  });

  group('2. DashboardBloc Tests', () {
    test('Loads real-time metrics with zero-records database', () async {
      final bloc = DashboardBloc(
        bookRepository: bookRepo,
        saleRepository: saleRepo,
        purchaseRepository: purchaseRepo,
        customerRepository: customerRepo,
        supplierRepository: supplierRepo,
        customerLedgerService: customerLedger,
        supplierLedgerService: supplierLedger,
      );

      expect(bloc.state, isA<DashboardInitial>());

      bloc.add(const LoadDashboardMetrics());

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
            (s) => s.metrics.todaySalesTotal,
            'todaySalesTotal',
            equals(0.0),
          ).having(
            (s) => s.metrics.todayPurchasesTotal,
            'todayPurchasesTotal',
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
          ),
        ]),
      );

      bloc.close();
    });
  });

  group('3. Foundation BLoC Pattern Tests', () {
    test('BooksBloc loads books from repository', () async {
      final bloc = BooksBloc(bookRepository: bookRepo);
      expect(bloc.state, isA<BooksInitial>());

      bloc.add(const LoadBooks());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BooksLoading>(),
          isA<BooksLoaded>().having((s) => s.books, 'books', isEmpty),
        ]),
      );
      bloc.close();
    });

    test('CategoryBloc loads categories from repository', () async {
      final bloc = CategoryBloc(categoryRepository: categoryRepo);
      expect(bloc.state, isA<CategoryInitial>());

      bloc.add(const LoadCategories());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CategoryLoading>(),
          isA<CategoryLoaded>().having((s) => s.categories, 'categories', isEmpty),
        ]),
      );
      bloc.close();
    });

    test('CustomerBloc loads customers from repository', () async {
      final bloc = CustomerBloc(customerRepository: customerRepo);
      expect(bloc.state, isA<CustomerInitial>());

      bloc.add(const LoadCustomers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerLoaded>().having((s) => s.customers, 'customers', isEmpty),
        ]),
      );
      bloc.close();
    });

    test('SupplierBloc loads suppliers from repository', () async {
      final bloc = SupplierBloc(supplierRepository: supplierRepo);
      expect(bloc.state, isA<SupplierInitial>());

      bloc.add(const LoadSuppliers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoading>(),
          isA<SupplierLoaded>().having((s) => s.suppliers, 'suppliers', isEmpty),
        ]),
      );
      bloc.close();
    });
  });

  group('4. Reusable Desktop Widgets Tests', () {
    testWidgets('StatCard renders title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StatCard(
              title: 'Total Books',
              value: '1,420',
              subtitle: 'Active titles in catalog',
              icon: Icons.menu_book_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Total Books'), findsOneWidget);
      expect(find.text('1,420'), findsOneWidget);
      expect(find.text('Active titles in catalog'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('EmptyState displays title, message, and action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_rounded,
              title: 'No Books Found',
              message: 'Get started by adding your first wholesale book title.',
              actionLabel: 'Add Book',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Books Found'), findsOneWidget);
      expect(find.text('Get started by adding your first wholesale book title.'), findsOneWidget);
      expect(find.text('Add Book'), findsOneWidget);

      await tester.tap(find.text('Add Book'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('ConfirmationDialog shows cancel and confirm actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ConfirmationDialog.show(
                context,
                title: 'Delete Book?',
                message: 'Are you sure you want to delete this record?',
                isDestructive: true,
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Book?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this record?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Book?'), findsNothing);
    });
  });
}
