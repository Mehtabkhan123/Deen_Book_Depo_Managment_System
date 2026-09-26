import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/stock_movement.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../domain/repositories/stock_movement_repository.dart';
import '../../domain/services/stock_service.dart';

// ==========================================
// Events
// ==========================================
abstract class InventoryEvent {
  const InventoryEvent();
}

class LoadInventory extends InventoryEvent {
  const LoadInventory();
}

class RefreshInventory extends InventoryEvent {
  const RefreshInventory();
}

class SearchInventory extends InventoryEvent {
  final String query;
  const SearchInventory(this.query);
}

class FilterInventory extends InventoryEvent {
  final int? categoryId;
  final String? stockStatus;
  const FilterInventory({this.categoryId, this.stockStatus});
}

class LoadStockMovements extends InventoryEvent {
  final int? bookId;
  final String? movementType;
  const LoadStockMovements({this.bookId, this.movementType});
}

class FilterStockMovements extends InventoryEvent {
  final int? bookId;
  final String? movementType;
  final String? query;
  const FilterStockMovements({this.bookId, this.movementType, this.query});
}

class ClearInventoryMessages extends InventoryEvent {
  const ClearInventoryMessages();
}

// ==========================================
// States
// ==========================================
abstract class InventoryState {
  const InventoryState();
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  final List<Book> books;
  final List<Book> filteredBooks;
  final Map<int, String> categoryNames;
  final Map<int, Book> booksMap;
  final String searchQuery;
  final int? selectedCategoryId;
  final String stockStatusFilter; // 'ALL', 'IN_STOCK', 'LOW_STOCK', 'OUT_OF_STOCK'
  final List<StockMovement> stockMovements;
  final List<StockMovement> filteredMovements;
  final bool isLoadingMovements;
  final int? movementsBookFilter;
  final String? movementsTypeFilter;
  final String movementsQuery;
  final String? successMessage;
  final String? errorMessage;

  const InventoryLoaded({
    required this.books,
    required this.filteredBooks,
    required this.categoryNames,
    required this.booksMap,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.stockStatusFilter = 'ALL',
    this.stockMovements = const [],
    this.filteredMovements = const [],
    this.isLoadingMovements = false,
    this.movementsBookFilter,
    this.movementsTypeFilter,
    this.movementsQuery = '',
    this.successMessage,
    this.errorMessage,
  });

  int get totalBooks => books.length;

  int get totalStockUnits =>
      books.fold(0, (sum, b) => sum + b.stockQuantity);

  int get lowStockCount => books
      .where((b) => b.stockQuantity > 0 && b.stockQuantity <= b.minimumStock)
      .length;

  int get outOfStockCount =>
      books.where((b) => b.stockQuantity <= 0).length;

  int get inStockCount =>
      books.where((b) => b.stockQuantity > b.minimumStock).length;

  static String computeStockStatus(Book book) {
    if (book.stockQuantity <= 0) return 'OUT OF STOCK';
    if (book.stockQuantity <= book.minimumStock) return 'LOW STOCK';
    return 'IN STOCK';
  }

  String getCategoryName(int? categoryId) {
    if (categoryId == null) return '--';
    return categoryNames[categoryId] ?? 'Category #$categoryId';
  }

  String getBookTitle(int bookId) {
    return booksMap[bookId]?.name ?? 'Book #$bookId';
  }

