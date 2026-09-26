import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/purchase_item.dart';
import '../../../../shared/models/supplier.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../suppliers/domain/repositories/supplier_repository.dart';
import '../../domain/repositories/purchase_repository.dart';

// ==========================================
// Events
// ==========================================
abstract class PurchaseEvent {
  const PurchaseEvent();
}

class LoadPurchases extends PurchaseEvent {
  const LoadPurchases();
}

class RefreshPurchases extends PurchaseEvent {
  const RefreshPurchases();
}

class SearchPurchases extends PurchaseEvent {
  final String query;
  const SearchPurchases(this.query);
}

class FilterPurchases extends PurchaseEvent {
  final String? paymentStatus;
  final int? supplierId;
  const FilterPurchases({this.paymentStatus, this.supplierId});
}

class LoadPurchaseDetails extends PurchaseEvent {
  final int id;
  const LoadPurchaseDetails(this.id);
}

class CreatePurchase extends PurchaseEvent {
  final Purchase purchase;
  final List<PurchaseItem> items;
  const CreatePurchase({
    required this.purchase,
    required this.items,
  });
}

class DeletePurchase extends PurchaseEvent {
  final int id;
  const DeletePurchase(this.id);
}

class ClearPurchaseMessages extends PurchaseEvent {
  const ClearPurchaseMessages();
}

// ==========================================
// States
// ==========================================
abstract class PurchaseState {
  const PurchaseState();
}

class PurchaseInitial extends PurchaseState {
  const PurchaseInitial();
}

class PurchaseLoading extends PurchaseState {
  const PurchaseLoading();
}

class PurchaseLoaded extends PurchaseState {
  final List<Purchase> purchases;
  final List<Purchase> filteredPurchases;
  final Map<int, Supplier> suppliers;
  final Map<int, Book> books;
  final String searchQuery;
  final String? paymentStatusFilter;
  final int? supplierFilter;
  final Purchase? selectedPurchase;
  final List<PurchaseItem>? selectedPurchaseItems;
  final bool isCreating;
  final String? successMessage;
  final String? errorMessage;

  const PurchaseLoaded({
    required this.purchases,
    required this.filteredPurchases,
    required this.suppliers,
    required this.books,
    this.searchQuery = '',
    this.paymentStatusFilter,
    this.supplierFilter,
    this.selectedPurchase,
    this.selectedPurchaseItems,
    this.isCreating = false,
    this.successMessage,
    this.errorMessage,
  });

  String getSupplierName(int supplierId) {
    return suppliers[supplierId]?.name ?? 'Supplier #$supplierId';
  }

  String getSupplierPhone(int supplierId) {
    return suppliers[supplierId]?.phone ?? '--';
  }

  String getBookTitle(int bookId) {
    return books[bookId]?.name ?? 'Book #$bookId';
  }

  String getBookIsbn(int bookId) {
    return books[bookId]?.isbn ?? '--';
  }

