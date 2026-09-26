import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../bloc/sales_bloc.dart';
import '../widgets/sale_detail_dialog.dart';
import '../widgets/sale_form_dialog.dart';

/// Professional Windows desktop wholesale sales management page
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<SalesBloc>();
    if (bloc.state is SalesInitial) {
      bloc.add(const LoadSales());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<SalesBloc>().add(SearchSales(query));
      }
    });
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    context.read<SalesBloc>().add(const SearchSales(''));
  }

  void _openNewSaleDialog(SalesLoaded state) {
    SaleFormDialog.show(
      context,
      customers: state.customers.values.toList(),
      books: state.books.values.toList(),
      onSave: (sale, items) {
        context.read<SalesBloc>().add(CreateSale(sale: sale, items: items));
      },
    );
  }

  void _showSaleDetails(Sale sale, SalesLoaded state) {
    context.read<SalesBloc>().add(LoadSaleDetails(sale.id!));
  }

  void _confirmDeleteSale(Sale sale) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Cancel & Reverse Sale #${sale.invoiceNumber}?'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this sales invoice?\n\n'
          '• All sold items will be returned to inventory stock.\n'
          '• A reverse stock movement audit entry will be recorded.\n'
          '• The customer\'s ledger balance will be updated automatically.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          AppButton(
            label: 'No, Keep Sale',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton(
            label: 'Yes, Reverse Sale',
            icon: Icons.restart_alt_rounded,
            variant: AppButtonVariant.destructive,
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SalesBloc>().add(DeleteSale(sale.id!));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<SalesBloc, SalesState>(
        listener: (context, state) {
          if (state is SalesLoaded) {
            if (state.selectedSale != null && state.selectedSaleItems != null) {
              final sale = state.selectedSale!;
              final items = state.selectedSaleItems!;
              final customerName = state.getCustomerName(sale.customerId);
              final customerPhone = state.getCustomerPhone(sale.customerId);
              final bookTitles = {
                for (final b in state.books.values)
                  if (b.id != null) b.id!: b.name
              };

              SaleDetailDialog.show(
                context,
                sale: sale,
                items: items,
                customerName: customerName,
                customerPhone: customerPhone,
                bookTitles: bookTitles,
              );
            }

            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<SalesBloc>().add(const ClearSaleMessages());
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<SalesBloc>().add(const ClearSaleMessages());
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Header
                PageHeader(
                  title: 'Wholesale Sales Management',
                  subtitle:
                      'Outward wholesale invoices, customer receivables, real-time stock deductions, and settlements.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context.read<SalesBloc>().add(const RefreshSales());
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'New Wholesale Sale',
                      icon: Icons.add_rounded,
                      onPressed: state is SalesLoaded
                          ? () => _openNewSaleDialog(state)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Metrics Overview Cards
                if (state is SalesLoaded) _buildMetricsCards(state),
                const SizedBox(height: 20),

                // Main Content View
                if (state is SalesLoading)
                  const LoadingIndicator(
                    message: 'Loading wholesale sales records from database...',
                  )
                else if (state is SalesError)
                  ErrorState(
                    title: 'Failed to load sales',
                    message: state.message,
                    onRetry: () =>
                        context.read<SalesBloc>().add(const LoadSales()),
                  )
                else if (state is SalesLoaded)
                  _buildSalesTable(state)
                else
                  const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsCards(SalesLoaded state) {
    return Row(
      children: [
        _buildMetricBox(
          'Total Invoices',
          '${state.totalSalesCount}',
          'All time sales count',
          Icons.receipt_long_rounded,
          AppColors.primary,
          AppColors.primaryLight.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 14),
        _buildMetricBox(
          'Total Invoiced Revenue',
          'Rs. ${state.totalInvoicedRevenue.toStringAsFixed(2)}',
          'Gross billed wholesale',
          Icons.trending_up_rounded,
          AppColors.textPrimary,
          AppColors.neutral100,
        ),
        const SizedBox(width: 14),
        _buildMetricBox(
          'Collections Received',
          'Rs. ${state.totalPaidAmount.toStringAsFixed(2)}',
          'Settled payments received',
          Icons.check_circle_outline_rounded,
          AppColors.successText,
          AppColors.successLight.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 14),
        _buildMetricBox(
          'Receivables Pending',
          'Rs. ${state.totalReceivableAmount.toStringAsFixed(2)}',
          'Outstanding credit balance',
          Icons.pending_actions_rounded,
          state.totalReceivableAmount > 0
              ? AppColors.errorText
              : AppColors.textSecondary,
          state.totalReceivableAmount > 0
              ? AppColors.errorLight.withValues(alpha: 0.5)
              : AppColors.neutral100,
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTable(SalesLoaded state) {
    final sales = state.filteredSales;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Row
        Row(
          children: [
            // Search Input
            Expanded(
              flex: 3,
              child: SearchField(
                hint: 'Search sales by invoice #, customer name, notes...',
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (query) {
                  _searchDebounce?.cancel();
                  context.read<SalesBloc>().add(SearchSales(query));
                },
                onClear: _onSearchClear,
              ),
            ),
            const SizedBox(width: 14),

            // Payment Status Filter
            SizedBox(
              width: 180,
              child: AppDropdown<String>(
                value: state.paymentStatusFilter ?? 'ALL',
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'PAID', child: Text('Paid In Full')),
                  DropdownMenuItem(value: 'PARTIAL', child: Text('Partially Paid')),
                  DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid / Credit')),
                ],
                onChanged: (val) {
                  context.read<SalesBloc>().add(FilterSales(
                        paymentStatus: val,
                      ));
                },
              ),
            ),
            const SizedBox(width: 14),

            // Customer Channel Filter
            SizedBox(
              width: 240,
              child: AppDropdown<int?>(
                hint: 'Filter by Customer',
                value: state.isCashOnlyFilter ? -999 : state.customerFilter,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Channels / Customers'),
                  ),
                  const DropdownMenuItem<int?>(
                    value: -999,
                    child: Text(
                      'Cash / Walk-in Only',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.successText),
                    ),
                  ),
                  ...state.customers.values.map((c) {
                    return DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (val) {
                  if (val == -999) {
                    context.read<SalesBloc>().add(const FilterSales(
                          isCashOnly: true,
                          customerId: null,
                        ));
                  } else {
                    context.read<SalesBloc>().add(FilterSales(
                          isCashOnly: false,
                          customerId: val,
                        ));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Sales Data Table
        DataTableWrapper(
          title: 'Wholesale Sales Invoices (${sales.length})',
          minWidth: 1150,
          emptyIcon: Icons.receipt_long_outlined,
          emptyTitle: state.searchQuery.isEmpty &&
                  state.paymentStatusFilter == null &&
                  state.customerFilter == null &&
                  !state.isCashOnlyFilter
              ? 'No sales invoices recorded'
              : 'No sales match current filter',
          emptyMessage: state.searchQuery.isEmpty &&
                  state.paymentStatusFilter == null &&
                  state.customerFilter == null &&
                  !state.isCashOnlyFilter
              ? 'Click "New Wholesale Sale" above to record your first outward book sale.'
              : 'Try clearing your search query or adjusting the payment status and customer filters.',
          emptyActionLabel: 'Reset Filters',
          onEmptyAction: () {
            _searchController.clear();
            _onSearchClear();
            context.read<SalesBloc>().add(const FilterSales(
                  paymentStatus: 'ALL',
                  customerId: null,
                  isCashOnly: false,
                ));
          },
          columns: const [
            DataColumn(label: Text('ID'), numeric: true),
            DataColumn(label: Text('Invoice Number')),
            DataColumn(label: Text('Customer / Channel')),
            DataColumn(label: Text('Sale Date')),
            DataColumn(label: Text('Subtotal'), numeric: true),
            DataColumn(label: Text('Discount'), numeric: true),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Paid Amount'), numeric: true),
            DataColumn(label: Text('Remaining'), numeric: true),
            DataColumn(label: Text('Payment Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: sales.map((sale) {
            final isCash = sale.customerId == null;
            final customerName = state.getCustomerName(sale.customerId);
            final dateFormatted = sale.saleDate.isNotEmpty
                ? sale.saleDate.split('T').first
                : '--';

            return DataRow(
              cells: [
                DataCell(Text('#${sale.id ?? "--"}')),
                DataCell(
                  Text(
                    sale.invoiceNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCash)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CASH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.successText,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          customerName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(dateFormatted, style: AppTextStyles.caption)),
                DataCell(Text('Rs. ${sale.subtotal.toStringAsFixed(2)}')),
                DataCell(Text('Rs. ${sale.discount.toStringAsFixed(2)}')),
                DataCell(
                  Text(
                    'Rs. ${sale.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(
                  Text(
                    'Rs. ${sale.paidAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.successText),
                  ),
                ),
                DataCell(
                  Text(
                    'Rs. ${sale.remainingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: sale.remainingAmount > 0
                          ? AppColors.errorText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(sale.paymentStatus)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        color: AppColors.primary,
                        tooltip: 'View Invoice Details',
                        splashRadius: 18,
                        onPressed: () => _showSaleDetails(sale, state),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        color: AppColors.error,
                        tooltip: 'Cancel & Reverse Sale',
                        splashRadius: 18,
                        onPressed: () => _confirmDeleteSale(sale),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
