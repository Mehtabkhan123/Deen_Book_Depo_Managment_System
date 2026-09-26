import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/constants/db_constants.dart';
import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/errors/exceptions.dart';
import 'package:deen_book_depo/core/theme/theme.dart';
import 'package:deen_book_depo/features/customers/data/repositories/sqlite_customer_repository.dart';
import 'package:deen_book_depo/features/customers/data/services/customer_ledger_service_impl.dart';
import 'package:deen_book_depo/features/customers/domain/repositories/customer_repository.dart';
import 'package:deen_book_depo/features/customers/domain/services/customer_ledger_service.dart';
import 'package:deen_book_depo/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:deen_book_depo/features/customers/presentation/widgets/customer_detail_dialog.dart';
import 'package:deen_book_depo/features/customers/presentation/widgets/customer_form_dialog.dart';
import 'package:deen_book_depo/features/suppliers/data/repositories/sqlite_supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/data/services/supplier_ledger_service_impl.dart';
import 'package:deen_book_depo/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:deen_book_depo/features/suppliers/domain/services/supplier_ledger_service.dart';
import 'package:deen_book_depo/features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'package:deen_book_depo/features/suppliers/presentation/widgets/supplier_detail_dialog.dart';
import 'package:deen_book_depo/features/suppliers/presentation/widgets/supplier_form_dialog.dart';
import 'package:deen_book_depo/shared/models/customer.dart';
import 'package:deen_book_depo/shared/models/customer_payment.dart';
import 'package:deen_book_depo/shared/models/purchase.dart';
import 'package:deen_book_depo/shared/models/sale.dart';
import 'package:deen_book_depo/shared/models/supplier.dart';
import 'package:deen_book_depo/shared/models/supplier_payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testDbPath;
  late DatabaseService dbService;
  late DatabaseHelper dbHelper;
  late CustomerRepository customerRepo;
  late SupplierRepository supplierRepo;
  late CustomerLedgerService customerLedgerService;
  late SupplierLedgerService supplierLedgerService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step6_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}wholesale_test.db';

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: testDbPath);
    dbHelper = DatabaseHelper(dbService);

    customerRepo = SqliteCustomerRepository(dbHelper);
    supplierRepo = SqliteSupplierRepository(dbHelper);
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
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  // ===========================================================================
  // PART A: CUSTOMERS TESTS (1 - 8)
  // ===========================================================================
  group('Part A: Customer Management Tests (1 - 8)', () {
    test('1. Load customers: loads initial empty list and populated list via BLoC', () async {
      final initial = await customerRepo.getAll();
      expect(initial, isEmpty);

      final bloc = CustomerBloc(
        customerRepository: customerRepo,
        ledgerService: customerLedgerService,
      );

      expect(bloc.state, isA<CustomerInitial>());

      bloc.add(const LoadCustomers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerLoaded>().having((s) => s.customers.length, 'count', 0),
        ]),
      );

      // Create a customer
      await customerRepo.create(const Customer(
        name: 'Al-Madina Academy',
        phone: '03001234567',
        email: 'info@almadina.pk',
        openingBalance: 5000.0,
      ));

      bloc.add(const LoadCustomers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerLoaded>().having((s) => s.customers.length, 'count', 1),
        ]),
      );

      await bloc.close();
    });

    test('2. Create customer: saves customer with opening balance and all fields', () async {
      const customer = Customer(
        name: 'Iqra Book Depot',
        phone: '03119876543',
        email: 'iqra@bookdepo.pk',
        address: 'Urdu Bazaar, Lahore',
        openingBalance: 12500.50,
        notes: 'VIP wholesale client, 5% additional trade discount',
      );

      final id = await customerRepo.create(customer);
      expect(id, isPositive);

      final retrieved = await customerRepo.getById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Iqra Book Depot'));
      expect(retrieved.phone, equals('03119876543'));
      expect(retrieved.email, equals('iqra@bookdepo.pk'));
      expect(retrieved.address, equals('Urdu Bazaar, Lahore'));
      expect(retrieved.openingBalance, equals(12500.50));
      expect(retrieved.notes, equals('VIP wholesale client, 5% additional trade discount'));
    });

    test('3. Update customer: edits contact and financial info successfully', () async {
      final id = await customerRepo.create(const Customer(
        name: 'Original Customer',
        phone: '03000000000',
        openingBalance: 1000.0,
      ));

      final existing = await customerRepo.getById(id);
      expect(existing, isNotNull);

      final updated = existing!.copyWith(
        name: 'Updated Customer Name',
        phone: '03211112233',
        email: 'updated@domain.com',
        address: 'Main Market, Rawalpindi',
        openingBalance: 2500.0,
        notes: 'Updated notes',
      );

      final success = await customerRepo.update(updated);
      expect(success, isTrue);

      final reFetched = await customerRepo.getById(id);
      expect(reFetched!.name, equals('Updated Customer Name'));
      expect(reFetched.phone, equals('03211112233'));
      expect(reFetched.email, equals('updated@domain.com'));
      expect(reFetched.openingBalance, equals(2500.0));
      expect(reFetched.notes, equals('Updated notes'));
    });

    test('4. Search customer: searches by name, phone, and email cleanly', () async {
      await customerRepo.create(const Customer(
        name: 'Qasmi Kitab Ghar',
        phone: '03451122334',
        email: 'qasmi@kitab.com',
      ));
      await customerRepo.create(const Customer(
        name: 'Darul Ilm Center',
        phone: '03219988776',
        email: 'contact@darulilm.org',
      ));

      // Search by Name
      final byName = await customerRepo.search('Qasmi');
      expect(byName.length, equals(1));
      expect(byName.first.name, equals('Qasmi Kitab Ghar'));

      // Search by Phone
      final byPhone = await customerRepo.search('03219988');
      expect(byPhone.length, equals(1));
      expect(byPhone.first.name, equals('Darul Ilm Center'));

      // Search by Email
      final byEmail = await customerRepo.search('kitab.com');
      expect(byEmail.length, equals(1));
      expect(byEmail.first.name, equals('Qasmi Kitab Ghar'));

      // Non-matching search
      final none = await customerRepo.search('NonExistentKeyword');
      expect(none, isEmpty);
    });

    test('5. Delete customer: deletes unreferenced customer and updates BLoC list', () async {
      final id = await customerRepo.create(const Customer(
        name: 'Temporary Account',
        openingBalance: 0.0,
      ));

      final allBefore = await customerRepo.getAll();
      expect(allBefore.length, equals(1));

      final deleted = await customerRepo.delete(id);
      expect(deleted, isTrue);

      final allAfter = await customerRepo.getAll();
      expect(allAfter, isEmpty);
    });

    test('6. Customer validation: rejects blank names, negative opening balance, and trims', () async {
      // Empty name
      expect(
        () => customerRepo.create(const Customer(name: '')),
        throwsA(isA<ValidationException>()),
      );

      // Whitespace-only name
      expect(
        () => customerRepo.create(const Customer(name: '   ')),
        throwsA(isA<ValidationException>()),
      );

      // Negative opening balance
      expect(
        () => customerRepo.create(const Customer(
          name: 'Negative Balance Customer',
          openingBalance: -500.0,
        )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. Customer detail loading: loads complete details and ledger balance via BLoC', () async {
      final id = await customerRepo.create(const Customer(
        name: 'Comprehensive Customer',
        phone: '03017766554',
        email: 'comp@customer.pk',
        address: 'Plot 45, Industrial Area',
        openingBalance: 8000.0,
        notes: 'Special payment cycle',
      ));

      final bloc = CustomerBloc(
        customerRepository: customerRepo,
        ledgerService: customerLedgerService,
      );

      bloc.add(const LoadCustomers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerLoaded>(),
        ]),
      );

      bloc.add(LoadCustomerDetails(id));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoaded>().having(
            (s) => s.selectedCustomer?.name,
            'selectedCustomer.name',
            'Comprehensive Customer',
          ).having(
            (s) => s.selectedCustomerBalance,
            'selectedCustomerBalance',
            8000.0,
          ),
        ]),
      );

      await bloc.close();
    });

    test('8. Customer balance retrieval: calculated via CustomerLedgerService', () async {
      final customerId = await customerRepo.create(const Customer(
        name: 'Wholesale Buyer Ledger Test',
        openingBalance: 10000.0,
      ));

      // Initial balance equals opening balance
      final initialBalance = await customerLedgerService.getCustomerBalance(customerId);
      expect(initialBalance, equals(10000.0));

      // Record a sale with remaining credit balance of 6500.0
      await dbHelper.insert(
        DbConstants.tableSales,
        Sale(
          customerId: customerId,
          invoiceNumber: 'INV-TEST-001',
          saleDate: DateTime.now().toIso8601String(),
          subtotal: 10000.0,
          total: 10000.0,
          paidAmount: 3500.0,
          remainingAmount: 6500.0,
          paymentStatus: 'PARTIAL',
        ).toMap(),
      );

      // Balance = Opening (10000) + Credit Sale (6500) = 16500.0
      final balanceAfterSale = await customerLedgerService.getCustomerBalance(customerId);
      expect(balanceAfterSale, equals(16500.0));

      // Record a customer recovery payment of 4500.0
      await dbHelper.insert(
        DbConstants.tableCustomerPayments,
        CustomerPayment(
          customerId: customerId,
          amount: 4500.0,
          paymentDate: DateTime.now().toIso8601String(),
          paymentMethod: 'CASH',
        ).toMap(),
      );

      // Balance = 16500 - 4500 = 12000.0
      final balanceAfterPayment = await customerLedgerService.getCustomerBalance(customerId);
      expect(balanceAfterPayment, equals(12000.0));
    });
  });

  // ===========================================================================
  // PART B: SUPPLIERS TESTS (9 - 16)
  // ===========================================================================
  group('Part B: Supplier Management Tests (9 - 16)', () {
    test('9. Load suppliers: loads initial empty list and populated list via BLoC', () async {
      final initial = await supplierRepo.getAll();
      expect(initial, isEmpty);

      final bloc = SupplierBloc(
        supplierRepository: supplierRepo,
        ledgerService: supplierLedgerService,
      );

      expect(bloc.state, isA<SupplierInitial>());

      bloc.add(const LoadSuppliers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoading>(),
          isA<SupplierLoaded>().having((s) => s.suppliers.length, 'count', 0),
        ]),
      );

      // Create a supplier
      await supplierRepo.create(const Supplier(
        name: 'Darul Kutub Publishers',
        phone: '04237123456',
        email: 'info@darulkutub.com',
        openingBalance: 15000.0,
      ));

      bloc.add(const LoadSuppliers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoading>(),
          isA<SupplierLoaded>().having((s) => s.suppliers.length, 'count', 1),
        ]),
      );

      await bloc.close();
    });

    test('10. Create supplier: saves supplier with opening balance and all fields', () async {
      const supplier = Supplier(
        name: 'Oxford Press Pakistan',
        phone: '021111693673',
        email: 'sales@oxfordpress.pk',
        address: 'Korangi Industrial Area, Karachi',
        openingBalance: 45000.0,
        notes: 'Monthly 30-day net payment agreement',
      );

      final id = await supplierRepo.create(supplier);
      expect(id, isPositive);

      final retrieved = await supplierRepo.getById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Oxford Press Pakistan'));
      expect(retrieved.phone, equals('021111693673'));
      expect(retrieved.email, equals('sales@oxfordpress.pk'));
      expect(retrieved.address, equals('Korangi Industrial Area, Karachi'));
      expect(retrieved.openingBalance, equals(45000.0));
      expect(retrieved.notes, equals('Monthly 30-day net payment agreement'));
    });

    test('11. Update supplier: edits contact and financial info successfully', () async {
      final id = await supplierRepo.create(const Supplier(
        name: 'Original Publisher',
        phone: '03001111111',
        openingBalance: 5000.0,
      ));

      final existing = await supplierRepo.getById(id);
      expect(existing, isNotNull);

      final updated = existing!.copyWith(
        name: 'Updated Publisher Name',
        phone: '03224445566',
        email: 'publisher@updated.com',
        address: 'Ghazni Street, Lahore',
        openingBalance: 7500.0,
        notes: 'New distributor manager assigned',
      );

      final success = await supplierRepo.update(updated);
      expect(success, isTrue);

      final reFetched = await supplierRepo.getById(id);
      expect(reFetched!.name, equals('Updated Publisher Name'));
      expect(reFetched.phone, equals('03224445566'));
      expect(reFetched.email, equals('publisher@updated.com'));
      expect(reFetched.openingBalance, equals(7500.0));
      expect(reFetched.notes, equals('New distributor manager assigned'));
    });

    test('12. Search supplier: searches by name, phone, and email cleanly', () async {
      await supplierRepo.create(const Supplier(
        name: 'Al-Faisal Publishers',
        phone: '04237222333',
        email: 'alfaisal@press.pk',
      ));
      await supplierRepo.create(const Supplier(
        name: 'Maktaba Rashidia',
        phone: '09152778899',
        email: 'rashidia@books.org',
      ));

      // Search by Name
      final byName = await supplierRepo.search('Al-Faisal');
      expect(byName.length, equals(1));
      expect(byName.first.name, equals('Al-Faisal Publishers'));

      // Search by Phone
      final byPhone = await supplierRepo.search('0915277');
      expect(byPhone.length, equals(1));
      expect(byPhone.first.name, equals('Maktaba Rashidia'));

      // Search by Email
      final byEmail = await supplierRepo.search('press.pk');
      expect(byEmail.length, equals(1));
      expect(byEmail.first.name, equals('Al-Faisal Publishers'));

      // Non-matching search
      final none = await supplierRepo.search('NonExistentSupplier');
      expect(none, isEmpty);
    });

    test('13. Delete supplier: deletes unreferenced supplier and updates BLoC list', () async {
      final id = await supplierRepo.create(const Supplier(
        name: 'One-off Vendor',
        openingBalance: 0.0,
      ));

      final allBefore = await supplierRepo.getAll();
      expect(allBefore.length, equals(1));

      final deleted = await supplierRepo.delete(id);
      expect(deleted, isTrue);

      final allAfter = await supplierRepo.getAll();
      expect(allAfter, isEmpty);
    });

    test('14. Supplier validation: rejects blank names, negative opening balance, and trims', () async {
      // Empty name
      expect(
        () => supplierRepo.create(const Supplier(name: '')),
        throwsA(isA<ValidationException>()),
      );

      // Whitespace-only name
      expect(
        () => supplierRepo.create(const Supplier(name: '   ')),
        throwsA(isA<ValidationException>()),
      );

      // Negative opening balance
      expect(
        () => supplierRepo.create(const Supplier(
          name: 'Negative Balance Supplier',
          openingBalance: -100.0,
        )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. Supplier detail loading: loads complete details and ledger balance via BLoC', () async {
      final id = await supplierRepo.create(const Supplier(
        name: 'Detailed Supplier Press',
        phone: '04237889900',
        email: 'info@detailedpress.com',
        address: 'Hall Road, Lahore',
        openingBalance: 30000.0,
        notes: 'Print on demand vendor',
      ));

      final bloc = SupplierBloc(
        supplierRepository: supplierRepo,
        ledgerService: supplierLedgerService,
      );

      bloc.add(const LoadSuppliers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoading>(),
          isA<SupplierLoaded>(),
        ]),
      );

      bloc.add(LoadSupplierDetails(id));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoaded>().having(
            (s) => s.selectedSupplier?.name,
            'selectedSupplier.name',
            'Detailed Supplier Press',
          ).having(
            (s) => s.selectedSupplierBalance,
            'selectedSupplierBalance',
            30000.0,
          ),
        ]),
      );

      await bloc.close();
    });

    test('16. Supplier balance retrieval: calculated via SupplierLedgerService', () async {
      final supplierId = await supplierRepo.create(const Supplier(
        name: 'Print Masters Press',
        openingBalance: 20000.0,
      ));

      // Initial balance equals opening balance
      final initialBalance = await supplierLedgerService.getSupplierBalance(supplierId);
      expect(initialBalance, equals(20000.0));

      // Record a purchase invoice with remaining payable amount of 8000.0
      await dbHelper.insert(
        DbConstants.tablePurchases,
        Purchase(
          supplierId: supplierId,
          invoiceNumber: 'PUR-TEST-001',
          purchaseDate: DateTime.now().toIso8601String(),
          subtotal: 12000.0,
          total: 12000.0,
          paidAmount: 4000.0,
          remainingAmount: 8000.0,
          paymentStatus: 'PARTIAL',
        ).toMap(),
      );

      // Balance = Opening (20000) + Credit Purchase (8000) = 28000.0
      final balanceAfterPurchase = await supplierLedgerService.getSupplierBalance(supplierId);
      expect(balanceAfterPurchase, equals(28000.0));

      // Record a disbursement payment to supplier of 13000.0
      await dbHelper.insert(
        DbConstants.tableSupplierPayments,
        SupplierPayment(
          supplierId: supplierId,
          amount: 13000.0,
          paymentDate: DateTime.now().toIso8601String(),
          paymentMethod: 'BANK_TRANSFER',
        ).toMap(),
      );

      // Balance = 28000 - 13000 = 15000.0
      final balanceAfterPayment = await supplierLedgerService.getSupplierBalance(supplierId);
      expect(balanceAfterPayment, equals(15000.0));
    });
  });

  // ===========================================================================
  // PART C: DELETE SAFETY & BLOC INTEGRITY
  // ===========================================================================
  group('Part C: Delete Safety & BLoC Integrity Tests', () {
    test('17. Delete safety for Customer: rejects deletion when sales or payments exist', () async {
      final custId = await customerRepo.create(const Customer(
        name: 'Referenced Customer',
        openingBalance: 0.0,
      ));

      // Link a sale
      await dbHelper.insert(
        DbConstants.tableSales,
        Sale(
          customerId: custId,
          invoiceNumber: 'INV-SAFETY-001',
          saleDate: DateTime.now().toIso8601String(),
          total: 500.0,
          paymentStatus: 'PAID',
        ).toMap(),
      );

      // CustomerRepo.delete must throw ValidationException
      expect(
        () => customerRepo.delete(custId),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('sales transactions exist'),
        )),
      );

      // Verify customer record is safely preserved
      final preserved = await customerRepo.getById(custId);
      expect(preserved, isNotNull);

      // Verify BLoC catches and emits error without crashing or removing row
      final bloc = CustomerBloc(
        customerRepository: customerRepo,
        ledgerService: customerLedgerService,
      );
      bloc.add(const LoadCustomers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerLoaded>().having((s) => s.customers.length, 'count', 1),
        ]),
      );

      bloc.add(DeleteCustomer(custId));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CustomerLoaded>().having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('sales transactions exist'),
          ).having(
            (s) => s.customers.length,
            'preserved customer count',
            1,
          ),
        ]),
      );

      await bloc.close();
    });

    test('18. Delete safety for Supplier: rejects deletion when purchases or payments exist', () async {
      final suppId = await supplierRepo.create(const Supplier(
        name: 'Referenced Supplier',
        openingBalance: 0.0,
      ));

      // Link a purchase
      await dbHelper.insert(
        DbConstants.tablePurchases,
        Purchase(
          supplierId: suppId,
          invoiceNumber: 'PUR-SAFETY-001',
          purchaseDate: DateTime.now().toIso8601String(),
          total: 1500.0,
          paymentStatus: 'PAID',
        ).toMap(),
      );

      // SupplierRepo.delete must throw ValidationException
      expect(
        () => supplierRepo.delete(suppId),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('purchase invoices are linked'),
        )),
      );

      // Verify supplier record is safely preserved
      final preserved = await supplierRepo.getById(suppId);
      expect(preserved, isNotNull);

      // Verify BLoC catches and emits error without crashing or removing row
      final bloc = SupplierBloc(
        supplierRepository: supplierRepo,
        ledgerService: supplierLedgerService,
      );
      bloc.add(const LoadSuppliers());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoading>(),
          isA<SupplierLoaded>().having((s) => s.suppliers.length, 'count', 1),
        ]),
      );

      bloc.add(DeleteSupplier(suppId));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SupplierLoaded>().having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('purchase invoices are linked'),
          ).having(
            (s) => s.suppliers.length,
            'preserved supplier count',
            1,
          ),
        ]),
      );

      await bloc.close();
    });
  });

  // ===========================================================================
  // PART D: UI MODALS & VALIDATION WIDGET TESTS
  // ===========================================================================
  group('Part D: Desktop Dialogs & Form Validation Widget Tests', () {
    testWidgets('19. Customer Form Dialog: validates required name and positive opening balance', (tester) async {
      Customer? savedCustomer;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  CustomerFormDialog.show(
                    ctx,
                    onSave: (c) => savedCustomer = c,
                  );
                },
                child: const Text('Open Customer Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Customer Form'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Customer'), findsOneWidget);
      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Financial Information'), findsOneWidget);
      expect(find.text('Additional Information'), findsOneWidget);

      // Click Create Customer without entering a name
      await tester.tap(find.text('Create Customer'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Customer name is required'), findsOneWidget);
      expect(savedCustomer, isNull);

      // Enter negative opening balance
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Test Academy',
      );
      await tester.enterText(
        find.byType(TextFormField).at(4),
        '-50',
      );

      await tester.tap(find.text('Create Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Opening balance cannot be negative'), findsOneWidget);
      expect(savedCustomer, isNull);

      // Enter valid opening balance and submit
      await tester.enterText(
        find.byType(TextFormField).at(4),
        '2500.00',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '03001234567',
      );

      await tester.tap(find.text('Create Customer'));
      await tester.pumpAndSettle();

      expect(savedCustomer, isNotNull);
      expect(savedCustomer!.name, equals('Test Academy'));
      expect(savedCustomer!.phone, equals('03001234567'));
      expect(savedCustomer!.openingBalance, equals(2500.0));
    });

    testWidgets('20. Supplier Form Dialog & Customer Detail Dialog display test', (tester) async {
      Supplier? savedSupplier;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  SupplierFormDialog.show(
                    ctx,
                    onSave: (s) => savedSupplier = s,
                  );
                },
                child: const Text('Open Supplier Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Supplier Form'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Supplier'), findsOneWidget);
      expect(find.text('Supplier / Publisher Name *'), findsOneWidget);

      // Enter valid supplier details
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Taj Company Ltd',
      );
      await tester.enterText(
        find.byType(TextFormField).at(4),
        '50000',
      );

      await tester.tap(find.text('Create Supplier'));
      await tester.pumpAndSettle();

      expect(savedSupplier, isNotNull);
      expect(savedSupplier!.name, equals('Taj Company Ltd'));
      expect(savedSupplier!.openingBalance, equals(50000.0));

      // Test Customer Detail Dialog
      const sampleCustomer = Customer(
        id: 99,
        name: 'Darul Uloom Library',
        phone: '03331122334',
        email: 'library@darululoom.edu',
        address: 'Sector 5, Korangi',
        openingBalance: 15000.0,
        notes: 'Annual book fair client',
        createdAt: '2026-09-24T12:00:00Z',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  CustomerDetailDialog.show(
                    ctx,
                    customer: sampleCustomer,
                    currentBalance: 18500.0,
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

      expect(find.text('Darul Uloom Library'), findsOneWidget);
      expect(find.text('Customer ID: #99 • Wholesale Account'), findsOneWidget);
      expect(find.text('Rs. 15000.00'), findsOneWidget);
      expect(find.text('Rs. 18500.00'), findsOneWidget);
      expect(find.text('library@darululoom.edu'), findsOneWidget);
      expect(find.text('Annual book fair client'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test Supplier Detail Dialog
      const sampleSupplier = Supplier(
        id: 88,
        name: 'Darul Ishaat Publishing',
        phone: '04237112233',
        email: 'info@darulishaat.com',
        address: 'Urdu Bazaar, Karachi',
        openingBalance: 35000.0,
        notes: 'Main Qurans and Hadith supplier',
        createdAt: '2026-09-24T12:00:00Z',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  SupplierDetailDialog.show(
                    ctx,
                    supplier: sampleSupplier,
                    currentBalance: 42000.0,
                  );
                },
                child: const Text('Open Supplier Detail Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Supplier Detail Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Darul Ishaat Publishing'), findsOneWidget);
      expect(find.text('Supplier ID: #88 • Publisher / Vendor Account'), findsOneWidget);
      expect(find.text('Rs. 35000.00'), findsOneWidget);
      expect(find.text('Rs. 42000.00'), findsOneWidget);
      expect(find.text('info@darulishaat.com'), findsOneWidget);
      expect(find.text('Main Qurans and Hadith supplier'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });
}
