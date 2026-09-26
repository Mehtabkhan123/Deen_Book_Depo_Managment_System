import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../bloc/inventory_bloc.dart';

/// Professional Windows Desktop Inventory Management Page
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _stockSearchController = TextEditingController();
  final TextEditingController _movementSearchController =
      TextEditingController();

  Timer? _stockSearchDebounce;
  Timer? _movementSearchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final bloc = context.read<InventoryBloc>();
    if (bloc.state is InventoryInitial) {
      bloc.add(const LoadInventory());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stockSearchDebounce?.cancel();
    _movementSearchDebounce?.cancel();
    _stockSearchController.dispose();
    _movementSearchController.dispose();
    super.dispose();
  }

  void _onStockSearchChanged(String query) {
    _stockSearchDebounce?.cancel();
    _stockSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<InventoryBloc>().add(SearchInventory(query));
      }
    });
  }

  void _onStockSearchClear() {
    _stockSearchDebounce?.cancel();
    context.read<InventoryBloc>().add(const SearchInventory(''));
  }

  void _onMovementSearchChanged(String query) {
    _movementSearchDebounce?.cancel();
    _movementSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<InventoryBloc>().add(FilterStockMovements(query: query));
      }
    });
  }

  void _onMovementSearchClear() {
    _movementSearchDebounce?.cancel();
    context.read<InventoryBloc>().add(const FilterStockMovements(query: ''));
  }

  Widget _buildStockStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case 'OUT OF STOCK':
        bg = AppColors.errorLight;
        fg = AppColors.errorText;
        icon = Icons.cancel_outlined;
        break;
      case 'LOW STOCK':
        bg = AppColors.warningLight;
        fg = AppColors.warningText;
        icon = Icons.warning_amber_rounded;
        break;
      case 'IN STOCK':
      default:
        bg = AppColors.successLight;
        fg = AppColors.successText;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTypeBadge(String type) {
    Color bg;
    Color fg;
    switch (type.toUpperCase()) {
      case 'PURCHASE':
        bg = AppColors.primaryLight.withValues(alpha: 0.2);
        fg = AppColors.primary;
        break;
      case 'SALE':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        break;
      case 'ADJUSTMENT_IN':
        bg = AppColors.successLight;
        fg = AppColors.successText;
        break;
      case 'ADJUSTMENT_OUT':
      default:
        bg = AppColors.neutral200;
        fg = AppColors.textPrimary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<InventoryBloc>().add(const ClearInventoryMessages());
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<InventoryBloc>().add(const ClearInventoryMessages());
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
                  title: 'Inventory & Stock Management',
                  subtitle:
                      'Real-time physical stock ledger, low-stock threshold monitoring, and movement audit trail.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context
                            .read<InventoryBloc>()
                            .add(const RefreshInventory());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Metrics Overview Cards
                if (state is InventoryLoaded) _buildMetricsCards(state),
                const SizedBox(height: 20),

                // Tab Navigation
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.inventory_2_outlined, size: 18),
                        text: 'Stock Ledger & Valuation',
                      ),
                      Tab(
                        icon: Icon(Icons.history_rounded, size: 18),
                        text: 'Stock Movement Audit Trail',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tab Views
                if (state is InventoryLoading)
                  const LoadingIndicator(
                    message: 'Loading inventory records and stock movements...',
                  )
                else if (state is InventoryError)
                  ErrorState(
                    title: 'Failed to load inventory',
                    message: state.message,
                    onRetry: () => context
                        .read<InventoryBloc>()
                        .add(const LoadInventory()),
                  )
                else if (state is InventoryLoaded)
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0) {
                        return _buildStockLedgerTab(state);
                      } else {
                        return _buildMovementsTab(state);
                      }
                    },
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsCards(InventoryLoaded state) {
    return Row(
      children: [
        _buildMetricBox(
          'Total Title Catalog',
          '${state.totalBooks}',
          'Unique active titles',
          Icons.menu_book_rounded,
          AppColors.primary,
          AppColors.primaryLight.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 14),
        _buildMetricBox(
          'Total Units in Stock',
          '${state.totalStockUnits}',
          'Current warehouse units',
          Icons.warehouse_rounded,
          Colors.indigo,
          Colors.indigo.shade50,
        ),
        const SizedBox(width: 14),
        _buildMetricBox(
          'Low Stock Alerts',
          '${state.lowStockCount}',
          'At or below threshold',
          Icons.warning_amber_rounded,
          AppColors.warningText,
          AppColors.warningLight.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 14),
        _buildMetricBox(
          'Out of Stock',
          '${state.outOfStockCount}',
          'Zero quantity on shelf',
          Icons.remove_shopping_cart_rounded,
          AppColors.errorText,
          AppColors.errorLight.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockLedgerTab(InventoryLoaded state) {
    final books = state.filteredBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter bar
        Row(
          children: [
            // Search Input
            Expanded(
              flex: 3,
              child: SearchField(
                hint: 'Search books by title, ISBN, author, or publisher...',
                controller: _stockSearchController,
                onChanged: _onStockSearchChanged,
                onSubmitted: (query) {
                  _stockSearchDebounce?.cancel();
                  context.read<InventoryBloc>().add(SearchInventory(query));
                },
                onClear: _onStockSearchClear,
              ),
            ),
            const SizedBox(width: 14),

            // Category Filter
            SizedBox(
              width: 200,
              child: AppDropdown<int>(
                hint: 'Filter by Category',
                value: state.selectedCategoryId,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...state.categoryNames.entries.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (catId) {
                  context.read<InventoryBloc>().add(FilterInventory(
                        categoryId: catId,
                        stockStatus: state.stockStatusFilter,
                      ));
                },
              ),
            ),
            const SizedBox(width: 14),

            // Stock Status Filter
            SizedBox(
              width: 180,
              child: AppDropdown<String>(
                value: state.stockStatusFilter,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Stock Levels')),
                  DropdownMenuItem(value: 'IN_STOCK', child: Text('In Stock')),
                  DropdownMenuItem(value: 'LOW_STOCK', child: Text('Low Stock Alerts')),
                  DropdownMenuItem(value: 'OUT_OF_STOCK', child: Text('Out of Stock')),
                ],
                onChanged: (status) {
                  if (status != null) {
                    context.read<InventoryBloc>().add(FilterInventory(
                          categoryId: state.selectedCategoryId,
                          stockStatus: status,
                        ));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Table
        DataTableWrapper(
          title: 'Books Stock Ledger (${books.length})',
          minWidth: 1100,
          emptyIcon: Icons.inventory_2_outlined,
          emptyTitle: state.searchQuery.isEmpty &&
                  state.selectedCategoryId == null &&
                  state.stockStatusFilter == 'ALL'
              ? 'No books in inventory catalog'
              : 'No books match current filter',
          emptyMessage: state.searchQuery.isEmpty &&
                  state.selectedCategoryId == null &&
                  state.stockStatusFilter == 'ALL'
              ? 'Add books in the Books module or record inward purchases to populate the inventory ledger.'
              : 'Try clearing the search keywords or selecting "All Stock Levels".',
          emptyActionLabel: 'Reset Filters',
          onEmptyAction: () {
            _stockSearchController.clear();
            _onStockSearchClear();
            context.read<InventoryBloc>().add(const FilterInventory(
                  categoryId: null,
                  stockStatus: 'ALL',
                ));
          },
          columns: const [
            DataColumn(label: Text('ID'), numeric: true),
            DataColumn(label: Text('Book Title')),
            DataColumn(label: Text('ISBN')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Current Stock'), numeric: true),
            DataColumn(label: Text('Min. Threshold'), numeric: true),
            DataColumn(label: Text('Purchase Price'), numeric: true),
            DataColumn(label: Text('Wholesale Price'), numeric: true),
            DataColumn(label: Text('Retail Price'), numeric: true),
            DataColumn(label: Text('Stock Status')),
          ],
          rows: books.map((b) {
            final catName = state.getCategoryName(b.categoryId);
            final status = InventoryLoaded.computeStockStatus(b);

            return DataRow(
              cells: [
                DataCell(Text('#${b.id ?? "--"}')),
                DataCell(
                  Text(
                    b.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(b.isbn ?? '--', style: AppTextStyles.caption)),
                DataCell(Text(catName)),
                DataCell(
                  Text(
                    '${b.stockQuantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: b.stockQuantity <= 0
                          ? AppColors.errorText
                          : b.stockQuantity <= b.minimumStock
                              ? AppColors.warningText
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
                DataCell(Text('${b.minimumStock}', style: AppTextStyles.caption)),
                DataCell(Text('Rs. ${b.purchasePrice.toStringAsFixed(2)}')),
                DataCell(Text('Rs. ${b.wholesalePrice.toStringAsFixed(2)}')),
                DataCell(Text('Rs. ${b.retailPrice.toStringAsFixed(2)}')),
                DataCell(_buildStockStatusBadge(status)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMovementsTab(InventoryLoaded state) {
    final movements = state.filteredMovements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Movement filters
        Row(
          children: [
            // Search Input
            Expanded(
              flex: 3,
              child: SearchField(
                hint: 'Filter movements by book title, invoice reference, or notes...',
                controller: _movementSearchController,
                onChanged: _onMovementSearchChanged,
                onSubmitted: (query) {
                  _movementSearchDebounce?.cancel();
                  context
                      .read<InventoryBloc>()
                      .add(FilterStockMovements(query: query));
                },
                onClear: _onMovementSearchClear,
              ),
            ),
            const SizedBox(width: 14),

            // Movement Type Filter
            SizedBox(
              width: 200,
              child: AppDropdown<String>(
                value: state.movementsTypeFilter ?? 'ALL',
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Movement Types')),
                  DropdownMenuItem(value: 'PURCHASE', child: Text('Purchases (Inward)')),
                  DropdownMenuItem(value: 'SALE', child: Text('Sales (Outward)')),
                  DropdownMenuItem(value: 'ADJUSTMENT_IN', child: Text('Adjustment (+)')),
                  DropdownMenuItem(value: 'ADJUSTMENT_OUT', child: Text('Adjustment (-)')),
                ],
                onChanged: (val) {
                  context.read<InventoryBloc>().add(FilterStockMovements(
                        movementType: val,
                      ));
                },
              ),
            ),
            const SizedBox(width: 14),

            // Book Filter
            SizedBox(
              width: 240,
              child: AppDropdown<int>(
                hint: 'Filter by Specific Book',
                value: state.movementsBookFilter,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('All Books'),
                  ),
                  ...state.books.map((b) {
                    return DropdownMenuItem<int>(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (bookId) {
                  context.read<InventoryBloc>().add(FilterStockMovements(
                        bookId: bookId,
                      ));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Movements Table
        DataTableWrapper(
          title: 'Stock Movement Audit Log (${movements.length})',
          minWidth: 1050,
          emptyIcon: Icons.history_rounded,
          emptyTitle: 'No stock movements recorded',
          emptyMessage:
              'Purchase receipts, sales invoices, and stock adjustments automatically write immutable movement log entries.',
          emptyActionLabel: 'Reset Movement Filter',
          onEmptyAction: () {
            _movementSearchController.clear();
            _onMovementSearchClear();
            context.read<InventoryBloc>().add(const FilterStockMovements(
                  bookId: null,
                  movementType: 'ALL',
                  query: '',
                ));
          },
          columns: const [
            DataColumn(label: Text('ID'), numeric: true),
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Book Title')),
            DataColumn(label: Text('Movement Type')),
            DataColumn(label: Text('Quantity Change'), numeric: true),
            DataColumn(label: Text('Previous Stock'), numeric: true),
            DataColumn(label: Text('New Stock'), numeric: true),
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Audit Notes')),
          ],
          rows: movements.map((m) {
            final bookTitle = state.getBookTitle(m.bookId);
            final dateFormatted = m.movementDate.isNotEmpty
                ? m.movementDate.replaceAll('T', ' ').split('.').first
                : '--';
            final isIncrease = m.newStock >= m.previousStock;

            return DataRow(
              cells: [
                DataCell(Text('#${m.id ?? "--"}')),
                DataCell(Text(dateFormatted, style: AppTextStyles.caption)),
                DataCell(
                  Text(
                    bookTitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(_buildMovementTypeBadge(m.movementType)),
                DataCell(
                  Text(
                    '${isIncrease ? "+" : "-"}${m.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isIncrease
                          ? AppColors.successText
                          : AppColors.errorText,
                    ),
                  ),
                ),
                DataCell(Text('${m.previousStock}')),
                DataCell(
                  Text(
                    '${m.newStock}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(
                  Text(
                    m.referenceType != null
                        ? '${m.referenceType} #${m.referenceId ?? ""}'
                        : '--',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    m.notes ?? '--',
                    style: AppTextStyles.bodySmall,
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
