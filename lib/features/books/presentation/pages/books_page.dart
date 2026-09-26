import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/category.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/data_table_wrapper.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../shared/widgets/search_field.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../bloc/books_bloc.dart';
import '../widgets/book_form_dialog.dart';

/// Professional Windows Desktop Books Catalog and Inventory Management Page
class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final booksBloc = context.read<BooksBloc>();
    if (booksBloc.state is BooksInitial) {
      booksBloc.add(const LoadBooks());
    }

    final categoryBloc = context.read<CategoryBloc>();
    if (categoryBloc.state is CategoryInitial) {
      categoryBloc.add(const LoadCategories());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Category> _getCachedCategories() {
    final catState = context.read<CategoryBloc>().state;
    if (catState is CategoryLoaded) {
      return catState.categories;
    }
    return const [];
  }

  void _openAddDialog() {
    final categories = _getCachedCategories();
    BookFormDialog.show(
      context,
      categories: categories,
      onSave: (book) {
        context.read<BooksBloc>().add(AddBook(book));
      },
    );
  }

  void _openEditDialog(Book book) {
    final categories = _getCachedCategories();
    BookFormDialog.show(
      context,
      book: book,
      categories: categories,
      onSave: (updated) {
        context.read<BooksBloc>().add(UpdateBook(updated));
      },
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Book?',
      message:
          'Are you sure you want to delete "${book.name}"? If historical purchase or sales records exist, deletion will be safely rejected.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed && book.id != null && mounted) {
      context.read<BooksBloc>().add(DeleteBook(book.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BooksBloc, BooksState>(
        listener: (context, state) {
          if (state is BooksLoaded) {
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
              context.read<BooksBloc>().add(const ClearBookMessages());
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
              context.read<BooksBloc>().add(const ClearBookMessages());
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
                  title: 'Books Catalog',
                  subtitle:
                      'Master book registry, pricing tiers, and real-time inventory levels.',
                  actions: [
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        context.read<BooksBloc>().add(const RefreshBooks());
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Add Book',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _openAddDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search & Filter Toolbar
                _buildFilterBar(state),
                const SizedBox(height: 20),

                // Content View
                if (state is BooksLoading)
                  const LoadingIndicator(
                    message: 'Loading books from local SQLite database...',
                  )
                else if (state is BooksError)
                  ErrorState(
                    title: 'Failed to load books catalog',
                    message: state.message,
                    onRetry: () =>
                        context.read<BooksBloc>().add(const LoadBooks()),
                  )
                else if (state is BooksLoaded)
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

  Widget _buildFilterBar(BooksState state) {
    final selectedCategoryId =
        state is BooksLoaded ? state.selectedCategoryId : null;

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final categories =
            catState is CategoryLoaded ? catState.categories : <Category>[];

        return Row(
          children: [
            // Search Input
            Expanded(
              flex: 3,
              child: SearchField(
                hint: 'Search by title, ISBN, author, or publisher...',
                controller: _searchController,
                onChanged: (query) {
                  context.read<BooksBloc>().add(SearchBooks(query));
                },
                onClear: () {
                  context.read<BooksBloc>().add(const SearchBooks(''));
                },
              ),
            ),
            const SizedBox(width: 16),

            // Category Filter Dropdown
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedCategoryId,
                  hint: const Text('All Categories'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((c) {
                      return DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }),
                  ],
                  onChanged: (catId) {
                    context
                        .read<BooksBloc>()
                        .add(FilterBooksByCategory(catId));
                  },
                ),
              ),
            ),

            if (selectedCategoryId != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Clear Category Filter',
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textSecondary,
                onPressed: () {
                  context
                      .read<BooksBloc>()
                      .add(const FilterBooksByCategory(null));
                },
              ),
            ],

            const Spacer(flex: 2),
          ],
        );
      },
    );
  }

  Widget _buildTable(BooksLoaded state) {
    final books = state.books;
    final categories = _getCachedCategories();
    final catMap = {for (var c in categories) c.id: c.name};

    final isFiltered =
        state.searchQuery.isNotEmpty || state.selectedCategoryId != null;

    return DataTableWrapper(
      title: 'Books Catalog (${books.length} items)',
      minWidth: 1200,
      emptyIcon: Icons.menu_book_outlined,
      emptyTitle:
          isFiltered ? 'No books match the filters' : 'No books in catalog yet',
      emptyMessage: isFiltered
          ? 'Try adjusting your search keywords or switching category to "All Categories".'
          : 'Register your first book title into the wholesale management database.',
      emptyActionLabel:
          isFiltered ? 'Clear All Filters' : 'Add First Book Title',
      onEmptyAction: isFiltered
          ? () {
              _searchController.clear();
              context.read<BooksBloc>().add(const SearchBooks(''));
              context.read<BooksBloc>().add(const FilterBooksByCategory(null));
            }
          : _openAddDialog,
      columns: const [
        DataColumn(label: Text('ID'), numeric: true),
        DataColumn(label: Text('Book Title')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('ISBN')),
        DataColumn(label: Text('Author')),
        DataColumn(label: Text('Publisher')),
        DataColumn(label: Text('Purchase Price'), numeric: true),
        DataColumn(label: Text('Wholesale Price'), numeric: true),
        DataColumn(label: Text('Retail Price'), numeric: true),
        DataColumn(label: Text('Stock'), numeric: true),
        DataColumn(label: Text('Min Alert'), numeric: true),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: books.map((book) {
        final categoryName =
            book.categoryId != null ? (catMap[book.categoryId] ?? 'ID #${book.categoryId}') : 'Uncategorized';

        return DataRow(
          cells: [
            DataCell(Text('#${book.id ?? "--"}')),
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
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      book.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Text(
                  categoryName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DataCell(Text(book.isbn ?? '--', style: AppTextStyles.caption)),
            DataCell(Text(book.author ?? '--', style: AppTextStyles.bodyMedium)),
            DataCell(Text(book.publisher ?? '--', style: AppTextStyles.bodyMedium)),
            DataCell(Text('Rs. ${book.purchasePrice.toStringAsFixed(2)}')),
            DataCell(
              Text(
                'Rs. ${book.wholesalePrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataCell(Text('Rs. ${book.retailPrice.toStringAsFixed(2)}')),
            DataCell(
              Text(
                '${book.stockQuantity}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: book.stockQuantity <= 0
                      ? AppColors.error
                      : (book.stockQuantity <= book.minimumStock
                          ? AppColors.warning
                          : AppColors.textPrimary),
                ),
              ),
            ),
            DataCell(Text('${book.minimumStock}', style: AppTextStyles.caption)),
            DataCell(_buildStatusBadge(book)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit Book Details',
                    splashRadius: 18,
                    onPressed: () => _openEditDialog(book),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Delete Book',
                    splashRadius: 18,
                    onPressed: () => _confirmDelete(book),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(Book book) {
    if (book.stockQuantity <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Out of Stock',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else if (book.stockQuantity <= book.minimumStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Low Stock',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'In Stock',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
  }
}
