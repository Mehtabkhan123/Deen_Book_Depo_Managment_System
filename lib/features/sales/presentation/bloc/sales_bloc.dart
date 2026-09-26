import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../customers/domain/repositories/customer_repository.dart';
import '../../domain/repositories/sale_repository.dart';

// ==========================================
// Events
// ==========================================
abstract class SalesEvent {
  const SalesEvent();
}

class LoadSales extends SalesEvent {
  const LoadSales();
}

class RefreshSales extends SalesEvent {
  const RefreshSales();
}

class SearchSales extends SalesEvent {
  final String query;
  const SearchSales(this.query);
}

class FilterSales extends SalesEvent {
  final String? paymentStatus;
  final int? customerId;
  final bool? isCashOnly;
  const FilterSales({
    this.paymentStatus,
    this.customerId,
    this.isCashOnly,
  });
}

class LoadSaleDetails extends SalesEvent {
  final int id;
  const LoadSaleDetails(this.id);
}

class CreateSale extends SalesEvent {
  final Sale sale;
  final List<SaleItem> items;
  const CreateSale({
    required this.sale,
    required this.items,
  });
}

class DeleteSale extends SalesEvent {
  final int id;
  const DeleteSale(this.id);
}

class ClearSaleMessages extends SalesEvent {
  const ClearSaleMessages();
}

// ==========================================
// States
// ==========================================
abstract class SalesState {
  const SalesState();
}

class SalesInitial extends SalesState {
  const SalesInitial();
}

class SalesLoading extends SalesState {
  const SalesLoading();
}

class SalesLoaded extends SalesState {
  final List<Sale> sales;
  final List<Sale> filteredSales;
  final Map<int, Customer> customers;
  final Map<int, Book> books;
  final String searchQuery;
  final String? paymentStatusFilter;
  final int? customerFilter;
  final bool isCashOnlyFilter;
  final Sale? selectedSale;
  final List<SaleItem>? selectedSaleItems;
  final bool isCreating;
  final bool isDeleting;
  final String? successMessage;
  final String? errorMessage;

  const SalesLoaded({
    required this.sales,
    required this.filteredSales,
    required this.customers,
    required this.books,
    this.searchQuery = '',
    this.paymentStatusFilter,
    this.customerFilter,
    this.isCashOnlyFilter = false,
    this.selectedSale,
    this.selectedSaleItems,
    this.isCreating = false,
    this.isDeleting = false,
    this.successMessage,
    this.errorMessage,
  });

  String getCustomerName(int? customerId) {
    if (customerId == null) return 'Cash / Walk-in Customer';
    return customers[customerId]?.name ?? 'Customer #$customerId';
  }

  String getCustomerPhone(int? customerId) {
    if (customerId == null) return '--';
    return customers[customerId]?.phone ?? '--';
  }

  String getBookTitle(int bookId) {
    return books[bookId]?.name ?? 'Book #$bookId';
  }

  int get totalSalesCount => sales.length;

  double get totalInvoicedRevenue =>
      sales.fold(0.0, (acc, s) => acc + s.total);

  double get totalPaidAmount =>
      sales.fold(0.0, (acc, s) => acc + s.paidAmount);

  double get totalReceivableAmount =>
      sales.fold(0.0, (acc, s) => acc + s.remainingAmount);

