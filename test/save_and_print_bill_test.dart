import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/data/services/inventory_stock_service.dart';
import 'package:deen_book_depo/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/domain/services/stock_service.dart';
import 'package:deen_book_depo/features/sales/data/repositories/sqlite_sale_repository.dart';
import 'package:deen_book_depo/features/sales/domain/repositories/sale_repository.dart';
import 'package:deen_book_depo/features/sales/presentation/bloc/sales_bloc.dart';
import 'package:deen_book_depo/features/sales/presentation/widgets/bill_saved_dialog.dart';
import 'package:deen_book_depo/features/sales/presentation/widgets/invoice_print_dialog.dart';
import 'package:deen_book_depo/services/printing_service.dart';
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
  late SaleRepository saleRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('save_print_bill_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}test.db';

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

  group('Invoice PDF Document Generation (PrintingService)', () {
    test('Generates 80mm thermal receipt PDF without errors', () async {
      const sale = Sale(
        id: 1,
        invoiceNumber: 'RET-2026-0001',
        saleDate: '2026-11-10T12:00:00.000',
        subtotal: 1500.0,
        discount: 100.0,
        total: 1400.0,
        paidAmount: 1400.0,
        remainingAmount: 0.0,
        paymentStatus: 'PAID',
        notes: 'RETAIL COUNTER SALE',
      );

      final items = [
        const SaleItem(
          id: 1,
          saleId: 1,
          bookId: 101,
          quantity: 2,
          unitPrice: 500.0,
          discount: 0.0,
          total: 1000.0,
          bookName: 'Riyad as-Salihin',
        ),
        const SaleItem(
          id: 2,
          saleId: 1,
          bookId: 102,
          quantity: 1,
          unitPrice: 500.0,
          discount: 100.0,
          total: 400.0,
          bookName: 'Fortress of the Muslim',
        ),
      ];

      final doc = await PrintingService.generateSaleDocument(
        sale: sale,
        items: items,
        customerName: 'Walk-in Cash Customer',
        customerPhone: null,
        bookTitles: {
          101: 'Riyad as-Salihin',
          102: 'Fortress of the Muslim',
        },
        pageFormat: PdfPageFormat.roll80,
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
    });

    test('Generates A4 Standard Sheet Invoice PDF with details', () async {
      const sale = Sale(
        id: 2,
        customerId: 42,
        invoiceNumber: 'WHL-2026-0002',
        saleDate: '2026-11-10T14:30:00.000',
        subtotal: 10000.0,
        discount: 1000.0,
        total: 9000.0,
        paidAmount: 5000.0,
        remainingAmount: 4000.0,
        paymentStatus: 'PARTIAL',
        notes: 'Wholesale Invoice - Term 15 days',
      );

      final items = [
        const SaleItem(
          id: 10,
          saleId: 2,
          bookId: 201,
          quantity: 20,
          unitPrice: 500.0,
          discount: 1000.0,
          total: 9000.0,
          bookName: 'Tafseer Ibn Kathir 10 Vols',
        ),
      ];

      final doc = await PrintingService.generateSaleDocument(
        sale: sale,
        items: items,
        customerName: 'Al-Madina Books & Stationers',
        customerPhone: '0321-7654321',
        customerAddress: 'Shop #12, Ghazni Street, Lahore',
        bookTitles: {
          201: 'Tafseer Ibn Kathir 10 Vols',
        },
        pageFormat: PdfPageFormat.a4,
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('Atomic Sale Saving & BLoC Bill Saved State', () {
    test('Saves bill atomically, decreases stock, and emits lastCreatedSale',
        () async {
      final catId = await categoryRepo.create(
        const Category(name: 'Islamic Studies'),
      );

      final bookId = await bookRepo.create(
        Book(
          categoryId: catId,
          name: 'Sahih Muslim Complete',
          isbn: '978-969-001',
          author: 'Imam Muslim',
          retailPrice: 800.0,
          wholesalePrice: 650.0,
          stockQuantity: 30,
        ),
      );

      final customerId = await customerRepo.create(
        const Customer(
          name: 'Iqbal Book House',
          phone: '0300-9876543',
        ),
      );

      final bloc = SalesBloc(
        saleRepository: saleRepo,
        customerRepository: customerRepo,
        bookRepository: bookRepo,
      );

      bloc.add(const LoadSales());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final saleToCreate = Sale(
        customerId: customerId,
        invoiceNumber: 'INV-TEST-001',
        saleDate: DateTime.now().toIso8601String(),
        subtotal: 1300.0,
        discount: 100.0,
        total: 1200.0,
        paidAmount: 1200.0,
        remainingAmount: 0.0,
        paymentStatus: 'PAID',
      );

      final saleItems = [
        SaleItem(
          saleId: 0,
          bookId: bookId,
          quantity: 2,
          unitPrice: 650.0,
          total: 1300.0,
        ),
      ];

      bloc.add(CreateSale(sale: saleToCreate, items: saleItems));
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(bloc.state, isA<SalesLoaded>());
      final state = bloc.state as SalesLoaded;

      // 1. Verify bill saved state
      expect(state.lastCreatedSale, isNotNull);
      expect(state.lastCreatedSale!.invoiceNumber, 'INV-TEST-001');
      expect(state.lastCreatedSaleItems, isNotNull);
      expect(state.lastCreatedSaleItems!.length, 1);
      expect(state.lastCreatedSaleItems!.first.quantity, 2);

      // 2. Verify stock atomically reduced from 30 to 28
      final updatedBook = await bookRepo.getById(bookId);
      expect(updatedBook, isNotNull);
      expect(updatedBook!.stockQuantity, 28);

      // 3. Verify stock movement recorded
      final movements = await movementRepo.getByBookId(bookId);
      expect(movements.isNotEmpty, isTrue);
      expect(movements.first.quantity, 2);
      expect(movements.first.movementType, 'SALE');

      // 4. Verify ClearLastCreatedSale clears lastCreatedSale without losing data
      bloc.add(const ClearLastCreatedSale());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final clearedState = bloc.state as SalesLoaded;
      expect(clearedState.lastCreatedSale, isNull);
      expect(clearedState.lastCreatedSaleItems, isNull);
      expect(clearedState.sales.length, 1);

      await bloc.close();
    });
  });

  group('Reprinting Bill Idempotency', () {
    test('Reprinting loads historical items without altering inventory or sales',
        () async {
      final catId = await categoryRepo.create(
        const Category(name: 'Quranic Sciences'),
      );

      final bookId = await bookRepo.create(
        Book(
          categoryId: catId,
          name: 'Tajweed Rules Explained',
          stockQuantity: 50,
          retailPrice: 300.0,
          wholesalePrice: 200.0,
        ),
      );

      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          invoiceNumber: 'INV-REPRINT-01',
          saleDate: DateTime.now().toIso8601String(),
          subtotal: 600.0,
          discount: 0.0,
          total: 600.0,
          paidAmount: 600.0,
          remainingAmount: 0.0,
          paymentStatus: 'PAID',
        ),
        items: [
          SaleItem(
            saleId: 0,
            bookId: bookId,
            quantity: 3,
            unitPrice: 200.0,
            total: 600.0,
          ),
        ],
      );

      // Stock should now be 47
      var bookAfterSale = await bookRepo.getById(bookId);
      expect(bookAfterSale!.stockQuantity, 47);

      // SIMULATE REPRINT: Read items for sale
      final historicalItems = await saleRepo.getItemsForSale(saleId);
      expect(historicalItems.length, 1);
      expect(historicalItems.first.quantity, 3);

      // Generating document for reprint
      final historicalSale = await saleRepo.getById(saleId);
      expect(historicalSale, isNotNull);

      final reprintDoc = await PrintingService.generateSaleDocument(
        sale: historicalSale!,
        items: historicalItems,
        customerName: 'Cash / Walk-in Customer',
        bookTitles: {bookId: 'Tajweed Rules Explained'},
        pageFormat: PdfPageFormat.roll80,
      );
      final pdfBytes = await reprintDoc.save();
      expect(pdfBytes, isNotEmpty);

      // Verify stock was NOT altered by reprinting
      final bookAfterReprint = await bookRepo.getById(bookId);
      expect(bookAfterReprint!.stockQuantity, 47);

      // Verify no duplicate sales created
      final allSales = await saleRepo.getAll();
      expect(allSales.length, 1);
    });
  });

  group('Bill Saved Dialog UI Verification', () {
    testWidgets('Renders Bill Saved screen with invoice number and Print button',
        (tester) async {
      bool newBillPressed = false;

      const testSale = Sale(
        id: 99,
        invoiceNumber: 'INV-UI-999',
        saleDate: '2026-11-10T15:00:00.000',
        subtotal: 2500.0,
        discount: 200.0,
        total: 2300.0,
        paidAmount: 2300.0,
        remainingAmount: 0.0,
        paymentStatus: 'PAID',
        notes: 'RETAIL',
      );

      final testItems = [
        const SaleItem(
          id: 1,
          saleId: 99,
          bookId: 5,
          quantity: 2,
          unitPrice: 1250.0,
          discount: 200.0,
          total: 2300.0,
          bookName: 'Ar-Raheeq Al-Makhtum',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillSavedDialog(
              sale: testSale,
              items: testItems,
              customerName: 'Walk-in Customer',
              onNewBill: () {
                newBillPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assertions
      expect(find.text('BILL SAVED SUCCESSFULLY'), findsOneWidget);
      expect(find.text('#INV-UI-999'), findsOneWidget); // invoice number badge
      expect(find.textContaining('INV-UI-999'), findsNWidgets(2)); // in header description and badge
      expect(find.text('PRINT BILL'), findsOneWidget);
      expect(find.text('New Bill / Done'), findsOneWidget);

      // Test New Bill button callback
      await tester.tap(find.text('New Bill / Done'));
      await tester.pumpAndSettle();
      expect(newBillPressed, isTrue);
    });

    testWidgets('InvoicePrintDialog renders format toggle and header',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testSale = Sale(
        id: 99,
        invoiceNumber: 'INV-UI-999',
        saleDate: '2026-11-10T15:00:00.000',
        subtotal: 2500.0,
        discount: 200.0,
        total: 2300.0,
        paidAmount: 2300.0,
        remainingAmount: 0.0,
        paymentStatus: 'PAID',
        notes: 'RETAIL',
      );

      final testItems = [
        const SaleItem(
          id: 1,
          saleId: 99,
          bookId: 5,
          quantity: 2,
          unitPrice: 1250.0,
          discount: 200.0,
          total: 2300.0,
          bookName: 'Ar-Raheeq Al-Makhtum',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoicePrintDialog(
              sale: testSale,
              items: testItems,
              customerName: 'Walk-in Customer',
            ),
          ),
        ),
      );

      // Pump initial frame
      await tester.pump();

      expect(find.text('Print Bill Preview'), findsOneWidget);
      expect(find.text('#INV-UI-999'), findsOneWidget);
      expect(find.text('80mm Thermal'), findsOneWidget);
      expect(find.text('A4 Sheet'), findsOneWidget);
      expect(find.text('Print Now'), findsOneWidget);
    });
  });
}
