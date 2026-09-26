import '../../../../shared/models/book.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/sale.dart';

/// Summary metrics container for the professional bookstore dashboard
class DashboardMetrics {
  // Catalog & Inventory
  final int totalBooks;
  final int currentStock;
  final int lowStockCount;
  final int outOfStockCount;

  // Today's Operations
  final int todaySalesCount;
  final double todaySalesTotal;
  final int todayPurchasesCount;
  final double todayPurchasesTotal;
  final int todayCustomerPaymentsCount;
  final double todayCustomerPaymentsTotal;
  final int todaySupplierPaymentsCount;
  final double todaySupplierPaymentsTotal;
  final int todayExpensesCount;
  final double todayExpensesTotal;

  // Ledger Balances
  final double customerReceivables;
  final double supplierPayables;

  // Recent Activities & Alerts
  final List<Sale> recentSales;
  final List<Purchase> recentPurchases;
  final List<Book> lowStockBooks;
  final Map<int, String> customerNames;
  final Map<int, String> supplierNames;

  const DashboardMetrics({
    this.totalBooks = 0,
    this.currentStock = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.todaySalesCount = 0,
    this.todaySalesTotal = 0.0,
    this.todayPurchasesCount = 0,
    this.todayPurchasesTotal = 0.0,
    this.todayCustomerPaymentsCount = 0,
    this.todayCustomerPaymentsTotal = 0.0,
    this.todaySupplierPaymentsCount = 0,
    this.todaySupplierPaymentsTotal = 0.0,
    this.todayExpensesCount = 0,
    this.todayExpensesTotal = 0.0,
    this.customerReceivables = 0.0,
    this.supplierPayables = 0.0,
    this.recentSales = const [],
    this.recentPurchases = const [],
    this.lowStockBooks = const [],
    this.customerNames = const {},
    this.supplierNames = const {},
  });
}

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardMetrics metrics;

  const DashboardLoaded(this.metrics);
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);
}