  SalesLoaded copyWith({
    List<Sale>? sales,
    List<Sale>? filteredSales,
    Map<int, Customer>? customers,
    Map<int, Book>? books,
    String? searchQuery,
    String? paymentStatusFilter,
    bool clearPaymentStatus = false,
    int? customerFilter,
    bool clearCustomer = false,
    bool? isCashOnlyFilter,
    Sale? selectedSale,
    bool clearSelectedSale = false,
    List<SaleItem>? selectedSaleItems,
    bool clearSelectedItems = false,
    bool? isCreating,
    bool? isDeleting,
    String? successMessage,
    bool clearSuccess = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SalesLoaded(
      sales: sales ?? this.sales,
      filteredSales: filteredSales ?? this.filteredSales,
      customers: customers ?? this.customers,
      books: books ?? this.books,
      searchQuery: searchQuery ?? this.searchQuery,
      paymentStatusFilter: clearPaymentStatus
          ? null
          : (paymentStatusFilter ?? this.paymentStatusFilter),
      customerFilter:
          clearCustomer ? null : (customerFilter ?? this.customerFilter),
      isCashOnlyFilter: isCashOnlyFilter ?? this.isCashOnlyFilter,
      selectedSale:
          clearSelectedSale ? null : (selectedSale ?? this.selectedSale),
      selectedSaleItems: clearSelectedItems
          ? null
          : (selectedSaleItems ?? this.selectedSaleItems),
      isCreating: isCreating ?? this.isCreating,
      isDeleting: isDeleting ?? this.isDeleting,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SalesError extends SalesState {
  final String message;
  const SalesError(this.message);
}

// ==========================================
// BLoC Implementation
// ==========================================
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SaleRepository saleRepository;
  final CustomerRepository customerRepository;
  final BookRepository bookRepository;

  SalesBloc({
    required this.saleRepository,
    required this.customerRepository,
    required this.bookRepository,
  }) : super(const SalesInitial()) {
    on<LoadSales>(_onLoadSales);
    on<RefreshSales>(_onRefreshSales);
    on<SearchSales>(_onSearchSales);
    on<FilterSales>(_onFilterSales);
    on<LoadSaleDetails>(_onLoadSaleDetails);
    on<CreateSale>(_onCreateSale);
    on<DeleteSale>(_onDeleteSale);
    on<ClearSaleMessages>(_onClearMessages);
  }

  Future<Map<int, Customer>> _loadCustomers() async {
    final list = await customerRepository.getAll();
    return {for (final c in list) if (c.id != null) c.id!: c};
  }

  Future<Map<int, Book>> _loadBooks() async {
    final list = await bookRepository.getAll();
    return {for (final b in list) if (b.id != null) b.id!: b};
  }

  List<Sale> _applyFilters({
    required List<Sale> sales,
    required Map<int, Customer> customers,
    required String query,
    String? paymentStatus,
    int? customerId,
    bool isCashOnly = false,
  }) {
    final trimmed = query.trim().toLowerCase();

    return sales.where((s) {
      // 1. Text Search (invoice number, customer name, notes)
      if (trimmed.isNotEmpty) {
        final invoiceMatches = s.invoiceNumber.toLowerCase().contains(trimmed);
        final notesMatches = (s.notes ?? '').toLowerCase().contains(trimmed);
        final customerName = s.customerId != null
            ? (customers[s.customerId]?.name ?? '').toLowerCase()
            : 'cash walk-in';
        final customerMatches = customerName.contains(trimmed);

        if (!invoiceMatches && !notesMatches && !customerMatches) {
          return false;
        }
      }

      // 2. Payment Status filter
      if (paymentStatus != null &&
          paymentStatus.isNotEmpty &&
          paymentStatus != 'ALL') {
        if (s.paymentStatus.toUpperCase() != paymentStatus.toUpperCase()) {
          return false;
        }
      }

      // 3. Cash-only filter
      if (isCashOnly) {
        if (s.customerId != null) {
          return false;
        }
      } else if (customerId != null) {
        // Specific customer filter
        if (s.customerId != customerId) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _onLoadSales(
    LoadSales event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    try {
      final sales = await saleRepository.getAll();
      final customers = await _loadCustomers();
      final books = await _loadBooks();

      final filtered = _applyFilters(
        sales: sales,
        customers: customers,
        query: '',
      );

      emit(SalesLoaded(
        sales: sales,
        filteredSales: filtered,
        customers: customers,
        books: books,
      ));
    } catch (e) {
      emit(SalesError('Failed to load sales: $e'));
    }
  }

  Future<void> _onRefreshSales(
    RefreshSales event,
    Emitter<SalesState> emit,
  ) async {
    final current = state is SalesLoaded ? (state as SalesLoaded) : null;
    try {
      final sales = await saleRepository.getAll();
      final customers = await _loadCustomers();
      final books = await _loadBooks();

      final filtered = _applyFilters(
        sales: sales,
        customers: customers,
        query: current?.searchQuery ?? '',
        paymentStatus: current?.paymentStatusFilter,
        customerId: current?.customerFilter,
        isCashOnly: current?.isCashOnlyFilter ?? false,
      );

      if (current != null) {
        emit(current.copyWith(
          sales: sales,
          filteredSales: filtered,
          customers: customers,
          books: books,
        ));
      } else {
        emit(SalesLoaded(
          sales: sales,
          filteredSales: filtered,
          customers: customers,
          books: books,
        ));
      }
    } catch (e) {
      emit(SalesError('Failed to refresh sales: $e'));
    }
  }

  void _onSearchSales(
    SearchSales event,
    Emitter<SalesState> emit,
  ) {
    if (state is! SalesLoaded) return;
    final current = state as SalesLoaded;

    final filtered = _applyFilters(
      sales: current.sales,
      customers: current.customers,
      query: event.query,
      paymentStatus: current.paymentStatusFilter,
      customerId: current.customerFilter,
      isCashOnly: current.isCashOnlyFilter,
    );

    emit(current.copyWith(
      searchQuery: event.query,
      filteredSales: filtered,
    ));
  }

  void _onFilterSales(
    FilterSales event,
    Emitter<SalesState> emit,
  ) {
    if (state is! SalesLoaded) return;
    final current = state as SalesLoaded;

    final newStatus = event.paymentStatus ?? current.paymentStatusFilter;
    final newCustomer = event.customerId ??
        (event.isCashOnly == true ? null : current.customerFilter);
    final newCashOnly = event.isCashOnly ?? current.isCashOnlyFilter;

    final filtered = _applyFilters(
      sales: current.sales,
      customers: current.customers,
      query: current.searchQuery,
      paymentStatus: newStatus,
      customerId: newCustomer,
      isCashOnly: newCashOnly,
    );

    emit(current.copyWith(
      paymentStatusFilter: newStatus,
      clearPaymentStatus: newStatus == null || newStatus == 'ALL',
      customerFilter: newCustomer,
      clearCustomer: newCustomer == null,
      isCashOnlyFilter: newCashOnly,
      filteredSales: filtered,
    ));
  }

  Future<void> _onLoadSaleDetails(
    LoadSaleDetails event,
    Emitter<SalesState> emit,
  ) async {
    if (state is! SalesLoaded) return;
    final current = state as SalesLoaded;

    try {
      final sale = await saleRepository.getById(event.id);
      if (sale == null) {
        emit(current.copyWith(
          errorMessage: 'Sales invoice #${event.id} not found.',
        ));
        return;
      }

      final items = await saleRepository.getItemsForSale(event.id);
      final enrichedItems = items.map((item) {
        final bookName = current.books[item.bookId]?.name;
        return item.copyWith(bookName: bookName);
      }).toList();

      emit(current.copyWith(
        selectedSale: sale,
        selectedSaleItems: enrichedItems,
      ));
    } catch (e) {
      emit(current.copyWith(
        errorMessage: 'Failed to load sales invoice items: $e',
      ));
    }
  }

  Future<void> _onCreateSale(
    CreateSale event,
    Emitter<SalesState> emit,
  ) async {
    if (state is! SalesLoaded) return;
    final current = state as SalesLoaded;

    emit(current.copyWith(isCreating: true, clearError: true, clearSuccess: true));

    try {
      final saleId = await saleRepository.createSaleWithItems(
        sale: event.sale,
        items: event.items,
      );

      // Re-fetch all data after successful atomic transaction
      final updatedSales = await saleRepository.getAll();
      final updatedBooks = await _loadBooks();
      final updatedCustomers = await _loadCustomers();

      final filtered = _applyFilters(
        sales: updatedSales,
        customers: updatedCustomers,
        query: current.searchQuery,
        paymentStatus: current.paymentStatusFilter,
        customerId: current.customerFilter,
        isCashOnly: current.isCashOnlyFilter,
      );

      final customerLabel = event.sale.customerId == null
          ? 'Cash / Walk-in'
          : (updatedCustomers[event.sale.customerId]?.name ?? 'Customer');

      emit(current.copyWith(
        sales: updatedSales,
        filteredSales: filtered,
        customers: updatedCustomers,
        books: updatedBooks,
        isCreating: false,
        successMessage:
            'Sale #${event.sale.invoiceNumber} for $customerLabel created successfully (ID: $saleId).',
      ));
    } on InsufficientStockException catch (e) {
      emit(current.copyWith(
        isCreating: false,
        errorMessage:
            'Insufficient stock for "${e.bookName}". Available: ${e.availableStock}, Requested: ${e.requestedQuantity}.',
      ));
    } on DuplicateInvoiceException catch (e) {
      emit(current.copyWith(
        isCreating: false,
        errorMessage:
            'Duplicate invoice number "${e.invoiceNumber}". Please enter a unique invoice number.',
      ));
    } on ValidationException catch (e) {
      emit(current.copyWith(
        isCreating: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(current.copyWith(
        isCreating: false,
        errorMessage: 'Failed to create sale invoice: $e',
      ));
    }
  }

  Future<void> _onDeleteSale(
    DeleteSale event,
    Emitter<SalesState> emit,
  ) async {
    if (state is! SalesLoaded) return;
    final current = state as SalesLoaded;

    emit(current.copyWith(isDeleting: true, clearError: true, clearSuccess: true));

    try {
      final success = await saleRepository.delete(event.id);
      if (!success) {
        emit(current.copyWith(
          isDeleting: false,
          errorMessage: 'Could not reverse sale #${event.id}.',
        ));
        return;
      }

      final updatedSales = await saleRepository.getAll();
      final updatedBooks = await _loadBooks();
      final updatedCustomers = await _loadCustomers();

      final filtered = _applyFilters(
        sales: updatedSales,
        customers: updatedCustomers,
        query: current.searchQuery,
        paymentStatus: current.paymentStatusFilter,
        customerId: current.customerFilter,
        isCashOnly: current.isCashOnlyFilter,
      );

      emit(current.copyWith(
        sales: updatedSales,
        filteredSales: filtered,
        customers: updatedCustomers,
        books: updatedBooks,
        isDeleting: false,
        successMessage:
            'Sale invoice #${event.id} cancelled. Stock restored and customer ledger updated.',
      ));
    } catch (e) {
      emit(current.copyWith(
        isDeleting: false,
        errorMessage: 'Failed to cancel sale invoice: $e',
      ));
    }
  }

  void _onClearMessages(
    ClearSaleMessages event,
    Emitter<SalesState> emit,
  ) {
    if (state is! SalesLoaded) return;
    final current = state as SalesLoaded;
    emit(current.copyWith(clearSuccess: true, clearError: true));
  }
}
