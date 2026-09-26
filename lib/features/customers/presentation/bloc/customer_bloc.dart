import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/customer_ledger_service.dart';

// ==========================================
// Events
// ==========================================
abstract class CustomerEvent {
  const CustomerEvent();
}

class LoadCustomers extends CustomerEvent {
  const LoadCustomers();
}

class RefreshCustomers extends CustomerEvent {
  const RefreshCustomers();
}

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers(this.query);
}

class AddCustomer extends CustomerEvent {
  final Customer customer;
  const AddCustomer(this.customer);
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;
  const UpdateCustomer(this.customer);
}

class DeleteCustomer extends CustomerEvent {
  final int id;
  const DeleteCustomer(this.id);
}

class LoadCustomerDetails extends CustomerEvent {
  final int id;
  const LoadCustomerDetails(this.id);
}

class ClearCustomerMessages extends CustomerEvent {
  const ClearCustomerMessages();
}

// ==========================================
// States
// ==========================================
abstract class CustomerState {
  const CustomerState();
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  final Map<int, double> balances;
  final String searchQuery;
  final Customer? selectedCustomer;
  final double? selectedCustomerBalance;
  final String? successMessage;
  final String? errorMessage;

  const CustomerLoaded(
    this.customers, {
    this.balances = const {},
    this.searchQuery = '',
    this.selectedCustomer,
    this.selectedCustomerBalance,
    this.successMessage,
    this.errorMessage,
  });

  double getBalance(int? id) {
    if (id == null) return 0.0;
    return balances[id] ?? 0.0;
  }

  CustomerLoaded copyWith({
    List<Customer>? customers,
    Map<int, double>? balances,
    String? searchQuery,
    Customer? selectedCustomer,
    double? selectedCustomerBalance,
    bool clearSelected = false,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return CustomerLoaded(
      customers ?? this.customers,
      balances: balances ?? this.balances,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCustomer:
          clearSelected ? null : (selectedCustomer ?? this.selectedCustomer),
      selectedCustomerBalance: clearSelected
          ? null
          : (selectedCustomerBalance ?? this.selectedCustomerBalance),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);
}

// ==========================================
// BLoC
// ==========================================
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository customerRepository;
  final CustomerLedgerService? ledgerService;

  CustomerBloc({
    required this.customerRepository,
    this.ledgerService,
  }) : super(const CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<RefreshCustomers>(_onRefreshCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<LoadCustomerDetails>(_onLoadCustomerDetails);
    on<ClearCustomerMessages>(_onClearMessages);
  }

  Future<Map<int, double>> _loadBalances(List<Customer> customers) async {
    final Map<int, double> balances = {};
    for (final c in customers) {
      if (c.id != null) {
        if (ledgerService != null) {
          try {
            balances[c.id!] = await ledgerService!.getCustomerBalance(c.id!);
          } catch (_) {
            balances[c.id!] = c.openingBalance;
          }
        } else {
          balances[c.id!] = c.openingBalance;
        }
      }
    }
    return balances;
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(const CustomerLoading());
    try {
      final customers = await customerRepository.getAll();
      final balances = await _loadBalances(customers);
      emit(CustomerLoaded(customers, balances: balances));
    } catch (e) {
      emit(CustomerError('Failed to load customers: $e'));
    }
  }

  Future<void> _onRefreshCustomers(
    RefreshCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    final currentQuery =
        state is CustomerLoaded ? (state as CustomerLoaded).searchQuery : '';
    try {
      final customers = currentQuery.isEmpty
          ? await customerRepository.getAll()
          : await customerRepository.search(currentQuery);
      final balances = await _loadBalances(customers);
      emit(CustomerLoaded(
        customers,
        balances: balances,
        searchQuery: currentQuery,
      ));
    } catch (e) {
      emit(CustomerError('Failed to refresh customers: $e'));
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(const CustomerLoading());
    try {
      final customers = await customerRepository.search(event.query);
      final balances = await _loadBalances(customers);
      emit(CustomerLoaded(
        customers,
        balances: balances,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(CustomerError('Failed to search customers: $e'));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerRepository.create(event.customer);
      final currentQuery =
          state is CustomerLoaded ? (state as CustomerLoaded).searchQuery : '';
      final customers = currentQuery.isEmpty
          ? await customerRepository.getAll()
          : await customerRepository.search(currentQuery);
      final balances = await _loadBalances(customers);
      emit(CustomerLoaded(
        customers,
        balances: balances,
        searchQuery: currentQuery,
        successMessage:
            'Customer "${event.customer.name}" created successfully.',
      ));
    } on AppException catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded)
            .copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(CustomerError(e.message));
      }
    } catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded).copyWith(
            errorMessage: 'Failed to create customer: $e',
            clearSuccess: true));
      } else {
        emit(CustomerError('Failed to create customer: $e'));
      }
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerRepository.update(event.customer);
      final currentQuery =
          state is CustomerLoaded ? (state as CustomerLoaded).searchQuery : '';
      final customers = currentQuery.isEmpty
          ? await customerRepository.getAll()
          : await customerRepository.search(currentQuery);
      final balances = await _loadBalances(customers);
      emit(CustomerLoaded(
        customers,
        balances: balances,
        searchQuery: currentQuery,
        successMessage:
            'Customer "${event.customer.name}" updated successfully.',
      ));
    } on AppException catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded)
            .copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(CustomerError(e.message));
      }
    } catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded).copyWith(
            errorMessage: 'Failed to update customer: $e',
            clearSuccess: true));
      } else {
        emit(CustomerError('Failed to update customer: $e'));
      }
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await customerRepository.delete(event.id);
      final currentQuery =
          state is CustomerLoaded ? (state as CustomerLoaded).searchQuery : '';
      final customers = currentQuery.isEmpty
          ? await customerRepository.getAll()
          : await customerRepository.search(currentQuery);
      final balances = await _loadBalances(customers);
      emit(CustomerLoaded(
        customers,
        balances: balances,
        searchQuery: currentQuery,
        successMessage: 'Customer deleted successfully.',
      ));
    } on AppException catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded)
            .copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(CustomerError(e.message));
      }
    } catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded).copyWith(
            errorMessage: 'Failed to delete customer: $e',
            clearSuccess: true));
      } else {
        emit(CustomerError('Failed to delete customer: $e'));
      }
    }
  }

  Future<void> _onLoadCustomerDetails(
    LoadCustomerDetails event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final customer = await customerRepository.getById(event.id);
      if (customer == null) {
        throw NotFoundException('Customer with ID ${event.id} not found.');
      }
      double balance = customer.openingBalance;
      if (ledgerService != null) {
        balance = await ledgerService!.getCustomerBalance(event.id);
      }
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded).copyWith(
          selectedCustomer: customer,
          selectedCustomerBalance: balance,
        ));
      }
    } catch (e) {
      if (state is CustomerLoaded) {
        emit((state as CustomerLoaded).copyWith(
            errorMessage: 'Failed to load customer details: $e',
            clearSuccess: true));
      } else {
        emit(CustomerError('Failed to load customer details: $e'));
      }
    }
  }

  void _onClearMessages(
    ClearCustomerMessages event,
    Emitter<CustomerState> emit,
  ) {
    if (state is CustomerLoaded) {
      emit((state as CustomerLoaded)
          .copyWith(clearSuccess: true, clearError: true));
    }
  }
}
