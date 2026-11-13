import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/errors/exceptions.dart';
import 'package:deen_book_depo/core/utils/phone_validator.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/customers/presentation/widgets/customer_form_dialog.dart';
import 'package:deen_book_depo/features/inventory/data/repositories/sqlite_stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/data/services/inventory_stock_service.dart';
import 'package:deen_book_depo/features/inventory/domain/constants/stock_movement_types.dart';
import 'package:deen_book_depo/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:deen_book_depo/features/inventory/domain/services/stock_service.dart';
import 'package:deen_book_depo/features/sales/data/repositories/sqlite_sale_repository.dart';
import 'package:deen_book_depo/features/sales/domain/repositories/sale_repository.dart';
import 'package:deen_book_depo/features/sales/presentation/widgets/bill_saved_dialog.dart';
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
    tempDir = await Directory.systemTemp.createTemp('wholesale_bill_test_');
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

  group('1. PhoneValidator Tests', () {
    test('Validates Pakistani and international phone formats', () {
      expect(PhoneValidator.isValid('0300-1234567'), isTrue);
      expect(PhoneValidator.isValid('03001234567'), isTrue);
      expect(PhoneValidator.isValid('+923001234567'), isTrue);
      expect(PhoneValidator.isValid('042-37234567'), isTrue);
      expect(PhoneValidator.isValid('(021) 34567890'), isTrue);
      expect(PhoneValidator.isValid('0333 9876543'), isTrue);
    });

    test('Rejects invalid phone numbers', () {
      expect(PhoneValidator.isValid(''), isFalse);
      expect(PhoneValidator.isValid('12345'), isFalse); // too short (<7)
      expect(PhoneValidator.isValid('abc-defghij'), isFalse);
      expect(PhoneValidator.isValid('0300-INVALID'), isFalse);
      expect(PhoneValidator.validate(null), isNotNull);
      expect(PhoneValidator.validate(''), isNotNull);
      expect(PhoneValidator.validate('0300-1234567'), isNull);
    });
  });

  group('2. Wholesale Customer Bill Creation & Permanent SQLite Snapshot', () {
    test('Saves wholesale bill with customer name and phone snapshot in SQLite', () async {
      // 1. Create a customer
      final custId = await customerRepo.create(
        const Customer(
          name: 'Al-Haramain Islamic Booksellers',
          phone: '0300-9876543',
          address: 'Urdu Bazar, Lahore',
          openingBalance: 0.0,
        ),
      );

      // 2. Create category and book
      final catId = await categoryRepo.create(const Category(name: 'Islamic History'));
      final bookId = await bookRepo.create(
        Book(
          categoryId: catId,
          name: 'Tareekh-e-Islam Complete Set',
          isbn: '978-969-500-1',
          purchasePrice: 1500.0,
          wholesalePrice: 2000.0,
          retailPrice: 2500.0,
          stockQuantity: 50,
          minimumStock: 5,
        ),
      );

      // 3. Create Wholesale Sale
      const invoiceNum = 'WHO-20261112-9999';
      final sale = Sale(
        customerId: custId,
        customerName: 'Al-Haramain Islamic Booksellers',
        customerPhone: '0300-9876543',
        invoiceNumber: invoiceNum,
        saleDate: '2026-11-12',
        subtotal: 20000.0,
        discount: 1000.0,
        total: 19000.0,
        paidAmount: 15000.0,
        remainingAmount: 4000.0,
        paymentStatus: 'PARTIAL',
        notes: '[WHOLESALE] Institutional bulk purchase',
      );

      final items = [
        const SaleItem(
          saleId: 0,
          bookId: 1,
          quantity: 10,
          unitPrice: 2000.0,
          discount: 0.0,
          total: 20000.0,
        ),
      ];

      final saleId = await saleRepo.createSaleWithItems(sale: sale, items: items);
      expect(saleId, greaterThan(0));

      // 4. Verify SQLite sales table row contains customer snapshot
      final rawSales = await dbHelper.query(
        DbConstants.tableSales,
        where: '${DbConstants.colId} = ?',
        whereArgs: [saleId],
      );
      expect(rawSales.isNotEmpty, isTrue);
      final rawSale = rawSales.first;
      expect(rawSale[DbConstants.colSaleCustomerName], equals('Al-Haramain Islamic Booksellers'));
      expect(rawSale[DbConstants.colSaleCustomerPhone], equals('0300-9876543'));
      expect(rawSale[DbConstants.colSaleInvoiceNumber], equals(invoiceNum));

      // 5. Verify stock deduction happened once atomically
      final updatedBook = await bookRepo.getById(bookId);
      expect(updatedBook?.stockQuantity, equals(40)); // 50 - 10

      final movements = await movementRepo.getByReference('SALE', saleId);
      expect(movements.length, equals(1));
      expect(movements.first.quantity, equals(10));
      expect(movements.first.movementType, equals(StockMovementTypes.sale));

      // 6. Verify searching by customer phone finds the invoice
      final searchResults = await saleRepo.search('0300-9876543');
      expect(searchResults.any((s) => s.id == saleId), isTrue);

      // 7. Verify historical snapshot remains even if customer directory changes
      await customerRepo.update(
        const Customer(
          id: 1,
          name: 'Renamed Customer',
          phone: '0311-0000000',
          openingBalance: 0.0,
        ),
      );
      final persistedSale = await saleRepo.getById(saleId);
      expect(persistedSale?.customerName, equals('Al-Haramain Islamic Booksellers'));
      expect(persistedSale?.customerPhone, equals('0300-9876543'));
    });

    test('Rejects wholesale bill if customer or phone is missing or invalid', () async {
      final catId = await categoryRepo.create(const Category(name: 'General'));
      final bookId = await bookRepo.create(
        Book(
          categoryId: catId,
          name: 'General Book',
          wholesalePrice: 100.0,
          retailPrice: 150.0,
          stockQuantity: 20,
          minimumStock: 2,
        ),
      );

      // 1. Missing customer on WHO- invoice
      expect(
        () => saleRepo.createSaleWithItems(
          sale: const Sale(
            customerId: null,
            invoiceNumber: 'WHO-20261112-0002',
            saleDate: '2026-11-12',
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 1, unitPrice: 100, total: 100),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );

      // 2. Invalid phone on WHO- invoice
      expect(
        () => saleRepo.createSaleWithItems(
          sale: const Sale(
            customerId: null,
            customerName: 'Test Customer',
            customerPhone: 'invalid-phone',
            invoiceNumber: 'WHO-20261112-0003',
            saleDate: '2026-11-12',
            paymentStatus: 'PAID',
          ),
          items: [
            SaleItem(saleId: 0, bookId: bookId, quantity: 1, unitPrice: 100, total: 100),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('3. Bill Content & PDF Generation (PrintingService)', () {
    test('Generates Wholesale 80mm thermal and A4 invoices with all required content', () async {
      const wholesaleSale = Sale(
        id: 10,
        customerId: 1,
        customerName: 'Dar-ul-Hikmah Book Agency',
        customerPhone: '0321-4567890',
        invoiceNumber: 'WHO-20261112-1001',
        saleDate: '2026-11-12',
        subtotal: 12000.0,
        discount: 1000.0,
        total: 11000.0,
        paidAmount: 8000.0,
        remainingAmount: 3000.0,
        paymentStatus: 'PARTIAL',
        createdAt: '2026-11-12T14:30:00.000',
        notes: '[WHOLESALE POS] Order #44',
      );

      final items = [
        const SaleItem(
          id: 1,
          saleId: 10,
          bookId: 101,
          bookName: 'Sahih Bukhari (Urdu Translation)',
          quantity: 6,
          unitPrice: 2000.0,
          discount: 0.0,
          total: 12000.0,
        ),
      ];

      // 1. Generate 80mm Thermal Receipt
      final thermalPdf = await PrintingService.generateSaleDocument(
        sale: wholesaleSale,
        items: items,
        customerName: wholesaleSale.customerName!,
        customerPhone: wholesaleSale.customerPhone,
        pageFormat: PdfPageFormat.roll80,
      );
      final thermalBytes = await thermalPdf.save();
      expect(thermalBytes.length, greaterThan(1000));

      // 2. Generate A4 Standard Sheet Invoice
      final a4Pdf = await PrintingService.generateSaleDocument(
        sale: wholesaleSale,
        items: items,
        customerName: wholesaleSale.customerName!,
        customerPhone: wholesaleSale.customerPhone,
        customerAddress: 'Nishtar Road, Rawalpindi',
        pageFormat: PdfPageFormat.a4,
      );
      final a4Bytes = await a4Pdf.save();
      expect(a4Bytes.length, greaterThan(1000));
    });
  });

  group('4. UI Dialogs & Interaction Tests', () {
    testWidgets('BillSavedDialog displays bill saved successfully, invoice number, and PRINT BILL button',
        (tester) async {
      const sampleSale = Sale(
        id: 55,
        invoiceNumber: 'WHO-20261112-5555',
        saleDate: '2026-11-12',
        customerName: 'Al-Huda Academy',
        customerPhone: '0300-5555555',
        subtotal: 5000.0,
        total: 5000.0,
        paidAmount: 5000.0,
        paymentStatus: 'PAID',
      );

      bool newBillTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillSavedDialog(
              sale: sampleSale,
              items: const [],
              customerName: sampleSale.customerName!,
              customerPhone: sampleSale.customerPhone,
              onNewBill: () {
                newBillTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BILL SAVED SUCCESSFULLY'), findsOneWidget);
      expect(find.text('#WHO-20261112-5555'), findsOneWidget);
      expect(find.text('PRINT BILL'), findsOneWidget);
      expect(find.text('New Bill / Done'), findsOneWidget);

      await tester.tap(find.text('New Bill / Done'));
      await tester.pumpAndSettle();
      expect(newBillTapped, isTrue);
    });

    testWidgets('CustomerFormDialog with requirePhone enforces phone validation',
        (tester) async {
      Customer? savedCustomer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerFormDialog(
              requirePhone: true,
              onSave: (cust) {
                savedCustomer = cust;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter customer name but leave phone empty
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        'Rawalpindi Book House',
      );
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Create Customer'));
      await tester.pumpAndSettle();

      // Error message for phone required
      expect(find.textContaining('Phone number is required for wholesale bills'), findsOneWidget);
      expect(savedCustomer, isNull);

      // Now enter valid phone number
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. 0300-1234567'),
        '0300-1234567',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Customer'));
      await tester.pumpAndSettle();

      expect(savedCustomer, isNotNull);
      expect(savedCustomer?.name, equals('Rawalpindi Book House'));
      expect(savedCustomer?.phone, equals('0300-1234567'));
    });
  });

  group('5. Sales History & Reprint Safety', () {
    test('Reprinting existing sale does not duplicate sale or decrease stock', () async {
      // 1. Create a customer and book
      final custId = await customerRepo.create(
        const Customer(
          name: 'Maktaba Quddusia',
          phone: '0300-7777777',
          openingBalance: 0.0,
        ),
      );

      final catId = await categoryRepo.create(const Category(name: 'Literature'));
      final bookId = await bookRepo.create(
        Book(
          categoryId: catId,
          name: 'Diwan-e-Ghalib (Wholesale Edition)',
          purchasePrice: 300.0,
          wholesalePrice: 450.0,
          retailPrice: 600.0,
          stockQuantity: 30,
          minimumStock: 5,
        ),
      );

      final saleId = await saleRepo.createSaleWithItems(
        sale: Sale(
          customerId: custId,
          customerName: 'Maktaba Quddusia',
          customerPhone: '0300-7777777',
          invoiceNumber: 'WHO-20261112-7777',
          saleDate: '2026-11-12',
          subtotal: 2250.0,
          total: 2250.0,
          paidAmount: 2250.0,
          paymentStatus: 'PAID',
        ),
        items: [
          const SaleItem(
            saleId: 0,
            bookId: 1,
            quantity: 5,
            unitPrice: 450.0,
            total: 2250.0,
          ),
        ],
      );

      // Verify stock was reduced from 30 to 25
      var book = await bookRepo.getById(bookId);
      expect(book?.stockQuantity, equals(25));

      // Simulate reprinting: Query sale and its items
      final sale = await saleRepo.getById(saleId);
      expect(sale, isNotNull);
      expect(sale?.customerName, equals('Maktaba Quddusia'));
      expect(sale?.customerPhone, equals('0300-7777777'));

      final items = await saleRepo.getItemsForSale(saleId);
      expect(items.length, equals(1));
      expect(items.first.quantity, equals(5));

      // Verify stock was NOT altered by reading or generating PDF for reprint
      final reprintPdf = await PrintingService.generateSaleDocument(
        sale: sale!,
        items: items,
        customerName: sale.customerName!,
        customerPhone: sale.customerPhone,
        pageFormat: PdfPageFormat.roll80,
      );
      final reprintBytes = await reprintPdf.save();
      expect(reprintBytes.isNotEmpty, isTrue);

      book = await bookRepo.getById(bookId);
      expect(book?.stockQuantity, equals(25)); // Unchanged

      final allSales = await saleRepo.getAll();
      expect(allSales.length, equals(1)); // No duplicate sales created
    });
  });
}

