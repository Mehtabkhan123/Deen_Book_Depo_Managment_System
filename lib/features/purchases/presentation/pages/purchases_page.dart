import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../bloc/purchase_bloc.dart';
import '../widgets/purchase_detail_dialog.dart';
import '../widgets/purchase_form_dialog.dart';

/// Professional Windows Desktop Purchases Management Page
class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<PurchaseBloc>();
    if (bloc.state is PurchaseInitial) {
      bloc.add(const LoadPurchases());
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
        context.read<PurchaseBloc>().add(SearchPurchases(query));
      }
    });
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    context.read<PurchaseBloc>().add(const SearchPurchases(''));
  }

  void _openAddDialog(PurchaseLoaded state) {
    PurchaseFormDialog.show(
      context,
      suppliers: state.suppliers.values.toList(),
      books: state.books.values.toList(),
      onSave: (purchase, items) {
        context.read<PurchaseBloc>().add(CreatePurchase(
              purchase: purchase,
              items: items,
            ));
      },
    );
  }

  void _openDetailDialog(Purchase purchase, PurchaseLoaded state) async {
    context.read<PurchaseBloc>().add(LoadPurchaseDetails(purchase.id!));
  }

  Future<void> _confirmDelete(Purchase purchase) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel / Reverse Purchase Invoice?',
      message:
          'Cancelling purchase #${purchase.invoiceNumber} will automatically reverse the stock quantities added by this invoice. If any books have already been sold or deducted below the required quantity, deletion will be safely rejected.',
      confirmLabel: 'Cancel Invoice & Reverse Stock',
      isDestructive: true,
      icon: Icons.assignment_return_outlined,
    );

    if (confirmed && purchase.id != null && mounted) {
      context.read<PurchaseBloc>().add(DeletePurchase(purchase.id!));
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
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
      body: BlocConsumer<PurchaseBloc, PurchaseState>(
        listener: (context, state) {
          if (state is PurchaseLoaded) {
            // If details were just loaded, show the detail dialog
            if (state.selectedPurchase != null &&
                state.selectedPurchaseItems != null) {
              final purchase = state.selectedPurchase!;
              final items = state.selectedPurchaseItems!;
              final supp = state.suppliers[purchase.supplierId];
              final bookTitles = {
                for (final entry in state.books.entries)
                  entry.key: entry.value.name
              };

              // Clear selected so it won't re-trigger
              context
                  .read<PurchaseBloc>()
                  .add(const FilterPurchases()); // keeps current filter

              PurchaseDetailDialog.show(
                context,
                purchase: purchase,
                items: items,
                supplierName: supp?.name ?? 'Supplier #${purchase.supplierId}',
                supplierPhone: supp?.phone ?? '--',
                bookTitles: bookTitles,
              );
            }

            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.successMessage!)),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
              context.read<PurchaseBloc>().add(const ClearPurchaseMessages());
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.errorMessage!)),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
              context.read<PurchaseBloc>().add(const ClearPurchaseMessages());
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
                  title: 'Purchases & Procurement',
                  subtitle:
                      'Manage wholesale book purchases, vendor invoices, stock inward, and payables.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context
                            .read<PurchaseBloc>()
                            .add(const RefreshPurchases());
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'New Purchase',
                      icon: Icons.add_shopping_cart_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        if (state is PurchaseLoaded) {
                          _openAddDialog(state);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter & Search Bar
                if (state is PurchaseLoaded) _buildFilterBar(state),
                const SizedBox(height: 20),

                // Content View
                if (state is PurchaseLoading)
                  const LoadingIndicator(
                    message: 'Loading purchases and inventory intakes...',
                  )
                else if (state is PurchaseError)
                  ErrorState(
                    title: 'Failed to load purchases',
                    message: state.message,
                    onRetry: () => context
                        .read<PurchaseBloc>()
                        .add(const LoadPurchases()),
                  )
                else if (state is PurchaseLoaded)
                  _buildTable(state)
                else
                  const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(PurchaseLoaded state) {
    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 3,
          child: SearchField(
            hint: 'Search by invoice number or supplier name...',
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: (query) {
              _searchDebounce?.cancel();
              context.read<PurchaseBloc>().add(SearchPurchases(query));
            },
            onClear: _onSearchClear,
          ),
        ),
        const SizedBox(width: 14),

        // Payment Status Filter Dropdown
        SizedBox(
          width: 180,
          child: AppDropdown<String>(
            value: state.paymentStatusFilter ?? 'ALL',
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
              DropdownMenuItem(value: 'PAID', child: Text('Paid Invoices')),
              DropdownMenuItem(value: 'PARTIAL', child: Text('Partial Credit')),
              DropdownMenuItem(value: 'UNPAID', child: Text('Unpaid Invoices')),
            ],
            onChanged: (val) {
              context.read<PurchaseBloc>().add(FilterPurchases(
                    paymentStatus: val,
                    supplierId: state.supplierFilter,
                  ));
            },
          ),
        ),
        const SizedBox(width: 14),

        // Supplier Filter Dropdown
        SizedBox(
          width: 220,
          child: AppDropdown<int>(
            hint: 'Filter by Supplier',
            value: state.supplierFilter,
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('All Suppliers'),
              ),
              ...state.suppliers.values.map((s) {
                return DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(
                    s.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (val) {
              context.read<PurchaseBloc>().add(FilterPurchases(
                    paymentStatus: state.paymentStatusFilter,
                    supplierId: val,
                  ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTable(PurchaseLoaded state) {
    final purchases = state.filteredPurchases;

    return DataTableWrapper(
      title: 'Purchase Invoices (${purchases.length})',
      minWidth: 1100,
      emptyIcon: Icons.receipt_long_outlined,
      emptyTitle: state.searchQuery.isEmpty &&
              state.paymentStatusFilter == null &&
              state.supplierFilter == null
          ? 'No purchase invoices recorded yet'
          : 'No purchases match current filter',
      emptyMessage: state.searchQuery.isEmpty &&
              state.paymentStatusFilter == null &&
              state.supplierFilter == null
          ? 'Create your first wholesale inward invoice to increment book inventory stock.'
          : 'Try clearing your search keyword or relaxing the supplier/status filters.',
      emptyActionLabel: state.searchQuery.isEmpty &&
              state.paymentStatusFilter == null &&
              state.supplierFilter == null
          ? 'New Purchase'
          : 'Reset Filters',
      onEmptyAction: state.searchQuery.isEmpty &&
              state.paymentStatusFilter == null &&
              state.supplierFilter == null
          ? () => _openAddDialog(state)
          : () {
              _searchController.clear();
              _onSearchClear();
              context.read<PurchaseBloc>().add(const FilterPurchases(
                    paymentStatus: 'ALL',
                    supplierId: null,
                  ));
            },
      columns: const [
        DataColumn(label: Text('ID'), numeric: true),
        DataColumn(label: Text('Invoice #')),
        DataColumn(label: Text('Supplier')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Subtotal'), numeric: true),
        DataColumn(label: Text('Discount'), numeric: true),
        DataColumn(label: Text('Total'), numeric: true),
        DataColumn(label: Text('Paid'), numeric: true),
        DataColumn(label: Text('Remaining'), numeric: true),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: purchases.map((p) {
        final supp = state.suppliers[p.supplierId];
        final suppName = supp?.name ?? 'Supplier #${p.supplierId}';
        final dateFormatted =
            p.purchaseDate.isNotEmpty ? p.purchaseDate.split('T').first : '--';

        return DataRow(
          cells: [
            DataCell(Text('#${p.id ?? "--"}')),
            DataCell(
              Text(
                p.invoiceNumber,
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
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suppName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(dateFormatted, style: AppTextStyles.caption)),
            DataCell(Text('Rs. ${p.subtotal.toStringAsFixed(2)}')),
            DataCell(Text('Rs. ${p.discount.toStringAsFixed(2)}')),
            DataCell(
              Text(
                'Rs. ${p.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            DataCell(
              Text(
                'Rs. ${p.paidAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.successText),
              ),
            ),
            DataCell(
              Text(
                'Rs. ${p.remainingAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: p.remainingAmount > 0
                      ? AppColors.errorText
                      : AppColors.textSecondary,
                ),
              ),
            ),
            DataCell(_buildStatusBadge(p.paymentStatus)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    color: AppColors.secondary,
                    tooltip: 'View Invoice Details & Items',
                    splashRadius: 18,
                    onPressed: () => _openDetailDialog(p, state),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Cancel Invoice & Reverse Stock',
                    splashRadius: 18,
                    onPressed: () => _confirmDelete(p),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
