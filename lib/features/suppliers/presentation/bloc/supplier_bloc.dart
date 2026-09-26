import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/services/supplier_ledger_service.dart';

// ==========================================
// Events
// ==========================================
abstract class SupplierEvent {
  const SupplierEvent();
}

class LoadSuppliers extends SupplierEvent {
  const LoadSuppliers();
}

class RefreshSuppliers extends SupplierEvent {
  const RefreshSuppliers();
}

class SearchSuppliers extends SupplierEvent {
  final String query;
  const SearchSuppliers(this.query);
}

class AddSupplier extends SupplierEvent {
  final Supplier supplier;
  const AddSupplier(this.supplier);
}

class UpdateSupplier extends SupplierEvent {
  final Supplier supplier;
  const UpdateSupplier(this.supplier);
}

class DeleteSupplier extends SupplierEvent {
  final int id;
  const DeleteSupplier(this.id);
}

class LoadSupplierDetails extends SupplierEvent {
  final int id;
  const LoadSupplierDetails(this.id);
}

class ClearSupplierMessages extends SupplierEvent {
  const ClearSupplierMessages();
}

// ==========================================
// States
// ==========================================
abstract class SupplierState {
  const SupplierState();
}

class SupplierInitial extends SupplierState {
  const SupplierInitial();
}

class SupplierLoading extends SupplierState {
  const SupplierLoading();
}

class SupplierLoaded extends SupplierState {
  final List<Supplier> suppliers;
  final Map<int, double> balances;
  final String searchQuery;
  final Supplier? selectedSupplier;
  final double? selectedSupplierBalance;
  final String? successMessage;
  final String? errorMessage;

  const SupplierLoaded(
    this.suppliers, {
    this.balances = const {},
    this.searchQuery = '',
    this.selectedSupplier,
    this.selectedSupplierBalance,
    this.successMessage,
    this.errorMessage,
  });

  double getBalance(int? id) {
    if (id == null) return 0.0;
    return balances[id] ?? 0.0;
  }

