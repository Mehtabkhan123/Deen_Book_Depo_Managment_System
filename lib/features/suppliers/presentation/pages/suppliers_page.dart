import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/supplier.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../bloc/supplier_bloc.dart';
import '../widgets/supplier_detail_dialog.dart';
import '../widgets/supplier_form_dialog.dart';

/// Professional Windows Desktop Suppliers Management Page
class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<SupplierBloc>();
    if (bloc.state is SupplierInitial) {
      bloc.add(const LoadSuppliers());
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
        context.read<SupplierBloc>().add(SearchSuppliers(query));
      }
    });
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    context.read<SupplierBloc>().add(const SearchSuppliers(''));
  }

  void _openAddDialog() {
    SupplierFormDialog.show(
      context,
      onSave: (supplier) {
        context.read<SupplierBloc>().add(AddSupplier(supplier));
      },
    );
  }

  void _openEditDialog(Supplier supplier) {
    SupplierFormDialog.show(
      context,
      supplier: supplier,
      onSave: (updated) {
        context.read<SupplierBloc>().add(UpdateSupplier(updated));
      },
    );
  }

  void _openDetailDialog(Supplier supplier, double currentBalance) {
    SupplierDetailDialog.show(
      context,
      supplier: supplier,
      currentBalance: currentBalance,
      onEdit: () => _openEditDialog(supplier),
    );
  }

  Future<void> _confirmDelete(Supplier supplier) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Supplier Account?',
      message:
          'Are you sure you want to delete "${supplier.name}"? If purchase invoices or disbursement payment records exist, deletion will be safely rejected.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && supplier.id != null && mounted) {
      context.read<SupplierBloc>().add(DeleteSupplier(supplier.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<SupplierBloc, SupplierState>(
        listener: (context, state) {
          if (state is SupplierLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(state.successMessage!),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
              context.read<SupplierBloc>().add(const ClearSupplierMessages());
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
              context.read<SupplierBloc>().add(const ClearSupplierMessages());
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
                  title: 'Suppliers & Publishers',
                  subtitle:
                      'Vendor directory, wholesale book distributors, and account payables.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context
                            .read<SupplierBloc>()
                            .add(const RefreshSuppliers());
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Add Supplier',
                      icon: Icons.add_business_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _openAddDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SearchField(
                        hint: 'Search suppliers by name, phone, or email...',
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: (query) {
                          _searchDebounce?.cancel();
                          context
                              .read<SupplierBloc>()
                              .add(SearchSuppliers(query));
                        },
                        onClear: _onSearchClear,
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
                const SizedBox(height: 20),

                // Content View
                if (state is SupplierLoading)
                  const LoadingIndicator(
                    message: 'Loading suppliers and ledger balances...',
                  )
                else if (state is SupplierError)
                  ErrorState(
                    title: 'Failed to load suppliers',
                    message: state.message,
                    onRetry: () => context
                        .read<SupplierBloc>()
                        .add(const LoadSuppliers()),
                  )
                else if (state is SupplierLoaded)
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

  Widget _buildTable(SupplierLoaded state) {
    final suppliers = state.suppliers;

    return DataTableWrapper(
      title: 'Supplier Accounts (${suppliers.length})',
      minWidth: 1000,
      emptyIcon: Icons.local_shipping_outlined,
      emptyTitle: state.searchQuery.isEmpty
          ? 'No suppliers registered yet'
          : 'No suppliers match "${state.searchQuery}"',
      emptyMessage: state.searchQuery.isEmpty
          ? 'Add your first publishing house, printer, or wholesale vendor to manage procurement and payables.'
          : 'Try searching with a different name, phone, or email keyword.',
      emptyActionLabel:
          state.searchQuery.isEmpty ? 'Add First Supplier' : 'Clear Search',
      onEmptyAction: state.searchQuery.isEmpty
          ? _openAddDialog
          : () {
              _searchController.clear();
              _onSearchClear();
            },
      columns: const [
        DataColumn(label: Text('ID'), numeric: true),
        DataColumn(label: Text('Supplier Name')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Opening Balance'), numeric: true),
        DataColumn(label: Text('Current Balance'), numeric: true),
        DataColumn(label: Text('Created Date')),
        DataColumn(label: Text('Actions')),
      ],
      rows: suppliers.map((s) {
        final currentBalance = state.getBalance(s.id);
        final createdFormatted =
            s.createdAt.isNotEmpty ? s.createdAt.split('T').first : '--';

        return DataRow(
          cells: [
            DataCell(Text('#${s.id ?? "--"}')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(s.phone ?? '--', style: AppTextStyles.bodyMedium)),
            DataCell(Text(s.email ?? '--', style: AppTextStyles.caption)),
            DataCell(Text('Rs. ${s.openingBalance.toStringAsFixed(2)}')),
            DataCell(
              Text(
                'Rs. ${currentBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: currentBalance > 0
                      ? AppColors.errorText
                      : AppColors.successText,
                ),
              ),
            ),
            DataCell(Text(createdFormatted, style: AppTextStyles.caption)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    color: AppColors.secondary,
                    tooltip: 'View Supplier Details',
                    splashRadius: 18,
                    onPressed: () => _openDetailDialog(s, currentBalance),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit Supplier',
                    splashRadius: 18,
                    onPressed: () => _openEditDialog(s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Delete Supplier',
                    splashRadius: 18,
                    onPressed: () => _confirmDelete(s),
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