  InventoryLoaded copyWith({
    List<Book>? books,
    List<Book>? filteredBooks,
    Map<int, String>? categoryNames,
    Map<int, Book>? booksMap,
    String? searchQuery,
    int? selectedCategoryId,
    bool clearCategory = false,
    String? stockStatusFilter,
    List<StockMovement>? stockMovements,
    List<StockMovement>? filteredMovements,
    bool? isLoadingMovements,
    int? movementsBookFilter,
    bool clearMovementsBook = false,
    String? movementsTypeFilter,
    bool clearMovementsType = false,
    String? movementsQuery,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return InventoryLoaded(
      books: books ?? this.books,
      filteredBooks: filteredBooks ?? this.filteredBooks,
      categoryNames: categoryNames ?? this.categoryNames,
      booksMap: booksMap ?? this.booksMap,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      stockStatusFilter: stockStatusFilter ?? this.stockStatusFilter,
      stockMovements: stockMovements ?? this.stockMovements,
      filteredMovements: filteredMovements ?? this.filteredMovements,
      isLoadingMovements: isLoadingMovements ?? this.isLoadingMovements,
      movementsBookFilter: clearMovementsBook
          ? null
          : (movementsBookFilter ?? this.movementsBookFilter),
      movementsTypeFilter: clearMovementsType
          ? null
          : (movementsTypeFilter ?? this.movementsTypeFilter),
      movementsQuery: movementsQuery ?? this.movementsQuery,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
}

// ==========================================
// BLoC
// ==========================================
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final BookRepository bookRepository;
  final CategoryRepository categoryRepository;
  final StockMovementRepository stockMovementRepository;
  final StockService stockService;

  InventoryBloc({
    required this.bookRepository,
    required this.categoryRepository,
    required this.stockMovementRepository,
    required this.stockService,
  }) : super(const InventoryInitial()) {
    on<LoadInventory>(_onLoadInventory);
    on<RefreshInventory>(_onRefreshInventory);
    on<SearchInventory>(_onSearchInventory);
    on<FilterInventory>(_onFilterInventory);
    on<LoadStockMovements>(_onLoadStockMovements);
    on<FilterStockMovements>(_onFilterStockMovements);
    on<ClearInventoryMessages>(_onClearMessages);
  }

  Future<Map<int, String>> _loadCategoryNames() async {
    final list = await categoryRepository.getAll();
    return {for (final c in list) if (c.id != null) c.id!: c.name};
  }

  List<Book> _applyBookFilters({
    required List<Book> all,
    required String query,
    int? categoryId,
    required String statusFilter,
  }) {
    final trimmed = query.trim().toLowerCase();

    return all.where((b) {
      // 1. Text search across title, isbn, author, publisher
      if (trimmed.isNotEmpty) {
        final title = b.name.toLowerCase();
        final isbn = (b.isbn ?? '').toLowerCase();
        final author = (b.author ?? '').toLowerCase();
        final publisher = (b.publisher ?? '').toLowerCase();
        final matches = title.contains(trimmed) ||
            isbn.contains(trimmed) ||
            author.contains(trimmed) ||
            publisher.contains(trimmed);
        if (!matches) return false;
      }

      // 2. Category filter
      if (categoryId != null) {
        if (b.categoryId != categoryId) return false;
      }

      // 3. Stock status filter
      if (statusFilter != 'ALL') {
        if (statusFilter == 'IN_STOCK' &&
            b.stockQuantity <= b.minimumStock) {
          return false;
        }
        if (statusFilter == 'LOW_STOCK' &&
            (b.stockQuantity <= 0 || b.stockQuantity > b.minimumStock)) {
          return false;
        }
        if (statusFilter == 'OUT_OF_STOCK' && b.stockQuantity > 0) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<StockMovement> _applyMovementFilters({
    required List<StockMovement> all,
    required Map<int, Book> booksMap,
    int? bookId,
    String? movementType,
    String query = '',
  }) {
    final trimmed = query.trim().toLowerCase();

    return all.where((m) {
      // 1. Book ID filter
      if (bookId != null && m.bookId != bookId) {
        return false;
      }

      // 2. Movement type filter
      if (movementType != null && movementType != 'ALL') {
        if (m.movementType.toUpperCase() != movementType.toUpperCase()) {
          return false;
        }
      }

      // 3. Query filter: match book title, notes, or reference
      if (trimmed.isNotEmpty) {
        final bookTitle = booksMap[m.bookId]?.name.toLowerCase() ?? '';
        final notes = (m.notes ?? '').toLowerCase();
        final refType = (m.referenceType ?? '').toLowerCase();
        final refId = m.referenceId?.toString() ?? '';
        final matches = bookTitle.contains(trimmed) ||
            notes.contains(trimmed) ||
            refType.contains(trimmed) ||
            refId.contains(trimmed);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _onLoadInventory(
    LoadInventory event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final books = await bookRepository.getAll();
      final categoryNames = await _loadCategoryNames();
      final booksMap = {for (final b in books) if (b.id != null) b.id!: b};
      final filteredBooks = _applyBookFilters(
        all: books,
        query: '',
        statusFilter: 'ALL',
      );

      // Also pre-load movements
      final movements = await stockMovementRepository.getAll(limit: 100);
      final enrichedMovements = movements.map((m) {
        return m.copyWith(bookName: booksMap[m.bookId]?.name);
      }).toList();

      final filteredMovements = _applyMovementFilters(
        all: enrichedMovements,
        booksMap: booksMap,
      );

      emit(InventoryLoaded(
        books: books,
        filteredBooks: filteredBooks,
        categoryNames: categoryNames,
        booksMap: booksMap,
        stockMovements: enrichedMovements,
        filteredMovements: filteredMovements,
      ));
    } catch (e) {
      emit(InventoryError('Failed to load inventory: $e'));
    }
  }

  Future<void> _onRefreshInventory(
    RefreshInventory event,
    Emitter<InventoryState> emit,
  ) async {
    final current = state is InventoryLoaded ? (state as InventoryLoaded) : null;
    try {
      final books = await bookRepository.getAll();
      final categoryNames = await _loadCategoryNames();
      final booksMap = {for (final b in books) if (b.id != null) b.id!: b};

      final query = current?.searchQuery ?? '';
      final categoryId = current?.selectedCategoryId;
      final status = current?.stockStatusFilter ?? 'ALL';

      final filteredBooks = _applyBookFilters(
        all: books,
        query: query,
        categoryId: categoryId,
        statusFilter: status,
      );

      final movements = await stockMovementRepository.getAll(limit: 100);
      final enrichedMovements = movements.map((m) {
        return m.copyWith(bookName: booksMap[m.bookId]?.name);
      }).toList();

      final filteredMovements = _applyMovementFilters(
        all: enrichedMovements,
        booksMap: booksMap,
        bookId: current?.movementsBookFilter,
        movementType: current?.movementsTypeFilter,
        query: current?.movementsQuery ?? '',
      );

      emit(InventoryLoaded(
        books: books,
        filteredBooks: filteredBooks,
        categoryNames: categoryNames,
        booksMap: booksMap,
        searchQuery: query,
        selectedCategoryId: categoryId,
        stockStatusFilter: status,
        stockMovements: enrichedMovements,
        filteredMovements: filteredMovements,
        movementsBookFilter: current?.movementsBookFilter,
        movementsTypeFilter: current?.movementsTypeFilter,
        movementsQuery: current?.movementsQuery ?? '',
      ));
    } catch (e) {
      emit(InventoryError('Failed to refresh inventory: $e'));
    }
  }

  void _onSearchInventory(
    SearchInventory event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final current = state as InventoryLoaded;
      final filtered = _applyBookFilters(
        all: current.books,
        query: event.query,
        categoryId: current.selectedCategoryId,
        statusFilter: current.stockStatusFilter,
      );
      emit(current.copyWith(
        searchQuery: event.query,
        filteredBooks: filtered,
      ));
    }
  }

  void _onFilterInventory(
    FilterInventory event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final current = state as InventoryLoaded;
      final status = event.stockStatus ?? current.stockStatusFilter;
      final categoryId = event.categoryId;

      final filtered = _applyBookFilters(
        all: current.books,
        query: current.searchQuery,
        categoryId: categoryId,
        statusFilter: status,
      );

      emit(current.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null,
        stockStatusFilter: status,
        filteredBooks: filtered,
      ));
    }
  }

  Future<void> _onLoadStockMovements(
    LoadStockMovements event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final current = state as InventoryLoaded;
      emit(current.copyWith(isLoadingMovements: true));
      try {
        List<StockMovement> movements;
        if (event.bookId != null) {
          movements = await stockMovementRepository.getByBookId(event.bookId!);
        } else {
          movements = await stockMovementRepository.getAll(limit: 200);
        }

        final enriched = movements.map((m) {
          return m.copyWith(bookName: current.booksMap[m.bookId]?.name);
        }).toList();

        final filtered = _applyMovementFilters(
          all: enriched,
          booksMap: current.booksMap,
          bookId: event.bookId,
          movementType: event.movementType,
          query: current.movementsQuery,
        );

        emit(current.copyWith(
          stockMovements: enriched,
          filteredMovements: filtered,
          isLoadingMovements: false,
          movementsBookFilter: event.bookId,
          clearMovementsBook: event.bookId == null,
          movementsTypeFilter: event.movementType,
          clearMovementsType: event.movementType == null || event.movementType == 'ALL',
        ));
      } catch (e) {
        emit(current.copyWith(
          isLoadingMovements: false,
          errorMessage: 'Failed to load stock movements: $e',
          clearSuccess: true,
        ));
      }
    }
  }

  void _onFilterStockMovements(
    FilterStockMovements event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final current = state as InventoryLoaded;
      final bookId = event.bookId ?? current.movementsBookFilter;
      final type = event.movementType ?? current.movementsTypeFilter;
      final query = event.query ?? current.movementsQuery;

      final filtered = _applyMovementFilters(
        all: current.stockMovements,
        booksMap: current.booksMap,
        bookId: bookId,
        movementType: type,
        query: query,
      );

      emit(current.copyWith(
        movementsBookFilter: bookId,
        clearMovementsBook: event.bookId == null && bookId == null,
        movementsTypeFilter: type,
        clearMovementsType: event.movementType == null && type == null,
        movementsQuery: query,
        filteredMovements: filtered,
      ));
    }
  }

  void _onClearMessages(
    ClearInventoryMessages event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      emit((state as InventoryLoaded)
          .copyWith(clearSuccess: true, clearError: true));
    }
  }
}