  SupplierLoaded copyWith({
    List<Supplier>? suppliers,
    Map<int, double>? balances,
    String? searchQuery,
    Supplier? selectedSupplier,
    double? selectedSupplierBalance,
    bool clearSelected = false,
    String? successMessage,
    String? errorMessage,
    bool clearSuccess = false,
    bool clearError = false,
  }) {
    return SupplierLoaded(
      suppliers ?? this.suppliers,
      balances: balances ?? this.balances,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSupplier:
          clearSelected ? null : (selectedSupplier ?? this.selectedSupplier),
      selectedSupplierBalance: clearSelected
          ? null
          : (selectedSupplierBalance ?? this.selectedSupplierBalance),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SupplierError extends SupplierState {
  final String message;
  const SupplierError(this.message);
}

// ==========================================
// BLoC
// ==========================================
class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final SupplierRepository supplierRepository;
  final SupplierLedgerService? ledgerService;

  SupplierBloc({
    required this.supplierRepository,
    this.ledgerService,
  }) : super(const SupplierInitial()) {
    on<LoadSuppliers>(_onLoadSuppliers);
    on<RefreshSuppliers>(_onRefreshSuppliers);
    on<SearchSuppliers>(_onSearchSuppliers);
    on<AddSupplier>(_onAddSupplier);
    on<UpdateSupplier>(_onUpdateSupplier);
    on<DeleteSupplier>(_onDeleteSupplier);
    on<LoadSupplierDetails>(_onLoadSupplierDetails);
    on<ClearSupplierMessages>(_onClearMessages);
  }

  Future<Map<int, double>> _loadBalances(List<Supplier> suppliers) async {
    final Map<int, double> balances = {};
    for (final s in suppliers) {
      if (s.id != null) {
        if (ledgerService != null) {
          try {
            balances[s.id!] = await ledgerService!.getSupplierBalance(s.id!);
          } catch (_) {
            balances[s.id!] = s.openingBalance;
          }
        } else {
          balances[s.id!] = s.openingBalance;
        }
      }
    }
    return balances;
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    emit(const SupplierLoading());
    try {
      final suppliers = await supplierRepository.getAll();
      final balances = await _loadBalances(suppliers);
      emit(SupplierLoaded(suppliers, balances: balances));
    } catch (e) {
      emit(SupplierError('Failed to load suppliers: $e'));
    }
  }

  Future<void> _onRefreshSuppliers(
    RefreshSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    final currentQuery =
        state is SupplierLoaded ? (state as SupplierLoaded).searchQuery : '';
    try {
      final suppliers = currentQuery.isEmpty
          ? await supplierRepository.getAll()
          : await supplierRepository.search(currentQuery);
      final balances = await _loadBalances(suppliers);
      emit(SupplierLoaded(
        suppliers,
        balances: balances,
        searchQuery: currentQuery,
      ));
    } catch (e) {
      emit(SupplierError('Failed to refresh suppliers: $e'));
    }
  }

  Future<void> _onSearchSuppliers(
    SearchSuppliers event,
    Emitter<SupplierState> emit,
  ) async {
    emit(const SupplierLoading());
    try {
      final suppliers = await supplierRepository.search(event.query);
      final balances = await _loadBalances(suppliers);
      emit(SupplierLoaded(
        suppliers,
        balances: balances,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(SupplierError('Failed to search suppliers: $e'));
    }
  }

  Future<void> _onAddSupplier(
    AddSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      await supplierRepository.create(event.supplier);
      final currentQuery =
          state is SupplierLoaded ? (state as SupplierLoaded).searchQuery : '';
      final suppliers = currentQuery.isEmpty
          ? await supplierRepository.getAll()
          : await supplierRepository.search(currentQuery);
      final balances = await _loadBalances(suppliers);
      emit(SupplierLoaded(
        suppliers,
        balances: balances,
        searchQuery: currentQuery,
        successMessage:
            'Supplier "${event.supplier.name}" created successfully.',
      ));
    } on AppException catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded)
            .copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(SupplierError(e.message));
      }
    } catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded).copyWith(
            errorMessage: 'Failed to create supplier: $e',
            clearSuccess: true));
      } else {
        emit(SupplierError('Failed to create supplier: $e'));
      }
    }
  }

  Future<void> _onUpdateSupplier(
    UpdateSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      await supplierRepository.update(event.supplier);
      final currentQuery =
          state is SupplierLoaded ? (state as SupplierLoaded).searchQuery : '';
      final suppliers = currentQuery.isEmpty
          ? await supplierRepository.getAll()
          : await supplierRepository.search(currentQuery);
      final balances = await _loadBalances(suppliers);
      emit(SupplierLoaded(
        suppliers,
        balances: balances,
        searchQuery: currentQuery,
        successMessage:
            'Supplier "${event.supplier.name}" updated successfully.',
      ));
    } on AppException catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded)
            .copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(SupplierError(e.message));
      }
    } catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded).copyWith(
            errorMessage: 'Failed to update supplier: $e',
            clearSuccess: true));
      } else {
        emit(SupplierError('Failed to update supplier: $e'));
      }
    }
  }

  Future<void> _onDeleteSupplier(
    DeleteSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      await supplierRepository.delete(event.id);
      final currentQuery =
          state is SupplierLoaded ? (state as SupplierLoaded).searchQuery : '';
      final suppliers = currentQuery.isEmpty
          ? await supplierRepository.getAll()
          : await supplierRepository.search(currentQuery);
      final balances = await _loadBalances(suppliers);
      emit(SupplierLoaded(
        suppliers,
        balances: balances,
        searchQuery: currentQuery,
        successMessage: 'Supplier deleted successfully.',
      ));
    } on AppException catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded)
            .copyWith(errorMessage: e.message, clearSuccess: true));
      } else {
        emit(SupplierError(e.message));
      }
    } catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded).copyWith(
            errorMessage: 'Failed to delete supplier: $e',
            clearSuccess: true));
      } else {
        emit(SupplierError('Failed to delete supplier: $e'));
      }
    }
  }

  Future<void> _onLoadSupplierDetails(
    LoadSupplierDetails event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      final supplier = await supplierRepository.getById(event.id);
      if (supplier == null) {
        throw NotFoundException('Supplier with ID ${event.id} not found.');
      }
      double balance = supplier.openingBalance;
      if (ledgerService != null) {
        balance = await ledgerService!.getSupplierBalance(event.id);
      }
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded).copyWith(
          selectedSupplier: supplier,
          selectedSupplierBalance: balance,
        ));
      }
    } catch (e) {
      if (state is SupplierLoaded) {
        emit((state as SupplierLoaded).copyWith(
            errorMessage: 'Failed to load supplier details: $e',
            clearSuccess: true));
      } else {
        emit(SupplierError('Failed to load supplier details: $e'));
      }
    }
  }

  void _onClearMessages(
    ClearSupplierMessages event,
    Emitter<SupplierState> emit,
  ) {
    if (state is SupplierLoaded) {
      emit((state as SupplierLoaded)
          .copyWith(clearSuccess: true, clearError: true));
    }
  }
}
