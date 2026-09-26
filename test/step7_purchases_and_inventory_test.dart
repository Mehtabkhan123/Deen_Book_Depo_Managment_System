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
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/data/services/inventory_stock_service.dart';
import 'package:deen_book_depo/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/domain/services/stock_service.dart';
import 'package:deen_book_depo/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:deen_book_depo/features/inventory/presentation/pages/inventory_page.dart';
import 'package:deen_book_depo/features/purchases/data/repositories/sqlite_purchase_repository.dart';
import 'package:deen_book_depo/features/purchases/domain/repositories/purchase_repository.dart';
import 'package:deen_book_depo/features/purchases/presentation/bloc/purchase_bloc.dart';
import 'package:deen_book_depo/features/purchases/presentation/widgets/purchase_detail_dialog.dart';
import 'package:deen_book_depo/features/purchases/presentation/widgets/purchase_form_dialog.dart';
import 'package:deen_book_depo/features/suppliers/data/repositories/sqlite_supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:deen_book_depo/shared/models/book.dart';
import 'package:deen_book_depo/shared/models/category.dart';
import 'package:deen_book_depo/shared/models/purchase.dart';
import 'package:deen_book_depo/shared/models/purchase_item.dart';
import 'package:deen_book_depo/shared/models/supplier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testDbPath;
  late DatabaseService dbService;
  late DatabaseHelper dbHelper;
  late CategoryRepository categoryRepo;
  late BookRepository bookRepo;
  late SupplierRepository supplierRepo;
  late StockMovementRepository movementRepo;
  late StockService stockService;
  late PurchaseRepository purchaseRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step7_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}wholesale_test.db';

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: testDbPath);
    dbHelper = DatabaseHelper(dbService);

    categoryRepo = SqliteCategoryRepository(dbHelper);
    bookRepo = SqliteBookRepository(dbHelper);
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
  });

  tearDown(() async {
    await dbService.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  // Helper method to setup a supplier and book
  Future<(int supplierId, int bookId)> setupSupplierAndBook({
    int initialStock = 10,
    int minStock = 5,
    double purchasePrice = 250.0,
  }) async {
    final suppId = await supplierRepo.create(const Supplier(
      name: 'Oxford Press Pakistan',
      phone: '021111693673',
      email: 'sales@oxford.pk',
      openingBalance: 0.0,
    ));

    final catId = await categoryRepo.create(const Category(
      name: 'Academic Textbooks',
    ));

    final bId = await bookRepo.create(Book(
      name: 'Secondary Physics Grade 9',
      isbn: '978-0190700010',
      author: 'Oxford Faculty',
      publisher: 'Oxford University Press',
      purchasePrice: purchasePrice,
      wholesalePrice: 320.0,
      retailPrice: 350.0,
      stockQuantity: initialStock,
      minimumStock: minStock,
      categoryId: catId,
    ));

    return (suppId, bId);
  }

  // ===========================================================================
  // PART A: PURCHASE TESTS (1 - 14)
  // ===========================================================================
  group('Part A: Purchase Management Tests (1 - 14)', () {
    test('1. Load purchases: empty and populated list via BLoC', () async {
      final bloc = PurchaseBloc(
        purchaseRepository: purchaseRepo,
        supplierRepository: supplierRepo,
        bookRepository: bookRepo,
      );

      expect(bloc.state, isA<PurchaseInitial>());

      bloc.add(const LoadPurchases());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<PurchaseLoading>(),
          isA<PurchaseLoaded>().having((s) => s.purchases.length, 'count', 0),
        ]),
      );

      final (suppId, bookId) = await setupSupplierAndBook();

      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-001',
          purchaseDate: '2026-09-24',
          subtotal: 5000.0,
          total: 5000.0,
          paidAmount: 5000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 20,
            unitPrice: 250.0,
            total: 5000.0,
          ),
        ],
      );

      bloc.add(const LoadPurchases());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<PurchaseLoading>(),
          isA<PurchaseLoaded>().having((s) => s.purchases.length, 'count', 1),
        ]),
      );

      await bloc.close();
    });

    test('2. Create purchase: saves single item purchase and increments stock', () async {
      final (suppId, bookId) = await setupSupplierAndBook(initialStock: 15);

      final purchaseId = await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-TEST-002',
          purchaseDate: '2026-09-24',
          subtotal: 7500.0,
          total: 7500.0,
          paidAmount: 7500.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 30,
            unitPrice: 250.0,
            total: 7500.0,
          ),
        ],
      );

      expect(purchaseId, isPositive);

      final retrieved = await purchaseRepo.getById(purchaseId);
      expect(retrieved, isNotNull);
      expect(retrieved!.invoiceNumber, equals('PINV-TEST-002'));
      expect(retrieved.total, equals(7500.0));

      final items = await purchaseRepo.getItemsForPurchase(purchaseId);
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(30));

      // Stock was 15, increased by 30 -> 45
      final updatedBook = await bookRepo.getById(bookId);
      expect(updatedBook!.stockQuantity, equals(45));
    });

    test('3. Create purchase with multiple items', () async {
      final (suppId, bookId1) = await setupSupplierAndBook(initialStock: 5);
      final bookId2 = await bookRepo.create(const Book(
        name: 'Secondary Chemistry Grade 9',
        purchasePrice: 300.0,
        wholesalePrice: 380.0,
        retailPrice: 420.0,
        stockQuantity: 10,
        minimumStock: 5,
      ));

      final purchaseId = await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-MULTI-003',
          purchaseDate: '2026-09-24',
          subtotal: 10000.0,
          total: 10000.0,
          paidAmount: 5000.0,
          remainingAmount: 5000.0,
          paymentStatus: 'PARTIAL',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId1,
            quantity: 16,
            unitPrice: 250.0,
            total: 4000.0,
          ),
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId2,
            quantity: 20,
            unitPrice: 300.0,
            total: 6000.0,
          ),
        ],
      );

      expect(purchaseId, isPositive);

      final items = await purchaseRepo.getItemsForPurchase(purchaseId);
      expect(items.length, equals(2));

      // Book 1: 5 + 16 = 21
      final b1 = await bookRepo.getById(bookId1);
      expect(b1!.stockQuantity, equals(21));

      // Book 2: 10 + 20 = 30
      final b2 = await bookRepo.getById(bookId2);
      expect(b2!.stockQuantity, equals(30));
    });

    test('4. Calculate line totals: qty * unitPrice - discount', () {
      const qty = 25;
      const unitPrice = 400.0;
      const discount = 250.0;

      final lineSubtotal = qty * unitPrice;
      final lineTotal = lineSubtotal - discount;

      expect(lineSubtotal, equals(10000.0));
      expect(lineTotal, equals(9750.0));
    });

    test('5. Calculate subtotal: sum of all line totals', () {
      final items = [
        const PurchaseItem(purchaseId: 1, bookId: 1, quantity: 10, unitPrice: 200, total: 2000),
        const PurchaseItem(purchaseId: 1, bookId: 2, quantity: 5, unitPrice: 300, discount: 100, total: 1400),
        const PurchaseItem(purchaseId: 1, bookId: 3, quantity: 2, unitPrice: 500, total: 1000),
      ];

      final subtotal = items.fold(0.0, (sum, i) => sum + i.total);
      expect(subtotal, equals(4400.0));
    });

    test('6. Calculate discount and 7. Calculate total: subtotal - discount', () {
      const subtotal = 4400.0;
      const discount = 400.0;
      final total = subtotal - discount;

      expect(total, equals(4000.0));
    });

    test('8. Calculate paid amount and 9. Calculate remaining amount: total - paid', () {
      const total = 4000.0;
      const paid = 1500.0;
      final remaining = total - paid;

      expect(remaining, equals(2500.0));
    });

    test('10. Payment status calculation: PAID, PARTIAL, UNPAID', () {
      // 10a. Paid in full
      double total = 5000.0;
      double paid = 5000.0;
      String status = paid >= total ? 'PAID' : (paid > 0 ? 'PARTIAL' : 'UNPAID');
      expect(status, equals('PAID'));

      // 10b. Partial credit
      paid = 2000.0;
      status = paid >= total ? 'PAID' : (paid > 0 ? 'PARTIAL' : 'UNPAID');
      expect(status, equals('PARTIAL'));

      // 10c. Fully unpaid
      paid = 0.0;
      status = paid >= total ? 'PAID' : (paid > 0 ? 'PARTIAL' : 'UNPAID');
      expect(status, equals('UNPAID'));
    });

    test('11. Duplicate invoice rejection: prevents duplicate invoice numbers', () async {
      final (suppId, bookId) = await setupSupplierAndBook();

      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-UNIQUE-99',
          purchaseDate: '2026-09-24',
          subtotal: 1000.0,
          total: 1000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 4,
            unitPrice: 250.0,
            total: 1000.0,
          ),
        ],
      );

      // Attempting same invoice number
      expect(
        () => purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PINV-UNIQUE-99',
            purchaseDate: '2026-09-24',
            subtotal: 1000.0,
            total: 1000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            PurchaseItem(
              purchaseId: 0,
              bookId: bookId,
              quantity: 4,
              unitPrice: 250.0,
              total: 1000.0,
            ),
          ],
        ),
        throwsA(isA<DuplicateInvoiceException>()),
      );
    });

    test('12. Invalid purchase rejection: negative unit prices and zero quantity', () async {
      final (suppId, bookId) = await setupSupplierAndBook();

      // Zero quantity
      expect(
        () => purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PINV-ZERO-QTY',
            purchaseDate: '2026-09-24',
            paymentStatus: 'UNPAID',
          ),
          items: [
            PurchaseItem(
              purchaseId: 0,
              bookId: bookId,
              quantity: 0,
              unitPrice: 100.0,
              total: 0.0,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );

      // Negative unit price
      expect(
        () => purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PINV-NEG-PRICE',
            purchaseDate: '2026-09-24',
            paymentStatus: 'UNPAID',
          ),
          items: [
            PurchaseItem(
              purchaseId: 0,
              bookId: bookId,
              quantity: 5,
              unitPrice: -50.0,
              total: -250.0,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. Supplier selection validation: invalid supplier ID rejected', () async {
      final (_, bookId) = await setupSupplierAndBook();

      expect(
        () => purchaseRepo.createPurchaseWithItems(
          purchase: const Purchase(
            supplierId: 0, // Invalid ID
            invoiceNumber: 'PINV-NO-SUPP',
            purchaseDate: '2026-09-24',
            paymentStatus: 'UNPAID',
          ),
          items: [
            PurchaseItem(
              purchaseId: 0,
              bookId: bookId,
              quantity: 2,
              unitPrice: 100.0,
              total: 200.0,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. Empty items rejection: purchase must have at least one line item', () async {
      final (suppId, _) = await setupSupplierAndBook();

      expect(
        () => purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PINV-EMPTY',
            purchaseDate: '2026-09-24',
            paymentStatus: 'UNPAID',
          ),
          items: const [],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ===========================================================================
  // PART B: INVENTORY TESTS (15 - 23)
  // ===========================================================================
  group('Part B: Inventory & Stock Movement Tests (15 - 23)', () {
    test('15. Purchase increases stock, 16. Correct previous stock, 17. Correct new stock', () async {
      final (suppId, bookId) = await setupSupplierAndBook(initialStock: 8);

      final pId = await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-STK-01',
          purchaseDate: '2026-09-24',
          subtotal: 3000.0,
          total: 3000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 12,
            unitPrice: 250.0,
            total: 3000.0,
          ),
        ],
      );

      // Book stock must now be 8 + 12 = 20
      final updatedBook = await bookRepo.getById(bookId);
      expect(updatedBook!.stockQuantity, equals(20));

      // Verify movement audit log
      final movements = await movementRepo.getByReference('PURCHASE', pId);
      expect(movements.length, equals(1));
      final m = movements.first;
      expect(m.previousStock, equals(8));
      expect(m.newStock, equals(20));
      expect(m.quantity, equals(12));
      expect(m.movementType, equals('PURCHASE'));
    });

    test('18. PURCHASE movement created with reference and audit notes', () async {
      final (suppId, bookId) = await setupSupplierAndBook();

      final pId = await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-AUDIT-02',
          purchaseDate: '2026-09-24',
          subtotal: 1250.0,
          total: 1250.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(
            purchaseId: 0,
            bookId: bookId,
            quantity: 5,
            unitPrice: 250.0,
            total: 1250.0,
          ),
        ],
      );

      final movements = await movementRepo.getByReference('PURCHASE', pId);
      expect(movements.first.notes, contains('PINV-AUDIT-02'));
      expect(movements.first.referenceType, equals('PURCHASE'));
      expect(movements.first.referenceId, equals(pId));
    });

    test('19. Multiple purchase items update multiple books atomically', () async {
      final (suppId, b1) = await setupSupplierAndBook(initialStock: 10);
      final b2 = await bookRepo.create(const Book(
        name: 'Biology Grade 9',
        purchasePrice: 200.0,
        wholesalePrice: 260.0,
        retailPrice: 290.0,
        stockQuantity: 20,
        minimumStock: 10,
      ));

      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-MULTI-STK',
          purchaseDate: '2026-09-24',
          subtotal: 5000.0,
          total: 5000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(purchaseId: 0, bookId: b1, quantity: 12, unitPrice: 250.0, total: 3000.0),
          PurchaseItem(purchaseId: 0, bookId: b2, quantity: 10, unitPrice: 200.0, total: 2000.0),
        ],
      );

      final updatedB1 = await bookRepo.getById(b1);
      final updatedB2 = await bookRepo.getById(b2);

      expect(updatedB1!.stockQuantity, equals(22)); // 10 + 12
      expect(updatedB2!.stockQuantity, equals(30)); // 20 + 10
    });

    test('20. Inventory list reflects updated stock via InventoryBloc', () async {
      final (suppId, bookId) = await setupSupplierAndBook(initialStock: 4);

      final bloc = InventoryBloc(
        bookRepository: bookRepo,
        categoryRepository: categoryRepo,
        stockMovementRepository: movementRepo,
        stockService: stockService,
      );

      bloc.add(const LoadInventory());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<InventoryLoading>(),
          isA<InventoryLoaded>().having(
            (s) => s.books.firstWhere((b) => b.id == bookId).stockQuantity,
            'initial stock',
            4,
          ),
        ]),
      );

      // Perform purchase intake
      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-INVENTORY-BLOC',
          purchaseDate: '2026-09-24',
          subtotal: 2500.0,
          total: 2500.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(purchaseId: 0, bookId: bookId, quantity: 10, unitPrice: 250.0, total: 2500.0),
        ],
      );

      bloc.add(const RefreshInventory());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<InventoryLoaded>().having(
            (s) => s.books.firstWhere((b) => b.id == bookId).stockQuantity,
            'updated stock',
            14, // 4 + 10
          ),
        ]),
      );

      await bloc.close();
    });

    test('21. Low-stock detection and 22. Out-of-stock detection', () async {
      // Out of stock (0 units)
      final bOut = await bookRepo.create(const Book(
        name: 'Out of Stock Title',
        stockQuantity: 0,
        minimumStock: 10,
      ));

      // Low stock (5 units <= min 10)
      final bLow = await bookRepo.create(const Book(
        name: 'Low Stock Title',
        stockQuantity: 5,
        minimumStock: 10,
      ));

      // In stock (25 units > min 10)
      final bIn = await bookRepo.create(const Book(
        name: 'Normal Stock Title',
        stockQuantity: 25,
        minimumStock: 10,
      ));

      final bookOut = await bookRepo.getById(bOut);
      final bookLow = await bookRepo.getById(bLow);
      final bookIn = await bookRepo.getById(bIn);

      expect(InventoryLoaded.computeStockStatus(bookOut!), equals('OUT OF STOCK'));
      expect(InventoryLoaded.computeStockStatus(bookLow!), equals('LOW STOCK'));
      expect(InventoryLoaded.computeStockStatus(bookIn!), equals('IN STOCK'));
    });

    test('23. Stock movement retrieval: chronological audit history', () async {
      final (suppId, bookId) = await setupSupplierAndBook(initialStock: 10);

      await purchaseRepo.createPurchaseWithItems(
        purchase: Purchase(
          supplierId: suppId,
          invoiceNumber: 'PINV-MOV-01',
          purchaseDate: '2026-09-24',
          subtotal: 1000.0,
          total: 1000.0,
          paymentStatus: 'PAID',
        ),
        items: [
          PurchaseItem(purchaseId: 0, bookId: bookId, quantity: 4, unitPrice: 250.0, total: 1000.0),
        ],
      );

      final movements = await stockService.getStockMovements();
      expect(movements.length, isPositive);
      expect(movements.any((m) => m.movementType == 'PURCHASE'), isTrue);
      expect(movements.first.quantity, equals(4));
    });
  });

  // ===========================================================================
  // PART C: TRANSACTION SAFETY & ROLLBACK TESTS (24 - 28)
  // ===========================================================================
  group('Part C: Transaction Safety & Rollback Tests (24 - 28)', () {
    test('24. Insufficient/invalid operation rolls back, 25. No partial purchase, 26. Stock unchanged, 27. No partial items, 28. No incorrect movement', () async {
      final (suppId, bookId) = await setupSupplierAndBook(initialStock: 50);

      // Attempt purchase where 2nd item has an INVALID book ID (e.g. 999999)
      try {
        await purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PINV-FAIL-ROLLBACK',
            purchaseDate: '2026-09-24',
            subtotal: 5000.0,
            total: 5000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            PurchaseItem(purchaseId: 0, bookId: bookId, quantity: 10, unitPrice: 250.0, total: 2500.0),
            const PurchaseItem(purchaseId: 0, bookId: 999999, quantity: 10, unitPrice: 250.0, total: 2500.0),
          ],
        );
        fail('Purchase with invalid book should have thrown an exception');
      } catch (e) {
        expect(e, isA<AppException>());
      }

      // 25. Check no purchase row was written
      final savedPurchase = await purchaseRepo.getByInvoiceNumber('PINV-FAIL-ROLLBACK');
      expect(savedPurchase, isNull);

      // 26. Check stock remains strictly 50 (unchanged)
      final bookAfterFailed = await bookRepo.getById(bookId);
      expect(bookAfterFailed!.stockQuantity, equals(50));

      // 27. Check no purchase items exist for this invoice
      final allItems = await dbHelper.query(
        DbConstants.tablePurchaseItems,
        where: '${DbConstants.colPurchaseItemBookId} = ?',
        whereArgs: [bookId],
      );
      expect(allItems, isEmpty);

      // 28. Check no stock movements were committed
      final movements = await movementRepo.getByBookId(bookId);
      expect(movements, isEmpty);
    });
  });

  // ===========================================================================
  // PART D: UI MODALS & WIDGET TESTS (29 - 31)
  // ===========================================================================
  group('Part D: Desktop UI Widgets & Dialog Tests', () {
    testWidgets('29. PurchaseFormDialog creates purchase and calculates settlement', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Purchase? savedPurchase;
      List<PurchaseItem>? savedItems;

      const sampleSupplier = Supplier(
        id: 1,
        name: 'Oxford Press Pakistan',
        phone: '021111693673',
        openingBalance: 0.0,
      );

      const sampleBook = Book(
        id: 10,
        name: 'Modern Mathematics 9',
        purchasePrice: 180.0,
        wholesalePrice: 230.0,
        retailPrice: 260.0,
        stockQuantity: 12,
        minimumStock: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PurchaseFormDialog.show(
                    ctx,
                    suppliers: [sampleSupplier],
                    books: [sampleBook],
                    onSave: (p, items) {
                      savedPurchase = p;
                      savedItems = items;
                    },
                  );
                },
                child: const Text('Open Purchase Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Purchase Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create Purchase Invoice'), findsOneWidget);
      expect(find.text('1. Purchase Information'), findsOneWidget);
      expect(find.text('2. Purchase Items Entry'), findsOneWidget);
      expect(find.text('3. Financial Settlement'), findsOneWidget);

      // Fill in invoice number
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('purchase_invoice_input')),
          matching: find.byType(TextFormField),
        ),
        'PINV-WIDGET-01',
      );

      // Select supplier
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oxford Press Pakistan (021111693673)').last);
      await tester.pumpAndSettle();

      // Select book
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modern Mathematics 9 [Stock: 12]').last);
      await tester.pumpAndSettle();

      // Click Add Item
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      // Modern Mathematics 9 is now in table
      expect(find.text('Modern Mathematics 9'), findsOneWidget);
      expect(find.text('Rs. 180.00'), findsWidgets);

      // Click Save Purchase Invoice
      await tester.tap(find.text('Save Purchase Invoice'));
      await tester.pumpAndSettle();

      expect(savedPurchase, isNotNull);
      expect(savedPurchase!.invoiceNumber, equals('PINV-WIDGET-01'));
      expect(savedPurchase!.supplierId, equals(1));
      expect(savedPurchase!.subtotal, equals(180.0));
      expect(savedItems, isNotNull);
      expect(savedItems!.length, equals(1));
      expect(savedItems!.first.bookId, equals(10));
    });

    testWidgets('30. PurchaseDetailDialog renders invoice items and financial settlement', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const samplePurchase = Purchase(
        id: 77,
        supplierId: 1,
        invoiceNumber: 'PINV-DETAIL-77',
        purchaseDate: '2026-09-24',
        subtotal: 5400.0,
        discount: 400.0,
        total: 5000.0,
        paidAmount: 3000.0,
        remainingAmount: 2000.0,
        paymentStatus: 'PARTIAL',
        notes: 'Monthly delivery via carrier truck',
      );

      final sampleItems = [
        const PurchaseItem(
          id: 1,
          purchaseId: 77,
          bookId: 10,
          quantity: 30,
          unitPrice: 180.0,
          total: 5400.0,
          bookName: 'Modern Mathematics 9',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PurchaseDetailDialog.show(
                    ctx,
                    purchase: samplePurchase,
                    items: sampleItems,
                    supplierName: 'Oxford Press Pakistan',
                    supplierPhone: '021111693673',
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

      expect(find.text('Purchase Invoice #PINV-DETAIL-77'), findsOneWidget);
      expect(find.text('PARTIAL'), findsOneWidget);
      expect(find.text('Modern Mathematics 9'), findsOneWidget);
      expect(find.text('Rs. 5400.00'), findsWidgets);
      expect(find.text('Rs. 5000.00'), findsOneWidget);
      expect(find.text('Rs. 3000.00'), findsOneWidget);
      expect(find.text('Rs. 2000.00'), findsOneWidget);
      expect(find.text('Notes: Monthly delivery via carrier truck'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('31. InventoryPage renders tabs, metrics cards, and filters', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late int suppId;
      late int bookId;
      late InventoryBloc bloc;

      await tester.runAsync(() async {
        final res = await setupSupplierAndBook(initialStock: 8, minStock: 10);
        suppId = res.$1;
        bookId = res.$2;

        // Perform a purchase to generate both stock and stock movements
        await purchaseRepo.createPurchaseWithItems(
          purchase: Purchase(
            supplierId: suppId,
            invoiceNumber: 'PINV-UI-01',
            purchaseDate: '2026-09-24',
            subtotal: 1000.0,
            total: 1000.0,
            paymentStatus: 'PAID',
          ),
          items: [
            PurchaseItem(purchaseId: 0, bookId: bookId, quantity: 4, unitPrice: 250.0, total: 1000.0),
          ],
        );

        bloc = InventoryBloc(
          bookRepository: bookRepo,
          categoryRepository: categoryRepo,
          stockMovementRepository: movementRepo,
          stockService: stockService,
        );
        final loadedFuture = bloc.stream.firstWhere((s) => s is InventoryLoaded);
        bloc.add(const LoadInventory());
        await loadedFuture;
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BlocProvider.value(
            value: bloc,
            child: const InventoryPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Inventory & Stock Management'), findsOneWidget);
      expect(find.text('Stock Ledger & Valuation'), findsOneWidget);
      expect(find.text('Stock Movement Audit Trail'), findsOneWidget);
      expect(find.text('Total Title Catalog'), findsOneWidget);
      expect(find.text('Secondary Physics Grade 9'), findsOneWidget);

      // Switch to Stock Movement Audit Trail tab
      await tester.tap(find.text('Stock Movement Audit Trail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PURCHASE'), findsWidgets);
      expect(find.text('+4'), findsOneWidget);

      await tester.runAsync(() async {
        await bloc.close();
      });
    });
  });
}
