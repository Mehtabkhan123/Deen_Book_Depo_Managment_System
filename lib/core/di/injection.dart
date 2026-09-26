import '../database/database_helper.dart';
import '../database/database_service.dart';
import '../../features/repositories.dart';
import '../../features/services.dart';

/// Centralized Dependency Injection Container for the Offline Wholesale Book Management System
class Injection {
  Injection._();

  static final Injection instance = Injection._();

  late DatabaseService databaseService;
  late DatabaseHelper databaseHelper;

  // Repositories
  late CategoryRepository categoryRepository;
  late BookRepository bookRepository;
  late CustomerRepository customerRepository;
  late SupplierRepository supplierRepository;
  late PurchaseRepository purchaseRepository;
  late SaleRepository saleRepository;
  late CustomerPaymentRepository customerPaymentRepository;
  late SupplierPaymentRepository supplierPaymentRepository;
  late StockMovementRepository stockMovementRepository;
  late ExpenseRepository expenseRepository;

  // Services
  late StockService stockService;
  late CustomerLedgerService customerLedgerService;
  late SupplierLedgerService supplierLedgerService;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initializes all single-instance database connections, repositories, and services
  Future<void> init({String? overrideDbPath}) async {
    if (_initialized) return;

    // 1. Core Database
    databaseService = DatabaseService.instance;
    await databaseService.init(overridePath: overrideDbPath);
    databaseHelper = DatabaseHelper(databaseService);

    // 2. Base Repositories
    categoryRepository = SqliteCategoryRepository(databaseHelper);
    bookRepository = SqliteBookRepository(databaseHelper);
    customerRepository = SqliteCustomerRepository(databaseHelper);
    supplierRepository = SqliteSupplierRepository(databaseHelper);
    customerPaymentRepository = SqliteCustomerPaymentRepository(databaseHelper);
    supplierPaymentRepository = SqliteSupplierPaymentRepository(databaseHelper);
    stockMovementRepository = SqliteStockMovementRepository(databaseHelper);
    expenseRepository = SqliteExpenseRepository(databaseHelper);

    // 3. Core Business Services
    stockService = InventoryStockService(
      bookRepository: bookRepository,
      movementRepository: stockMovementRepository,
      dbHelper: databaseHelper,
    );

    customerLedgerService = CustomerLedgerServiceImpl(
      customerRepository: customerRepository,
      dbHelper: databaseHelper,
    );

    supplierLedgerService = SupplierLedgerServiceImpl(
      supplierRepository: supplierRepository,
      dbHelper: databaseHelper,
    );

    // 4. Composite Repositories (requiring business services)
    purchaseRepository = SqlitePurchaseRepository(
      stockService: stockService,
      dbHelper: databaseHelper,
    );

    saleRepository = SqliteSaleRepository(
      bookRepository: bookRepository,
      stockService: stockService,
      dbHelper: databaseHelper,
    );

    _initialized = true;
  }

  /// Resets dependencies for testing purposes
  void reset() {
    _initialized = false;
  }
}
