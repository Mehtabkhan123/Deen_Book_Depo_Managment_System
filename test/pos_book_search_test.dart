import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:deen_book_depo/shared/models/book.dart';
import 'package:deen_book_depo/shared/models/category.dart';

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
    tempDir = await Directory.systemTemp.createTemp('pos_search_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}pos_search.db';

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

  Future<void> seedTestBooks() async {
    final catId = await categoryRepo.create(
      const Category(
        name: 'Islamic Classical Literature',
        description: 'Hadith and Tafseer texts',
      ),
    );

    // 1. Sahih al-Bukhari (In stock, standard)
    await bookRepo.create(
      Book(
        categoryId: catId,
        name: 'Sahih al-Bukhari Complete 9 Volumes',
        isbn: '978-0-14-044913-6',
        author: 'Imam Muhammad al-Bukhari',
        publisher: 'Darussalam Publications',
        wholesalePrice: 4200.0,
        retailPrice: 5500.0,
        stockQuantity: 25,
        minimumStock: 5,
      ),
    );

    // 2. Riyadh as-Salihin (In stock, different author/publisher)
    await bookRepo.create(
      Book(
        categoryId: catId,
        name: 'Riyadh as-Salihin Arabic Urdu',
        isbn: '978-1-56564-001-5',
        author: 'Imam an-Nawawi',
        publisher: 'Maktaba Quddusia',
        wholesalePrice: 650.0,
        retailPrice: 900.0,
        stockQuantity: 12,
        minimumStock: 4,
      ),
    );

    // 3. Tafsir Ibn Kathir (ZERO STOCK, out of stock)
    await bookRepo.create(
      Book(
        categoryId: catId,
        name: 'Tafsir Ibn Kathir Comprehensive Set',
        isbn: '978-9-960-89271-9',
        author: 'Hafiz Ibn Kathir',
        publisher: 'Darussalam Global',
        wholesalePrice: 3800.0,
        retailPrice: 4800.0,
        stockQuantity: 0, // ZERO STOCK
        minimumStock: 3,
      ),
    );
  }

  group('POS SQLite Book Search Requirements', () {
    test('1. Search by complete book name matches SQLite record', () async {
      await seedTestBooks();

      final results = await bookRepo.search(
        'Sahih al-Bukhari Complete 9 Volumes',
      );
      expect(results, hasLength(1));
      expect(results.first.name, equals('Sahih al-Bukhari Complete 9 Volumes'));
      expect(results.first.stockQuantity, equals(25));
    });

    test(
      '2. Search by partial book name returns all matching records',
      () async {
        await seedTestBooks();

        final results = await bookRepo.search('Salihin');
        expect(results, hasLength(1));
        expect(results.first.name, contains('Riyadh as-Salihin'));
      },
    );

    test(
      '3. Search by ISBN with and without hyphens (barcode format)',
      () async {
        await seedTestBooks();

        // With exact hyphens
        final withHyphens = await bookRepo.search('978-0-14-044913-6');
        expect(withHyphens, hasLength(1));
        expect(withHyphens.first.name, contains('Sahih al-Bukhari'));

        // Raw barcode digits without hyphens
        final rawDigits = await bookRepo.search('9780140449136');
        expect(rawDigits, hasLength(1));
        expect(rawDigits.first.name, contains('Sahih al-Bukhari'));
      },
    );

    test('4. Search by author matches correct books', () async {
      await seedTestBooks();

      final results = await bookRepo.search('Nawawi');
      expect(results, hasLength(1));
      expect(results.first.author, equals('Imam an-Nawawi'));
    });

    test('5. Search by publisher matches correct books', () async {
      await seedTestBooks();

      final results = await bookRepo.search('Darussalam');
      // Both Bukhari and Ibn Kathir have Darussalam
      expect(results.length, equals(2));
    });

    test(
      '6. Search is completely case-insensitive (UPPERCASE & lowercase)',
      () async {
        await seedTestBooks();

        final lower = await bookRepo.search('bukhari');
        final upper = await bookRepo.search('BUKHARI');
        final mixed = await bookRepo.search('BuKhArI');

        expect(lower, hasLength(1));
        expect(upper, hasLength(1));
        expect(mixed, hasLength(1));
        expect(lower.first.id, equals(upper.first.id));
      },
    );

    test(
      '7. Search does NOT hide zero-stock books (returns out-of-stock items)',
      () async {
        await seedTestBooks();

        final zeroStockResults = await bookRepo.search('Tafsir Ibn Kathir');
        expect(zeroStockResults, hasLength(1));
        expect(zeroStockResults.first.name, contains('Tafsir Ibn Kathir'));
        expect(zeroStockResults.first.stockQuantity, equals(0));
        expect(zeroStockResults.first.isLowStock, isTrue);
      },
    );

    test(
      '8. SalesBloc SearchPosBooks event updates states with SQLite results',
      () async {
        await seedTestBooks();

        final salesBloc = SalesBloc(
          saleRepository: saleRepo,
          customerRepository: customerRepo,
          bookRepository: bookRepo,
        );

        final loadedFuture = salesBloc.stream.firstWhere(
          (s) => s is SalesLoaded,
        );
        salesBloc.add(const LoadSales());
        await loadedFuture;

        // Dispatch SearchPosBooks
        final searchFuture = salesBloc.stream.firstWhere(
          (s) =>
              s is SalesLoaded &&
              !s.isSearchingPosBooks &&
              s.posSearchResults.isNotEmpty,
        );
        salesBloc.add(const SearchPosBooks('Salihin'));
        final state = (await searchFuture) as SalesLoaded;

        expect(state.posSearchResults, hasLength(1));
        expect(
          state.posSearchResults.first.name,
          contains('Riyadh as-Salihin'),
        );
        expect(state.posBookSearchQuery, equals('Salihin'));

        // Dispatch ClearPosBookSearch
        final clearFuture = salesBloc.stream.firstWhere(
          (s) =>
              s is SalesLoaded &&
              s.posSearchResults.isEmpty &&
              s.posBookSearchQuery.isEmpty,
        );
        salesBloc.add(const ClearPosBookSearch());
        final clearedState = (await clearFuture) as SalesLoaded;
        expect(clearedState.posSearchResults, isEmpty);

        await salesBloc.close();
      },
    );
  });

  group('POS UI Book Search Integration Tests', () {
    test(
      '9. SalesBloc search preserves out-of-stock items and handles non-matching queries and empty states',
      () async {
        await seedTestBooks();

        final salesBloc = SalesBloc(
          saleRepository: saleRepo,
          customerRepository: customerRepo,
          bookRepository: bookRepo,
        );

        final loadedFuture = salesBloc.stream.firstWhere(
          (s) => s is SalesLoaded,
        );
        salesBloc.add(const LoadSales());
        await loadedFuture;

        // Search for zero-stock book 'Ibn Kathir'
        final zeroStockFuture = salesBloc.stream.firstWhere(
          (s) =>
              s is SalesLoaded &&
              !s.isSearchingPosBooks &&
              s.posBookSearchQuery == 'Ibn Kathir',
        );
        salesBloc.add(const SearchPosBooks('Ibn Kathir'));
        final zeroStockState = (await zeroStockFuture) as SalesLoaded;

        expect(zeroStockState.posSearchResults, hasLength(1));
        expect(
          zeroStockState.posSearchResults.first.name,
          contains('Tafsir Ibn Kathir'),
        );
        expect(zeroStockState.posSearchResults.first.stockQuantity, equals(0));

        // Search for non-existent book returns empty results (UI shows empty state)
        final emptyFuture = salesBloc.stream.firstWhere(
          (s) =>
              s is SalesLoaded &&
              !s.isSearchingPosBooks &&
              s.posBookSearchQuery == 'NonExistentBookXYZ',
        );
        salesBloc.add(const SearchPosBooks('NonExistentBookXYZ'));
        final emptyState = (await emptyFuture) as SalesLoaded;

        expect(emptyState.posSearchResults, isEmpty);
        expect(emptyState.posBookSearchQuery, equals('NonExistentBookXYZ'));

        // Clear search restores clean POS state
        final clearFuture = salesBloc.stream.firstWhere(
          (s) =>
              s is SalesLoaded &&
              s.posSearchResults.isEmpty &&
              s.posBookSearchQuery.isEmpty,
        );
        salesBloc.add(const ClearPosBookSearch());
        final clearedState = (await clearFuture) as SalesLoaded;
        expect(clearedState.posSearchResults, isEmpty);

        await salesBloc.close();
      },
    );
  });
}
