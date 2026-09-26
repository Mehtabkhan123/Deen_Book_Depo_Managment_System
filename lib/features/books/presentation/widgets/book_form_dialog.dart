import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/category.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Professional Windows Desktop dialog for creating and editing book catalog items
class BookFormDialog extends StatefulWidget {
  final Book? book;
  final List<Category> categories;
  final ValueChanged<Book> onSave;

  const BookFormDialog({
    super.key,
    this.book,
    required this.categories,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Book? book,
    required List<Category> categories,
    required ValueChanged<Book> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookFormDialog(
        book: book,
        categories: categories,
        onSave: onSave,
      ),
    );
  }

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _isbnController;
  late final TextEditingController _authorController;
  late final TextEditingController _publisherController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _wholesalePriceController;
  late final TextEditingController _retailPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;

  int? _selectedCategoryId;

  bool get isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _nameController = TextEditingController(text: b?.name ?? '');
    _isbnController = TextEditingController(text: b?.isbn ?? '');
    _authorController = TextEditingController(text: b?.author ?? '');
    _publisherController = TextEditingController(text: b?.publisher ?? '');
    _purchasePriceController = TextEditingController(
      text: b != null ? b.purchasePrice.toStringAsFixed(2) : '0.00',
    );
    _wholesalePriceController = TextEditingController(
      text: b != null ? b.wholesalePrice.toStringAsFixed(2) : '0.00',
    );
    _retailPriceController = TextEditingController(
      text: b != null ? b.retailPrice.toStringAsFixed(2) : '0.00',
    );
    _stockController = TextEditingController(
      text: b != null ? b.stockQuantity.toString() : '0',
    );
    _minStockController = TextEditingController(
      text: b != null ? b.minimumStock.toString() : '5',
    );

    _selectedCategoryId = b?.categoryId;
    // If category is not in list (e.g. deleted or null), keep null
    if (_selectedCategoryId != null &&
        !widget.categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _purchasePriceController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final trimmedIsbn = _isbnController.text.trim();
    final trimmedAuthor = _authorController.text.trim();
    final trimmedPublisher = _publisherController.text.trim();

    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final wholesalePrice = double.tryParse(_wholesalePriceController.text.trim()) ?? 0.0;
    final retailPrice = double.tryParse(_retailPriceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 0;

    final book = Book(
      id: widget.book?.id,
      categoryId: _selectedCategoryId,
      name: trimmedName,
      isbn: trimmedIsbn.isEmpty ? null : trimmedIsbn,
      author: trimmedAuthor.isEmpty ? null : trimmedAuthor,
      publisher: trimmedPublisher.isEmpty ? null : trimmedPublisher,
      purchasePrice: purchasePrice,
      wholesalePrice: wholesalePrice,
      retailPrice: retailPrice,
      stockQuantity: stock,
      minimumStock: minStock,
      createdAt: widget.book?.createdAt ?? '',
    );

    widget.onSave(book);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      backgroundColor: AppColors.surface,
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Book Details' : 'Add New Book Title',
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Update master catalog record, pricing, and stock alerts'
                                : 'Register a new title into the wholesale inventory',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
                const SizedBox(height: 16),

                // Scrollable Form Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Basic Information
                        _buildSectionHeader('Basic Information', Icons.info_outline_rounded),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Book Title *',
                          hint: 'e.g. Sahih Al-Bukhari Vol 1, Urdu Grammar Class 9',
                          controller: _nameController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Book title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Dropdown
                            Expanded(
                              flex: 3,
                              child: AppDropdown<int>(
                                label: 'Category',
                                hint: 'Select classification',
                                value: _selectedCategoryId,
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('None / Uncategorized'),
                                  ),
                                  ...widget.categories.map((c) {
                                    return DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.name),
                                    );
                                  }),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryId = val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // ISBN Field
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                label: 'ISBN / Barcode',
                                hint: '978-XXXXXXXXXX',
                                controller: _isbnController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // SECTION 2: Publication Information
                        _buildSectionHeader('Publication Details', Icons.business_outlined),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Author',
                                hint: 'e.g. Imam Bukhari, Allama Iqbal',
                                controller: _authorController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                label: 'Publisher',
                                hint: 'e.g. Maktaba Darussalam, Ferozsons',
                                controller: _publisherController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // SECTION 3: Pricing
                        _buildSectionHeader('Pricing (PKR / Currency)', Icons.payments_outlined),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Purchase Cost *',
                                hint: '0.00',
                                controller: _purchasePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: _validateNonNegativeNumber,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                label: 'Wholesale Price *',
                                hint: '0.00',
                                controller: _wholesalePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: _validateNonNegativeNumber,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                label: 'Retail Price *',
                                hint: '0.00',
                                controller: _retailPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: _validateNonNegativeNumber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // SECTION 4: Inventory
                        _buildSectionHeader('Inventory & Stock Alerts', Icons.inventory_2_outlined),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Initial Stock *',
                                hint: '0',
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                validator: _validateNonNegativeInt,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                label: 'Minimum Stock Alert *',
                                hint: '5',
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                validator: _validateNonNegativeInt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: isEditing ? 'Save Book Changes' : 'Register Book',
                      icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String? _validateNonNegativeNumber(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Price is required';
    }
    final num = double.tryParse(val.trim());
    if (num == null) {
      return 'Invalid number';
    }
    if (num < 0) {
      return 'Cannot be negative';
    }
    return null;
  }

  String? _validateNonNegativeInt(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Field is required';
    }
    final num = int.tryParse(val.trim());
    if (num == null) {
      return 'Must be an integer';
    }
    if (num < 0) {
      return 'Cannot be negative';
    }
    return null;
  }
}