  PurchaseLoaded copyWith({
    List<Purchase>? purchases,
    List<Purchase>? filteredPurchases,
    Map<int, Supplier>? suppliers,
    Map<int, Book>? books,
    String? searchQuery,
    String? paymentStatusFilter,
    bool clearStatusFilter = false,
    int? supplierFilter,
    bool clearSupplierFilter = false,
    Purchase? selectedPurchase,
    List<PurchaseItem>? selectedPurchaseItems,
    bool clearSelected = false,
    bool? isCreating,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return PurchaseLoaded(
      purchases: purchases ?? this.purchases,
      filteredPurchases: filteredPurchases ?? this.filteredPurchases,
      suppliers: suppliers ?? this.suppliers,
      books: books ?? this.books,
      searchQuery: searchQuery ?? this.searchQuery,
      paymentStatusFilter: clearStatusFilter
          ? null
          : (paymentStatusFilter ?? this.paymentStatusFilter),
      supplierFilter: clearSupplierFilter
          ? null
          : (supplierFilter ?? this.supplierFilter),
      selectedPurchase:
          clearSelected ? null : (selectedPurchase ?? this.selectedPurchase),
      selectedPurchaseItems: clearSelected
          ? null
          : (selectedPurchaseItems ?? this.selectedPurchaseItems),
      isCreating: isCreating ?? this.isCreating,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PurchaseError extends PurchaseState {
  final String message;
  const PurchaseError(this.message);
}

// ==========================================
// BLoC
// ==========================================
class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final PurchaseRepository purchaseRepository;
  final SupplierRepository supplierRepository;
  final BookRepository bookRepository;

  PurchaseBloc({
    required this.purchaseRepository,
    required this.supplierRepository,
    required this.bookRepository,
  }) : super(const PurchaseInitial()) {
    on<LoadPurchases>(_onLoadPurchases);
    on<RefreshPurchases>(_onRefreshPurchases);
    on<SearchPurchases>(_onSearchPurchases);
    on<FilterPurchases>(_onFilterPurchases);
    on<LoadPurchaseDetails>(_onLoadPurchaseDetails);
    on<CreatePurchase>(_onCreatePurchase);
    on<DeletePurchase>(_onDeletePurchase);
    on<ClearPurchaseMessages>(_onClearMessages);
  }

  Future<Map<int, Supplier>> _loadSuppliersMap() async {
    final list = await supplierRepository.getAll();
    return {for (final s in list) if (s.id != null) s.id!: s};
  }

  Future<Map<int, Book>> _loadBooksMap() async {
    final list = await bookRepository.getAll();
    return {for (final b in list) if (b.id != null) b.id!: b};
  }

  List<Purchase> _applyFilters({
    required List<Purchase> all,
    required Map<int, Supplier> suppliers,
    required String query,
    String? status,
    int? supplierId,
  }) {
    final trimmedQuery = query.trim().toLowerCase();

    return all.where((p) {
      // 1. Query filter: match invoice number or supplier name
      if (trimmedQuery.isNotEmpty) {
        final invoiceMatch =
            p.invoiceNumber.toLowerCase().contains(trimmedQuery);
        final suppName = suppliers[p.supplierId]?.name.toLowerCase() ?? '';
        final supplierMatch = suppName.contains(trimmedQuery);
        if (!invoiceMatch && !supplierMatch) return false;
      }

      // 2. Payment status filter
      if (status != null && status != 'ALL') {
        if (p.paymentStatus.toUpperCase() != status.toUpperCase()) {
          return false;
        }
      }

      // 3. Supplier filter
      if (supplierId != null) {
        if (p.supplierId != supplierId) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _onLoadPurchases(
    LoadPurchases event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());
    try {
      final purchases = await purchaseRepository.getAll();
      final suppliers = await _loadSuppliersMap();
      final books = await _loadBooksMap();
      final filtered = _applyFilters(
        all: purchases,
        suppliers: suppliers,
        query: '',
      );

      emit(PurchaseLoaded(
        purchases: purchases,
        filteredPurchases: filtered,
        suppliers: suppliers,
        books: books,
      ));
    } catch (e) {
      emit(PurchaseError('Failed to load purchases: $e'));
    }
  }

  Future<void> _onRefreshPurchases(
    RefreshPurchases event,
    Emitter<PurchaseState> emit,
  ) async {
    final current = state is PurchaseLoaded ? (state as PurchaseLoaded) : null;
    try {
      final purchases = await purchaseRepository.getAll();
      final suppliers = await _loadSuppliersMap();
      final books = await _loadBooksMap();
      final query = current?.searchQuery ?? '';
      final status = current?.paymentStatusFilter;
      final suppId = current?.supplierFilter;

      final filtered = _applyFilters(
        all: purchases,
        suppliers: suppliers,
        query: query,
        status: status,
        supplierId: suppId,
      );

      emit(PurchaseLoaded(
        purchases: purchases,
        filteredPurchases: filtered,
        suppliers: suppliers,
        books: books,
        searchQuery: query,
        paymentStatusFilter: status,
        supplierFilter: suppId,
      ));
    } catch (e) {
      emit(PurchaseError('Failed to refresh purchases: $e'));
    }
  }

  void _onSearchPurchases(
    SearchPurchases event,
    Emitter<PurchaseState> emit,
  ) {
    if (state is PurchaseLoaded) {
      final current = state as PurchaseLoaded;
      final filtered = _applyFilters(
        all: current.purchases,
        suppliers: current.suppliers,
        query: event.query,
        status: current.paymentStatusFilter,
        supplierId: current.supplierFilter,
      );
      emit(current.copyWith(
        searchQuery: event.query,
        filteredPurchases: filtered,
      ));
    }
  }

  void _onFilterPurchases(
    FilterPurchases event,
    Emitter<PurchaseState> emit,
  ) {
    if (state is PurchaseLoaded) {
      final current = state as PurchaseLoaded;
      final filtered = _applyFilters(
        all: current.purchases,
        suppliers: current.suppliers,
        query: current.searchQuery,
        status: event.paymentStatus,
        supplierId: event.supplierId,
      );
      emit(current.copyWith(
        paymentStatusFilter: event.paymentStatus,
        clearStatusFilter: event.paymentStatus == null || event.paymentStatus == 'ALL',
        supplierFilter: event.supplierId,
        clearSupplierFilter: event.supplierId == null,
        filteredPurchases: filtered,
      ));
    }
  }

  Future<void> _onLoadPurchaseDetails(
    LoadPurchaseDetails event,
    Emitter<PurchaseState> emit,
  ) async {
    try {
      final purchase = await purchaseRepository.getById(event.id);
      if (purchase == null) {
        throw NotFoundException('Purchase invoice #${event.id} not found.');
      }
      final items = await purchaseRepository.getItemsForPurchase(event.id);

      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(
          selectedPurchase: purchase,
          selectedPurchaseItems: items,
        ));
      } else {
        final suppliers = await _loadSuppliersMap();
        final books = await _loadBooksMap();
        emit(PurchaseLoaded(
          purchases: [purchase],
          filteredPurchases: [purchase],
          suppliers: suppliers,
          books: books,
          selectedPurchase: purchase,
          selectedPurchaseItems: items,
        ));
      }
    } catch (e) {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(
          errorMessage: 'Failed to load purchase details: $e',
          clearSuccess: true,
        ));
      } else {
        emit(PurchaseError('Failed to load purchase details: $e'));
      }
    }
  }

  Future<void> _onCreatePurchase(
    CreatePurchase event,
    Emitter<PurchaseState> emit,
  ) async {
    if (state is PurchaseLoaded) {
      emit((state as PurchaseLoaded).copyWith(isCreating: true));
    }
    try {
      final purchaseId = await purchaseRepository.createPurchaseWithItems(
        purchase: event.purchase,
        items: event.items,
      );

      final purchases = await purchaseRepository.getAll();
      final suppliers = await _loadSuppliersMap();
      final books = await _loadBooksMap();
      final current = state is PurchaseLoaded ? (state as PurchaseLoaded) : null;
      final query = current?.searchQuery ?? '';
      final status = current?.paymentStatusFilter;
      final suppId = current?.supplierFilter;

      final filtered = _applyFilters(
        all: purchases,
        suppliers: suppliers,
        query: query,
        status: status,
        supplierId: suppId,
      );

      emit(PurchaseLoaded(
        purchases: purchases,
        filteredPurchases: filtered,
        suppliers: suppliers,
        books: books,
        searchQuery: query,
        paymentStatusFilter: status,
        supplierFilter: suppId,
        isCreating: false,
        successMessage:
            'Purchase invoice "${event.purchase.invoiceNumber}" saved successfully (ID #$purchaseId). Stock updated.',
      ));
    } on AppException catch (e) {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(
          isCreating: false,
          errorMessage: e.message,
          clearSuccess: true,
        ));
      } else {
        emit(PurchaseError(e.message));
      }
    } catch (e) {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(
          isCreating: false,
          errorMessage: 'Failed to save purchase: $e',
          clearSuccess: true,
        ));
      } else {
        emit(PurchaseError('Failed to save purchase: $e'));
      }
    }
  }

  Future<void> _onDeletePurchase(
    DeletePurchase event,
    Emitter<PurchaseState> emit,
  ) async {
    try {
      await purchaseRepository.delete(event.id);
      final purchases = await purchaseRepository.getAll();
      final suppliers = await _loadSuppliersMap();
      final books = await _loadBooksMap();
      final current = state is PurchaseLoaded ? (state as PurchaseLoaded) : null;
      final query = current?.searchQuery ?? '';
      final status = current?.paymentStatusFilter;
      final suppId = current?.supplierFilter;

      final filtered = _applyFilters(
        all: purchases,
        suppliers: suppliers,
        query: query,
        status: status,
        supplierId: suppId,
      );

      emit(PurchaseLoaded(
        purchases: purchases,
        filteredPurchases: filtered,
        suppliers: suppliers,
        books: books,
        searchQuery: query,
        paymentStatusFilter: status,
        supplierFilter: suppId,
        successMessage:
            'Purchase invoice #ID ${event.id} cancelled. Stock changes were safely reversed.',
      ));
    } on AppException catch (e) {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(
          errorMessage: e.message,
          clearSuccess: true,
        ));
      } else {
        emit(PurchaseError(e.message));
      }
    } catch (e) {
      if (state is PurchaseLoaded) {
        emit((state as PurchaseLoaded).copyWith(
          errorMessage: 'Failed to delete purchase: $e',
          clearSuccess: true,
        ));
      } else {
        emit(PurchaseError('Failed to delete purchase: $e'));
      }
    }
  }

  void _onClearMessages(
    ClearPurchaseMessages event,
    Emitter<PurchaseState> emit,
  ) {
    if (state is PurchaseLoaded) {
      emit((state as PurchaseLoaded)
          .copyWith(clearSuccess: true, clearError: true));
    }
  }
}
