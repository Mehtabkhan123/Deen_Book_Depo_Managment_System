import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../bloc/customer_bloc.dart';
import '../widgets/customer_detail_dialog.dart';
import '../widgets/customer_form_dialog.dart';

/// Professional Windows Desktop Customers Management Page
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CustomerBloc>();
    if (bloc.state is CustomerInitial) {
      bloc.add(const LoadCustomers());
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
        context.read<CustomerBloc>().add(SearchCustomers(query));
      }
    });
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    context.read<CustomerBloc>().add(const SearchCustomers(''));
  }

  void _openAddDialog() {
    CustomerFormDialog.show(
      context,
      onSave: (customer) {
        context.read<CustomerBloc>().add(AddCustomer(customer));
      },
    );
  }

  void _openEditDialog(Customer customer) {
    CustomerFormDialog.show(
      context,
      customer: customer,
      onSave: (updated) {
        context.read<CustomerBloc>().add(UpdateCustomer(updated));
      },
    );
  }

  void _openDetailDialog(Customer customer, double currentBalance) {
    CustomerDetailDialog.show(
      context,
      customer: customer,
      currentBalance: currentBalance,
      onEdit: () => _openEditDialog(customer),
    );
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Customer Account?',
      message:
          'Are you sure you want to delete "${customer.name}"? If sales invoices or payment records exist for this customer, deletion will be safely rejected.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );

    if (confirmed && customer.id != null && mounted) {
      context.read<CustomerBloc>().add(DeleteCustomer(customer.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerLoaded) {
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
              context.read<CustomerBloc>().add(const ClearCustomerMessages());
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
              context.read<CustomerBloc>().add(const ClearCustomerMessages());
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
                  title: 'Customers Directory',
                  subtitle:
                      'Manage wholesale book buyers, academies, credit accounts, and receivables.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context
                            .read<CustomerBloc>()
                            .add(const RefreshCustomers());
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Add Customer',
                      icon: Icons.person_add_alt_1_rounded,
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
                        hint: 'Search customers by name, phone, or email...',
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: (query) {
                          _searchDebounce?.cancel();
                          context
                              .read<CustomerBloc>()
                              .add(SearchCustomers(query));
                        },
                        onClear: _onSearchClear,
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
                const SizedBox(height: 20),

                // Content View
                if (state is CustomerLoading)
                  const LoadingIndicator(
                    message: 'Loading customers and ledger balances...',
                  )
                else if (state is CustomerError)
                  ErrorState(
                    title: 'Failed to load customers',
                    message: state.message,
                    onRetry: () => context
                        .read<CustomerBloc>()
                        .add(const LoadCustomers()),
                  )
                else if (state is CustomerLoaded)
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

  Widget _buildTable(CustomerLoaded state) {
    final customers = state.customers;

    return DataTableWrapper(
      title: 'Customer Accounts (${customers.length})',
      minWidth: 1000,
      emptyIcon: Icons.people_outline_rounded,
      emptyTitle: state.searchQuery.isEmpty
          ? 'No customers registered yet'
          : 'No customers match "${state.searchQuery}"',
      emptyMessage: state.searchQuery.isEmpty
          ? 'Add your first wholesale buyer or retail bookstore account to begin recording credit ledgers.'
          : 'Try searching with a different name, phone, or email keyword.',
      emptyActionLabel:
          state.searchQuery.isEmpty ? 'Add First Customer' : 'Clear Search',
      onEmptyAction: state.searchQuery.isEmpty
          ? _openAddDialog
          : () {
              _searchController.clear();
              _onSearchClear();
            },
      columns: const [
        DataColumn(label: Text('ID'), numeric: true),
        DataColumn(label: Text('Customer Name')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Opening Balance'), numeric: true),
        DataColumn(label: Text('Current Balance'), numeric: true),
        DataColumn(label: Text('Created Date')),
        DataColumn(label: Text('Actions')),
      ],
      rows: customers.map((c) {
        final currentBalance = state.getBalance(c.id);
        final createdFormatted =
            c.createdAt.isNotEmpty ? c.createdAt.split('T').first : '--';

        return DataRow(
          cells: [
            DataCell(Text('#${c.id ?? "--"}')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    c.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(c.phone ?? '--', style: AppTextStyles.bodyMedium)),
            DataCell(Text(c.email ?? '--', style: AppTextStyles.caption)),
            DataCell(Text('Rs. ${c.openingBalance.toStringAsFixed(2)}')),
            DataCell(
              Text(
                'Rs. ${currentBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: currentBalance > 0
                      ? AppColors.warningText
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
                    tooltip: 'View Customer Details',
                    splashRadius: 18,
                    onPressed: () => _openDetailDialog(c, currentBalance),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit Customer',
                    splashRadius: 18,
                    onPressed: () => _openEditDialog(c),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Delete Customer',
                    splashRadius: 18,
                    onPressed: () => _confirmDelete(c),
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
