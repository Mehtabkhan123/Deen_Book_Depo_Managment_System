import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../customers/domain/repositories/customer_repository.dart';
import '../../../customers/domain/services/customer_ledger_service.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../payments/domain/repositories/customer_payment_repository.dart';
import '../../../payments/domain/repositories/supplier_payment_repository.dart';
import '../../../purchases/domain/repositories/purchase_repository.dart';
import '../../../sales/domain/repositories/sale_repository.dart';
import '../../../suppliers/domain/repositories/supplier_repository.dart';
import '../../../suppliers/domain/services/supplier_ledger_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

export 'dashboard_event.dart';
export 'dashboard_state.dart';

/// BLoC responsible for aggregating business metrics and activity logs for the bookstore dashboard
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final BookRepository bookRepository;
  final SaleRepository saleRepository;
  final PurchaseRepository purchaseRepository;
  final CustomerRepository customerRepository;
  final SupplierRepository supplierRepository;
  final CustomerLedgerService customerLedgerService;
  final SupplierLedgerService supplierLedgerService;
  final DatabaseHelper? databaseHelper;
  final ExpenseRepository? expenseRepository;
  final CustomerPaymentRepository? customerPaymentRepository;
  final SupplierPaymentRepository? supplierPaymentRepository;

  DashboardBloc({
    required this.bookRepository,
    required this.saleRepository,
    required this.purchaseRepository,
    required this.customerRepository,
    required this.supplierRepository,
    required this.customerLedgerService,
    required this.supplierLedgerService,
    this.databaseHelper,
    this.expenseRepository,
    this.customerPaymentRepository,
    this.supplierPaymentRepository,
  }) : super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _fetchAndEmitMetrics(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchAndEmitMetrics(emit);
  }

  Future<void> _fetchAndEmitMetrics(Emitter<DashboardState> emit) async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final db = databaseHelper ??
          (Injection.instance.isInitialized ? Injection.instance.databaseHelper : null);

      int totalBooks = 0;
      int currentStock = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;

      int todaySalesCount = 0;
      double todaySalesTotal = 0.0;

      int todayPurchasesCount = 0;
      double todayPurchasesTotal = 0.0;

      int todayCustomerPaymentsCount = 0;
      double todayCustomerPaymentsTotal = 0.0;

      int todaySupplierPaymentsCount = 0;
      double todaySupplierPaymentsTotal = 0.0;

      int todayExpensesCount = 0;
      double todayExpensesTotal = 0.0;

      if (db != null) {
        // 1. Books & stock count via SQLite
        final bookStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as total_books,
            COALESCE(SUM(${DbConstants.colBookStockQuantity}), 0) as current_stock,
            COUNT(CASE WHEN ${DbConstants.colBookStockQuantity} <= ${DbConstants.colBookMinimumStock} AND ${DbConstants.colBookStockQuantity} > 0 THEN 1 END) as low_stock_count,
            COUNT(CASE WHEN ${DbConstants.colBookStockQuantity} <= 0 THEN 1 END) as out_of_stock_count
          FROM ${DbConstants.tableBooks}
        ''');
        if (bookStats.isNotEmpty) {
          totalBooks = (bookStats.first['total_books'] as num?)?.toInt() ?? 0;
          currentStock = (bookStats.first['current_stock'] as num?)?.toInt() ?? 0;
          lowStockCount = (bookStats.first['low_stock_count'] as num?)?.toInt() ?? 0;
          outOfStockCount = (bookStats.first['out_of_stock_count'] as num?)?.toInt() ?? 0;
        }

        // 2. Today's Sales via SQLite
        final salesStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as count,
            COALESCE(SUM(${DbConstants.colSaleTotal}), 0.0) as total
          FROM ${DbConstants.tableSales}
          WHERE ${DbConstants.colSaleDate} LIKE ?
        ''', ['$todayStr%']);
        if (salesStats.isNotEmpty) {
          todaySalesCount = (salesStats.first['count'] as num?)?.toInt() ?? 0;
          todaySalesTotal = (salesStats.first['total'] as num?)?.toDouble() ?? 0.0;
        }

        // 3. Today's Purchases via SQLite
        final purchaseStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as count,
            COALESCE(SUM(${DbConstants.colPurchaseTotal}), 0.0) as total
          FROM ${DbConstants.tablePurchases}
          WHERE ${DbConstants.colPurchaseDate} LIKE ?
        ''', ['$todayStr%']);
        if (purchaseStats.isNotEmpty) {
          todayPurchasesCount = (purchaseStats.first['count'] as num?)?.toInt() ?? 0;
          todayPurchasesTotal = (purchaseStats.first['total'] as num?)?.toDouble() ?? 0.0;
        }

        // 4. Today's Customer Payments via SQLite
        final custPayStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as count,
            COALESCE(SUM(${DbConstants.colCustPaymentAmount}), 0.0) as total
          FROM ${DbConstants.tableCustomerPayments}
          WHERE ${DbConstants.colCustPaymentDate} LIKE ?
        ''', ['$todayStr%']);
        if (custPayStats.isNotEmpty) {
          todayCustomerPaymentsCount = (custPayStats.first['count'] as num?)?.toInt() ?? 0;
          todayCustomerPaymentsTotal = (custPayStats.first['total'] as num?)?.toDouble() ?? 0.0;
        }

        // 5. Today's Supplier Payments via SQLite
        final suppPayStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as count,
            COALESCE(SUM(${DbConstants.colSuppPaymentAmount}), 0.0) as total
          FROM ${DbConstants.tableSupplierPayments}
          WHERE ${DbConstants.colSuppPaymentDate} LIKE ?
        ''', ['$todayStr%']);
        if (suppPayStats.isNotEmpty) {
          todaySupplierPaymentsCount = (suppPayStats.first['count'] as num?)?.toInt() ?? 0;
          todaySupplierPaymentsTotal = (suppPayStats.first['total'] as num?)?.toDouble() ?? 0.0;
        }

        // 6. Today's Expenses via SQLite
        final expStats = await db.rawQuery('''
          SELECT 
            COUNT(*) as count,
            COALESCE(SUM(${DbConstants.colExpenseAmount}), 0.0) as total
          FROM ${DbConstants.tableExpenses}
          WHERE ${DbConstants.colExpenseDate} LIKE ?
        ''', ['$todayStr%']);
        if (expStats.isNotEmpty) {
          todayExpensesCount = (expStats.first['count'] as num?)?.toInt() ?? 0;
          todayExpensesTotal = (expStats.first['total'] as num?)?.toDouble() ?? 0.0;
        }
      } else {
        // Fallback for isolated unit tests where db is not passed
        final allBooks = await bookRepository.getAll();
        totalBooks = allBooks.length;
        currentStock = allBooks.fold<int>(0, (sum, b) => sum + b.stockQuantity);
        lowStockCount = allBooks
            .where((b) => b.stockQuantity <= b.minimumStock && b.stockQuantity > 0)
            .length;
        outOfStockCount = allBooks.where((b) => b.stockQuantity <= 0).length;

        final recentSales = await saleRepository.getAll(limit: 100);
        final todaySales =
            recentSales.where((s) => s.saleDate.startsWith(todayStr)).toList();
        todaySalesCount = todaySales.length;
        todaySalesTotal = todaySales.fold<double>(0.0, (sum, s) => sum + s.total);

        final recentPurchases = await purchaseRepository.getAll(limit: 100);
        final todayPurchases =
            recentPurchases.where((p) => p.purchaseDate.startsWith(todayStr)).toList();
        todayPurchasesCount = todayPurchases.length;
        todayPurchasesTotal =
            todayPurchases.fold<double>(0.0, (sum, p) => sum + p.total);
      }

      // 7. Recent 10 Sales & Recent 10 Purchases (Limit 10 ORDER BY date DESC)
      final recentSales = await saleRepository.getAll(limit: 10);
      final recentPurchases = await purchaseRepository.getAll(limit: 10);
      final lowStockBooks = await bookRepository.getLowStockBooks();

      // 8. Receivables & Payables via domain ledger services (do not duplicate balance calculations)
      final allCustomers = await customerRepository.getAll();
      final customerNames = <int, String>{};
      double totalReceivables = 0.0;
      for (final customer in allCustomers) {
        if (customer.id != null) {
          customerNames[customer.id!] = customer.name;
          final balance =
              await customerLedgerService.getCustomerBalance(customer.id!);
          if (balance > 0) totalReceivables += balance;
        }
      }

      final allSuppliers = await supplierRepository.getAll();
      final supplierNames = <int, String>{};
      double totalPayables = 0.0;
      for (final supplier in allSuppliers) {
        if (supplier.id != null) {
          supplierNames[supplier.id!] = supplier.name;
          final balance =
              await supplierLedgerService.getSupplierBalance(supplier.id!);
          if (balance > 0) totalPayables += balance;
        }
      }

      final metrics = DashboardMetrics(
        totalBooks: totalBooks,
        currentStock: currentStock,
        lowStockCount: lowStockCount,
        outOfStockCount: outOfStockCount,
        todaySalesCount: todaySalesCount,
        todaySalesTotal: todaySalesTotal,
        todayPurchasesCount: todayPurchasesCount,
        todayPurchasesTotal: todayPurchasesTotal,
        todayCustomerPaymentsCount: todayCustomerPaymentsCount,
        todayCustomerPaymentsTotal: todayCustomerPaymentsTotal,
        todaySupplierPaymentsCount: todaySupplierPaymentsCount,
        todaySupplierPaymentsTotal: todaySupplierPaymentsTotal,
        todayExpensesCount: todayExpensesCount,
        todayExpensesTotal: todayExpensesTotal,
        customerReceivables: totalReceivables,
        supplierPayables: totalPayables,
        recentSales: recentSales,
        recentPurchases: recentPurchases,
        lowStockBooks: lowStockBooks,
        customerNames: customerNames,
        supplierNames: supplierNames,
      );

      emit(DashboardLoaded(metrics));
    } catch (e, stack) {
      AppLogger.error('Failed to load dashboard metrics: $e', e, stack);
      emit(DashboardError('Failed to load real-time metrics: $e'));
    }
  }
}
