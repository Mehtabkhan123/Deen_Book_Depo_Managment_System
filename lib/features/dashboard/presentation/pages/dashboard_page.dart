import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../navigation/presentation/bloc/navigation_bloc.dart';
import '../bloc/dashboard_bloc.dart';

/// Professional offline Windows Desktop Dashboard page powered by DashboardBloc
class DashboardPage extends StatefulWidget {
  final VoidCallback? onNewSale;
  final VoidCallback? onNewPurchase;
  final VoidCallback? onAddBook;
  final VoidCallback? onAddCustomer;
  final VoidCallback? onAddSupplier;

  const DashboardPage({
    super.key,
    this.onNewSale,
    this.onNewPurchase,
    this.onAddBook,
    this.onAddCustomer,
    this.onAddSupplier,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial metrics load if not already initialized
    final bloc = context.read<DashboardBloc>();
    if (bloc.state is DashboardInitial) {
      bloc.add(const LoadDashboard());
    }
  }

  void _handleQuickAction(String destinationId, VoidCallback? customCallback) {
    if (customCallback != null) {
      customCallback();
      return;
    }
    try {
      context.read<NavigationBloc>().add(NavigateTo(destinationId));
    } catch (_) {
      // In isolated tests where NavigationBloc might not be present in tree
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const LoadingIndicator(
              message: 'Loading bookstore metrics from local database...',
            );
          }

          if (state is DashboardError) {
            return ErrorState(
              title: 'Failed to load Dashboard',
              message: state.message,
              onRetry: () =>
                  context.read<DashboardBloc>().add(const LoadDashboard()),
            );
          }

          if (state is DashboardLoaded) {
            return _buildDashboardContent(context, state.metrics);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardMetrics metrics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header with Refresh Action
          PageHeader(
            title: 'Bookstore Dashboard',
            subtitle:
                'Real-time inventory intelligence, daily wholesale transactions, and financial position.',
            actions: [
              AppButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => context
                    .read<DashboardBloc>()
                    .add(const RefreshDashboard()),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions Bar
          _buildQuickActionsBar(context),
          const SizedBox(height: 24),

          // Section 1: Today's Performance (5 Cards)
          _buildSectionHeader(
            title: "Today's Business Operations",
            subtitle: 'Real-time billing, inward shipments, receipts, and expenses recorded today',
            icon: Icons.today_rounded,
          ),
          const SizedBox(height: 12),
          _buildTodayGrid(metrics),
          const SizedBox(height: 28),

          // Section 2: Catalog & Financial Balances (6 Cards)
          _buildSectionHeader(
            title: 'Inventory & Financial Health',
            subtitle: 'Warehouse stock volume, low/out-of-stock items, and ledger balances',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 12),
          _buildInventoryAndFinancialGrid(metrics),
          const SizedBox(height: 28),

          // Section 3: Low & Out-of-Stock Alerts
          _buildLowStockAlertsCard(metrics),
          const SizedBox(height: 24),

          // Section 4: Recent 10 Sales & Recent 10 Purchases (2 Columns)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRecentSalesCard(metrics)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildRecentPurchasesCard(metrics)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRecentSalesCard(metrics),
                    const SizedBox(height: 20),
                    _buildRecentPurchasesCard(metrics),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Quick Actions:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppButton(
            label: 'New Sale',
            icon: Icons.point_of_sale_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () => _handleQuickAction(
              AppDestinations.sales,
              widget.onNewSale,
            ),
          ),
          AppButton(
            label: 'New Purchase',
            icon: Icons.shopping_bag_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => _handleQuickAction(
              AppDestinations.purchases,
              widget.onNewPurchase,
            ),
          ),
          AppButton(
            label: 'Add Book',
            icon: Icons.menu_book_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () => _handleQuickAction(
              AppDestinations.books,
              widget.onAddBook,
            ),
          ),
          AppButton(
            label: 'Add Customer',
            icon: Icons.person_add_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () => _handleQuickAction(
              AppDestinations.customers,
              widget.onAddCustomer,
            ),
          ),
          AppButton(
            label: 'Add Supplier',
            icon: Icons.local_shipping_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () => _handleQuickAction(
              AppDestinations.suppliers,
              widget.onAddSupplier,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayGrid(DashboardMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 5
            : (constraints.maxWidth > 800 ? 3 : 2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.55,
          children: [
            StatCard(
              title: "Today's Sales",
              value: 'Rs. ${metrics.todaySalesTotal.toStringAsFixed(2)}',
              subtitle: '${metrics.todaySalesCount} order(s) billed today',
              icon: Icons.point_of_sale_rounded,
              iconColor: AppColors.success,
              iconBackgroundColor: AppColors.successLight,
            ),
            StatCard(
              title: "Today's Purchases",
              value: 'Rs. ${metrics.todayPurchasesTotal.toStringAsFixed(2)}',
              subtitle: '${metrics.todayPurchasesCount} inward shipment(s)',
              icon: Icons.shopping_bag_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBackgroundColor: const Color(0xFFF5F3FF),
            ),
            StatCard(
              title: "Customer Payments",
              value: 'Rs. ${metrics.todayCustomerPaymentsTotal.toStringAsFixed(2)}',
              subtitle: '${metrics.todayCustomerPaymentsCount} receipt(s) collected',
              icon: Icons.payments_rounded,
              iconColor: const Color(0xFF0D9488),
              iconBackgroundColor: const Color(0xFFF0FDFA),
            ),
            StatCard(
              title: "Supplier Payments",
              value: 'Rs. ${metrics.todaySupplierPaymentsTotal.toStringAsFixed(2)}',
              subtitle: '${metrics.todaySupplierPaymentsCount} payout(s) disbursed',
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFFD97706),
              iconBackgroundColor: const Color(0xFFFFFBEB),
            ),
            StatCard(
              title: "Today's Expenses",
              value: 'Rs. ${metrics.todayExpensesTotal.toStringAsFixed(2)}',
              subtitle: '${metrics.todayExpensesCount} operational expense(s)',
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.error,
              iconBackgroundColor: AppColors.errorLight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInventoryAndFinancialGrid(DashboardMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 960 ? 3 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.75,
          children: [
            StatCard(
              title: 'Total Books',
              value: '${metrics.totalBooks}',
              subtitle: 'Catalog book titles',
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.primary,
            ),
            StatCard(
              title: 'Current Stock',
              value: '${metrics.currentStock}',
              subtitle: 'Total volume in warehouse',
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBackgroundColor: const Color(0xFFEFF6FF),
            ),
            StatCard(
              title: 'Low Stock',
              value: '${metrics.lowStockCount}',
              subtitle: 'Books at/below reorder threshold',
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.warning,
              iconBackgroundColor: AppColors.warningLight,
            ),
            StatCard(
              title: 'Out of Stock',
              value: '${metrics.outOfStockCount}',
              subtitle: 'Titles with zero copies',
              icon: Icons.remove_shopping_cart_rounded,
              iconColor: AppColors.error,
              iconBackgroundColor: AppColors.errorLight,
            ),
            StatCard(
              title: 'Customer Receivables',
              value: 'Rs. ${metrics.customerReceivables.toStringAsFixed(2)}',
              subtitle: 'Outstanding customer balances',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.warning,
              iconBackgroundColor: AppColors.warningLight,
            ),
            StatCard(
              title: 'Supplier Payables',
              value: 'Rs. ${metrics.supplierPayables.toStringAsFixed(2)}',
              subtitle: 'Pending vendor disbursements',
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.error,
              iconBackgroundColor: AppColors.errorLight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockAlertsCard(DashboardMetrics metrics) {
    return AppCard(
      title: 'Low & Out-of-Stock Alerts',
      subtitle: 'Inventory requiring immediate replenishment or supplier purchase orders',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: metrics.lowStockBooks.isNotEmpty
              ? AppColors.errorLight
              : AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${metrics.lowStockBooks.length} alert(s)',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: metrics.lowStockBooks.isNotEmpty
                ? AppColors.error
                : AppColors.success,
          ),
        ),
      ),
      child: metrics.lowStockBooks.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All Stock Levels Healthy',
              message:
                  'No books are currently below their minimum threshold alert.',
              iconSize: 42,
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.lowStockBooks.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.neutral200),
              itemBuilder: (context, index) {
                final book = metrics.lowStockBooks[index];
                final isOutOfStock = book.stockQuantity <= 0;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: isOutOfStock
                        ? AppColors.errorLight
                        : AppColors.warningLight,
                    child: Icon(
                      isOutOfStock
                          ? Icons.remove_shopping_cart_rounded
                          : Icons.warning_amber_rounded,
                      color:
                          isOutOfStock ? AppColors.error : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    book.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Author: ${book.author?.isNotEmpty == true ? book.author : 'N/A'} • Min threshold: ${book.minimumStock} pcs',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${book.stockQuantity} in stock',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isOutOfStock
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildAlertBadge(isOutOfStock),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecentSalesCard(DashboardMetrics metrics) {
    return AppCard(
      title: 'Recent 10 Sales',
      subtitle: 'Most recent outward wholesale invoices billed to customers',
      trailing: Text(
        '${metrics.recentSales.length} invoice(s)',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      child: metrics.recentSales.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_outlined,
              title: 'No sales recorded yet',
              message:
                  'Sales invoices billed through the Sales module will automatically appear here.',
              iconSize: 42,
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.recentSales.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.neutral200),
              itemBuilder: (context, index) {
                final sale = metrics.recentSales[index];
                final customerName = sale.customerId != null
                    ? (metrics.customerNames[sale.customerId] ?? 'Customer #${sale.customerId}')
                    : 'Walk-in / Cash Customer';

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.successLight,
                    child: Icon(Icons.arrow_upward_rounded,
                        color: AppColors.success, size: 18),
                  ),
                  title: Row(
                    children: [
                      Text(
                        sale.invoiceNumber,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(sale.paymentStatus),
                    ],
                  ),
                  subtitle: Text(
                    '$customerName • ${sale.saleDate.split('T').first}',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Text(
                    'Rs. ${sale.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRecentPurchasesCard(DashboardMetrics metrics) {
    return AppCard(
      title: 'Recent 10 Purchases',
      subtitle: 'Inward wholesale stock shipments from publishers & distributors',
      trailing: Text(
        '${metrics.recentPurchases.length} invoice(s)',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      child: metrics.recentPurchases.isEmpty
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No purchase invoices recorded',
              message:
                  'Purchases recorded from suppliers will be summarized here for quick audits.',
              iconSize: 42,
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.recentPurchases.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.neutral200),
              itemBuilder: (context, index) {
                final purchase = metrics.recentPurchases[index];
                final supplierName =
                    metrics.supplierNames[purchase.supplierId] ??
                        'Supplier #${purchase.supplierId}';

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.arrow_downward_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  title: Row(
                    children: [
                      Text(
                        purchase.invoiceNumber,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(purchase.paymentStatus),
                    ],
                  ),
                  subtitle: Text(
                    '$supplierName • ${purchase.purchaseDate.split('T').first}',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Text(
                    'Rs. ${purchase.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAlertBadge(bool isOutOfStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOutOfStock ? AppColors.errorLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOutOfStock ? AppColors.error : AppColors.warning,
          width: 0.8,
        ),
      ),
      child: Text(
        isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isOutOfStock ? AppColors.error : AppColors.warning,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'PAID':
        bg = AppColors.successLight;
        fg = AppColors.successText;
        break;
      case 'PARTIAL':
        bg = AppColors.warningLight;
        fg = AppColors.warningText;
        break;
      case 'UNPAID':
      default:
        bg = AppColors.errorLight;
        fg = AppColors.errorText;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
