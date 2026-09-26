import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/category.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../bloc/category_bloc.dart';
import '../widgets/category_form_dialog.dart';

/// Professional Windows Desktop Categories Management Page
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CategoryBloc>();
    if (bloc.state is CategoryInitial) {
      bloc.add(const LoadCategories());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    CategoryFormDialog.show(
      context,
      onSave: (category) {
        context.read<CategoryBloc>().add(AddCategory(category));
      },
    );
  }

  void _openEditDialog(Category category) {
    CategoryFormDialog.show(
      context,
      category: category,
      onSave: (updated) {
        context.read<CategoryBloc>().add(UpdateCategory(updated));
      },
    );
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Category?',
      message:
          'Are you sure you want to delete "${category.name}"? If existing books belong to this category, deletion will be safely rejected.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && category.id != null && mounted) {
      context.read<CategoryBloc>().add(DeleteCategory(category.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryLoaded) {
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
              context.read<CategoryBloc>().add(const ClearCategoryMessages());
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
              context.read<CategoryBloc>().add(const ClearCategoryMessages());
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
                  title: 'Categories',
                  subtitle:
                      'Manage book classifications, genres, and curriculum divisions.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context
                            .read<CategoryBloc>()
                            .add(const RefreshCategories());
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Add Category',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _openAddDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SearchField(
                        hint: 'Search categories by name...',
                        controller: _searchController,
                        onChanged: (query) {
                          context
                              .read<CategoryBloc>()
                              .add(SearchCategories(query));
                        },
                        onClear: () {
                          context
                              .read<CategoryBloc>()
                              .add(const SearchCategories(''));
                        },
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
                const SizedBox(height: 20),

                // Content View
                if (state is CategoryLoading)
                  const LoadingIndicator(
                    message: 'Loading categories from local SQLite database...',
                  )
                else if (state is CategoryError)
                  ErrorState(
                    title: 'Failed to load categories',
                    message: state.message,
                    onRetry: () => context
                        .read<CategoryBloc>()
                        .add(const LoadCategories()),
                  )
                else if (state is CategoryLoaded)
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

  Widget _buildTable(CategoryLoaded state) {
    final categories = state.categories;

    return DataTableWrapper(
      title: 'All Categories (${categories.length})',
      minWidth: 780,
      emptyIcon: Icons.category_outlined,
      emptyTitle: state.searchQuery.isEmpty
          ? 'No categories created yet'
          : 'No categories match "${state.searchQuery}"',
      emptyMessage: state.searchQuery.isEmpty
          ? 'Create your first book classification category to organize your inventory.'
          : 'Try searching with a different keyword or clear the search input.',
      emptyActionLabel:
          state.searchQuery.isEmpty ? 'Add First Category' : 'Clear Search',
      onEmptyAction: state.searchQuery.isEmpty
          ? _openAddDialog
          : () {
              _searchController.clear();
              context.read<CategoryBloc>().add(const SearchCategories(''));
            },
      columns: const [
        DataColumn(label: Text('ID'), numeric: true),
        DataColumn(label: Text('Category Name')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Created Date')),
        DataColumn(label: Text('Updated Date')),
        DataColumn(label: Text('Actions')),
      ],
      rows: categories.map((cat) {
        final createdFormatted =
            cat.createdAt.isNotEmpty ? cat.createdAt.split('T').first : '--';
        final updatedFormatted =
            cat.updatedAt != null ? cat.updatedAt!.split('T').first : '--';

        return DataRow(
          cells: [
            DataCell(Text('#${cat.id ?? "--"}')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cat.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  cat.description ?? '--',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: cat.description != null
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(createdFormatted, style: AppTextStyles.caption)),
            DataCell(Text(updatedFormatted, style: AppTextStyles.caption)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit Category',
                    splashRadius: 18,
                    onPressed: () => _openEditDialog(cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Delete Category',
                    splashRadius: 18,
                    onPressed: () => _confirmDelete(cat),
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
