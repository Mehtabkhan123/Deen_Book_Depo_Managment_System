import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deen_book_depo/core/database/database_helper.dart';
import 'package:deen_book_depo/core/database/database_service.dart';
import 'package:deen_book_depo/core/errors/exceptions.dart';
import 'package:deen_book_depo/core/theme/theme.dart';
import 'package:deen_book_depo/features/books/data/repositories/sqlite_book_repository.dart';
import 'package:deen_book_depo/features/books/domain/repositories/book_repository.dart';
import 'package:deen_book_depo/features/books/presentation/bloc/books_bloc.dart';
import 'package:deen_book_depo/features/books/presentation/widgets/book_form_dialog.dart';
import 'package:deen_book_depo/features/categories/data/repositories/sqlite_category_repository.dart';
import 'package:deen_book_depo/features/categories/domain/repositories/category_repository.dart';
import 'package:deen_book_depo/features/categories/presentation/bloc/category_bloc.dart';
import 'package:deen_book_depo/features/categories/presentation/widgets/category_form_dialog.dart';
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

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('step5_test_');
    testDbPath = '${tempDir.path}${Platform.pathSeparator}wholesale_test.db';

    dbService = DatabaseService.instance;
    await dbService.init(overridePath: testDbPath);
    dbHelper = DatabaseHelper(dbService);

    categoryRepo = SqliteCategoryRepository(dbHelper);
    bookRepo = SqliteBookRepository(dbHelper);
  });

  tearDown(() async {
    await dbService.close();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('Category Management Repository & BLoC Tests', () {
    test('1. Load categories: empty initially then loads records', () async {
      final initial = await categoryRepo.getAll();
      expect(initial, isEmpty);

      final catId = await categoryRepo.create(const Category(name: 'Islamic Studies'));
      expect(catId, isPositive);

      final loaded = await categoryRepo.getAll();
      expect(loaded.length, equals(1));
      expect(loaded.first.name, equals('Islamic Studies'));
    });

    test('2. Create category with description and query by ID', () async {
      final catId = await categoryRepo.create(const Category(
        name: 'Literature',
        description: 'Poetry and prose books',
      ));

      final fetched = await categoryRepo.getById(catId);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Literature'));
      expect(fetched.description, equals('Poetry and prose books'));
    });

    test('3. Update category name and description', () async {
      final catId = await categoryRepo.create(const Category(name: 'General'));
      final existing = await categoryRepo.getById(catId);

      final updatedCategory = existing!.copyWith(
        name: 'General Science',
        description: 'Science textbooks',
      );
      final success = await categoryRepo.update(updatedCategory);
      expect(success, isTrue);

      final afterUpdate = await categoryRepo.getById(catId);
      expect(afterUpdate!.name, equals('General Science'));
      expect(afterUpdate.description, equals('Science textbooks'));
    });

    test('4. Search categories by partial name', () async {
      await categoryRepo.create(const Category(name: 'Urdu Literature'));
      await categoryRepo.create(const Category(name: 'English Grammar'));
      await categoryRepo.create(const Category(name: 'Urdu Poetry'));

      final searchResults = await categoryRepo.search('urdu');
      expect(searchResults.length, equals(2));
      expect(searchResults.any((c) => c.name == 'English Grammar'), isFalse);
    });

    test('5. Delete category without dependent books succeeds', () async {
      final catId = await categoryRepo.create(const Category(name: 'Temporary'));
      final deleted = await categoryRepo.delete(catId);
      expect(deleted, isTrue);

      final fetched = await categoryRepo.getById(catId);
      expect(fetched, isNull);
    });

    test('6. Duplicate category name throws ValidationException', () async {
      await categoryRepo.create(const Category(name: 'Duplicate Test'));
      expect(
        () => categoryRepo.create(const Category(name: 'Duplicate Test')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. Empty category name throws ValidationException', () async {
      expect(
        () => categoryRepo.create(const Category(name: '   ')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('8. Category foreign key safety: cannot delete category if books assigned', () async {
      final catId = await categoryRepo.create(const Category(name: 'Fiction'));
      await bookRepo.create(Book(
        name: 'Novel 1',
        categoryId: catId,
        purchasePrice: 100,
        wholesalePrice: 150,
        retailPrice: 200,
      ));

      expect(
        () => categoryRepo.delete(catId),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('books are assigned'),
        )),
      );
    });

    test('9. CategoryBloc BLoC operations and state transitions', () async {
      final bloc = CategoryBloc(categoryRepository: categoryRepo);

      expect(bloc.state, isA<CategoryInitial>());

      bloc.add(const AddCategory(Category(name: 'Tafseer')));
      await pumpEventQueue();

      expect(bloc.state, isA<CategoryLoaded>());
      final loadedState = bloc.state as CategoryLoaded;
      expect(loadedState.categories.length, equals(1));
      expect(loadedState.categories.first.name, equals('Tafseer'));
      expect(loadedState.successMessage, contains('created successfully'));

      // Search
      bloc.add(const SearchCategories('Taf'));
      await pumpEventQueue();
      expect(bloc.state, isA<CategoryLoaded>());
      expect((bloc.state as CategoryLoaded).categories.length, equals(1));

      // Attempt duplicate addition through BLoC
      bloc.add(const AddCategory(Category(name: 'Tafseer')));
      await pumpEventQueue();
      expect(bloc.state, isA<CategoryLoaded>());
      expect((bloc.state as CategoryLoaded).errorMessage, isNotNull);

      bloc.close();
    });
  });

  group('Book Management Repository & BLoC Tests', () {
    test('10. Load books: empty initially then loads created books', () async {
      final initial = await bookRepo.getAll();
      expect(initial, isEmpty);

      final bookId = await bookRepo.create(const Book(
        name: 'Urdu Qaida',
        purchasePrice: 40.0,
        wholesalePrice: 60.0,
        retailPrice: 80.0,
        stockQuantity: 100,
        minimumStock: 10,
      ));
      expect(bookId, isPositive);

      final loaded = await bookRepo.getAll();
      expect(loaded.length, equals(1));
      expect(loaded.first.name, equals('Urdu Qaida'));
    });

    test('11. Create book with publication details and query by ISBN', () async {
      await bookRepo.create(const Book(
        name: 'Bukhari Shareef Vol 1',
        isbn: '978-969-000-001',
        author: 'Imam Bukhari',
        publisher: 'Darussalam',
        purchasePrice: 500,
        wholesalePrice: 750,
        retailPrice: 900,
        stockQuantity: 25,
        minimumStock: 5,
      ));

      final byIsbn = await bookRepo.getByIsbn('978-969-000-001');
      expect(byIsbn, isNotNull);
      expect(byIsbn!.name, equals('Bukhari Shareef Vol 1'));
      expect(byIsbn.author, equals('Imam Bukhari'));
      expect(byIsbn.publisher, equals('Darussalam'));
    });

    test('12. Update book prices and stock alert threshold', () async {
      final bookId = await bookRepo.create(const Book(
        name: 'Math Grade 5',
        purchasePrice: 120,
        wholesalePrice: 180,
        retailPrice: 220,
        stockQuantity: 50,
        minimumStock: 10,
      ));

      final existing = await bookRepo.getById(bookId);
      final updated = existing!.copyWith(
        wholesalePrice: 195,
        retailPrice: 240,
        minimumStock: 15,
      );

      final success = await bookRepo.update(updated);
      expect(success, isTrue);

      final reFetched = await bookRepo.getById(bookId);
      expect(reFetched!.wholesalePrice, equals(195.0));
      expect(reFetched.retailPrice, equals(240.0));
      expect(reFetched.minimumStock, equals(15));
    });

    test('13. Multi-field Search (Name, ISBN, Author, Publisher)', () async {
      await bookRepo.create(const Book(
        name: 'Physics Principles',
        isbn: '978-01-PHY-01',
        author: 'Dr. Halliday',
        publisher: 'Wiley Academic',
        purchasePrice: 300,
        wholesalePrice: 400,
        retailPrice: 500,
      ));

      await bookRepo.create(const Book(
        name: 'Chemistry Reactions',
        isbn: '978-01-CHEM-02',
        author: 'Raymond Chang',
        publisher: 'McGraw-Hill',
        purchasePrice: 280,
        wholesalePrice: 380,
        retailPrice: 480,
      ));

      // Match by title
      expect((await bookRepo.search('Physics')).length, equals(1));
      // Match by author
      expect((await bookRepo.search('Chang')).length, equals(1));
      // Match by ISBN
      expect((await bookRepo.search('PHY-01')).length, equals(1));
      // Match by publisher
      expect((await bookRepo.search('Wiley')).length, equals(1));
    });

    test('14. Category Filtering and Combined searchAndFilter', () async {
      final cat1 = await categoryRepo.create(const Category(name: 'Islamic'));
      final cat2 = await categoryRepo.create(const Category(name: 'Science'));

      await bookRepo.create(Book(
        name: 'Riyad us Saliheen',
        categoryId: cat1,
        purchasePrice: 400,
        wholesalePrice: 600,
        retailPrice: 750,
      ));

      await bookRepo.create(Book(
        name: 'General Science Class 6',
        categoryId: cat2,
        purchasePrice: 150,
        wholesalePrice: 200,
        retailPrice: 250,
      ));

      // Filter by category
      final islamicBooks = await bookRepo.searchAndFilter(categoryId: cat1);
      expect(islamicBooks.length, equals(1));
      expect(islamicBooks.first.name, equals('Riyad us Saliheen'));

      // Filter by category and search term
      final searchAndCat = await bookRepo.searchAndFilter(
        query: 'Science',
        categoryId: cat2,
      );
      expect(searchAndCat.length, equals(1));

      // Mismatched category and query yields empty
      final mismatched = await bookRepo.searchAndFilter(
        query: 'Riyad',
        categoryId: cat2,
      );
      expect(mismatched, isEmpty);
    });

    test('15. Delete book without transactions succeeds', () async {
      final bookId = await bookRepo.create(const Book(
        name: 'Book to Delete',
        purchasePrice: 100,
        wholesalePrice: 150,
        retailPrice: 200,
      ));

      final deleted = await bookRepo.delete(bookId);
      expect(deleted, isTrue);

      final reFetched = await bookRepo.getById(bookId);
      expect(reFetched, isNull);
    });

    test('16. Validation failures on book creation', () async {
      // Empty title
      expect(
        () => bookRepo.create(const Book(name: '   ')),
        throwsA(isA<ValidationException>()),
      );

      // Negative purchase price
      expect(
        () => bookRepo.create(const Book(name: 'Valid Name', purchasePrice: -10)),
        throwsA(isA<ValidationException>()),
      );

      // Negative stock
      expect(
        () => bookRepo.create(const Book(name: 'Valid Name', stockQuantity: -5)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. Low-stock visual indicator and calculation', () async {
      final inStock = const Book(name: 'Book A', stockQuantity: 20, minimumStock: 5);
      final lowStock = const Book(name: 'Book B', stockQuantity: 5, minimumStock: 5);
      final outOfStock = const Book(name: 'Book C', stockQuantity: 0, minimumStock: 5);

      expect(inStock.stockQuantity > inStock.minimumStock, isTrue);
      expect(lowStock.stockQuantity <= lowStock.minimumStock && lowStock.stockQuantity > 0, isTrue);
      expect(outOfStock.stockQuantity <= 0, isTrue);

      await bookRepo.create(lowStock);
      await bookRepo.create(outOfStock);
      await bookRepo.create(inStock);

      final lowStockList = await bookRepo.getLowStockBooks();
      expect(lowStockList.length, equals(2));
      expect(lowStockList.any((b) => b.name == 'Book A'), isFalse);
    });

    test('18. BooksBloc BLoC operations and state transitions', () async {
      final bloc = BooksBloc(bookRepository: bookRepo);

      expect(bloc.state, isA<BooksInitial>());

      bloc.add(const AddBook(Book(
        name: 'Bloc Book',
        purchasePrice: 100,
        wholesalePrice: 150,
        retailPrice: 200,
        stockQuantity: 15,
        minimumStock: 5,
      )));
      await pumpEventQueue(times: 50);

      expect(bloc.state, isA<BooksLoaded>());
      final loaded = bloc.state as BooksLoaded;
      expect(loaded.books.length, equals(1));
      expect(loaded.books.first.name, equals('Bloc Book'));
      expect(loaded.successMessage, contains('created successfully'));

      // Filter
      bloc.add(const FilterBooksByCategory(999));
      await pumpEventQueue(times: 50);
      expect(bloc.state, isA<BooksLoaded>());
      expect((bloc.state as BooksLoaded).books, isEmpty);

      // Reset Filter
      bloc.add(const FilterBooksByCategory(null));
      await pumpEventQueue(times: 50);
      expect(bloc.state, isA<BooksLoaded>());
      expect((bloc.state as BooksLoaded).books.length, equals(1));

      bloc.close();
    });
  });

  group('Dialog UI Widget Tests', () {
    testWidgets('CategoryFormDialog renders and validates input', (tester) async {
      Category? savedCategory;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CategoryFormDialog.show(
                  ctx,
                  onSave: (cat) => savedCategory = cat,
                ),
                child: const Text('Open Category Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Category Form'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Category'), findsOneWidget);
      expect(find.text('Create Category'), findsOneWidget);

      // Attempt submit without name
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();
      expect(find.text('Category name is required'), findsOneWidget);

      // Enter valid name
      await tester.enterText(find.byType(TextFormField).first, 'Islamic Philosophy');
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();

      expect(savedCategory, isNotNull);
      expect(savedCategory!.name, equals('Islamic Philosophy'));
    });

    testWidgets('BookFormDialog renders all 4 sections and validates input', (tester) async {
      Book? savedBook;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => BookFormDialog.show(
                  ctx,
                  categories: const [Category(id: 1, name: 'Tafseer')],
                  onSave: (b) => savedBook = b,
                ),
                child: const Text('Open Book Form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Book Form'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Book Title'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Publication Details'), findsOneWidget);
      expect(find.text('Pricing (PKR / Currency)'), findsOneWidget);
      expect(find.text('Inventory & Stock Alerts'), findsOneWidget);

      // Enter book name
      await tester.enterText(find.byType(TextFormField).first, 'Tafseer Ibn Kathir');

      // Tap Register Book
      await tester.tap(find.text('Register Book'));
      await tester.pumpAndSettle();

      expect(savedBook, isNotNull);
      expect(savedBook!.name, equals('Tafseer Ibn Kathir'));
    });
  });
}
