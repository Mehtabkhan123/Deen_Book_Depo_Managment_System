import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/purchase_item.dart';
import '../../../../shared/models/supplier.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Professional Windows Desktop dialog for entering a wholesale purchase invoice
class PurchaseFormDialog extends StatefulWidget {
  final List<Supplier> suppliers;
  final List<Book> books;
  final void Function(Purchase purchase, List<PurchaseItem> items) onSave;

  const PurchaseFormDialog({
    super.key,
    required this.suppliers,
    required this.books,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Supplier> suppliers,
    required List<Book> books,
    required void Function(Purchase purchase, List<PurchaseItem> items) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PurchaseFormDialog(
        suppliers: suppliers,
        books: books,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends State<PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSupplierId;
  late final TextEditingController _invoiceController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  late final TextEditingController _overallDiscountController;
  late final TextEditingController _paidAmountController;

  // New Item Row Controllers
  int? _selectedBookId;
  late final TextEditingController _itemQtyController;
  late final TextEditingController _itemPriceController;
  late final TextEditingController _itemDiscountController;

  final List<PurchaseItem> _items = [];
  String? _itemError;

  @override
  void initState() {
    super.initState();
    _invoiceController = TextEditingController();
    _dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    _notesController = TextEditingController();
    _overallDiscountController = TextEditingController(text: '0.00');
    _paidAmountController = TextEditingController(text: '0.00');

    _itemQtyController = TextEditingController(text: '1');
    _itemPriceController = TextEditingController(text: '0.00');
    _itemDiscountController = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _overallDiscountController.dispose();
    _paidAmountController.dispose();

    _itemQtyController.dispose();
    _itemPriceController.dispose();
    _itemDiscountController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _overallDiscount {
    return double.tryParse(_overallDiscountController.text.trim()) ?? 0.0;
  }

  double get _total {
    final t = _subtotal - _overallDiscount;
    return t < 0 ? 0.0 : t;
  }

  double get _paidAmount {
    return double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  }

  double get _remainingAmount {
    final r = _total - _paidAmount;
    return r < 0 ? 0.0 : r;
  }

  String get _paymentStatus {
    if (_total == 0.0) return 'PAID';
    if (_paidAmount >= _total) return 'PAID';
    if (_paidAmount > 0) return 'PARTIAL';
    return 'UNPAID';
  }

  void _onBookSelected(int? bookId) {
    setState(() {
      _selectedBookId = bookId;
      if (bookId != null) {
        final book = widget.books.firstWhere((b) => b.id == bookId);
        _itemPriceController.text = book.purchasePrice.toStringAsFixed(2);
      }
    });
  }

  void _addItem() {
    setState(() => _itemError = null);

    if (_selectedBookId == null) {
      setState(() => _itemError = 'Please select a book to add.');
      return;
    }

    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _itemError = 'Quantity must be at least 1.');
      return;
    }

    final unitPrice = double.tryParse(_itemPriceController.text.trim()) ?? -1;
    if (unitPrice < 0) {
      setState(() => _itemError = 'Unit price cannot be negative.');
      return;
    }

    final discount = double.tryParse(_itemDiscountController.text.trim()) ?? 0.0;
    if (discount < 0) {
      setState(() => _itemError = 'Item discount cannot be negative.');
      return;
    }

    final lineSubtotal = qty * unitPrice;
    if (discount > lineSubtotal) {
      setState(() => _itemError = 'Item discount cannot exceed line subtotal.');
      return;
    }

    final lineTotal = lineSubtotal - discount;
    final selectedBook = widget.books.firstWhere((b) => b.id == _selectedBookId);

    setState(() {
      _items.add(PurchaseItem(
        purchaseId: 0,
        bookId: _selectedBookId!,
        quantity: qty,
        unitPrice: unitPrice,
        discount: discount,
        total: lineTotal,
        bookName: selectedBook.name,
      ));

      // Reset item inputs
      _selectedBookId = null;
      _itemQtyController.text = '1';
      _itemPriceController.text = '0.00';
      _itemDiscountController.text = '0.00';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one item is required on the purchase invoice.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final subtotal = _subtotal;
    final discount = _overallDiscount;
    if (discount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Overall discount cannot be negative.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (discount > subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Overall discount cannot exceed subtotal.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final total = _total;
    final paid = _paidAmount;
    if (paid < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paid amount cannot be negative.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (paid > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paid amount cannot exceed total purchase invoice amount.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final invoiceNumber = _invoiceController.text.trim();
    final purchaseDate = _dateController.text.trim();
    final notes = _notesController.text.trim();

    final purchase = Purchase(
      supplierId: _selectedSupplierId!,
      invoiceNumber: invoiceNumber,
      purchaseDate: purchaseDate,
      subtotal: subtotal,
      discount: discount,
      total: total,
      paidAmount: paid,
      remainingAmount: _remainingAmount,
      paymentStatus: _paymentStatus,
      notes: notes.isEmpty ? null : notes,
    );

    widget.onSave(purchase, List.unmodifiable(_items));
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
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 820),
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
                        Icons.add_shopping_cart_rounded,
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
                            'Create Purchase Invoice',
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Record wholesale book intake from publishers and vendors. Automatically increments inventory stock.',
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
                const SizedBox(height: 14),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Purchase Information
                        _buildSectionHeader('1. Purchase Information', Icons.business_rounded),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: AppDropdown<int>(
                                label: 'Supplier / Publisher *',
                                hint: 'Select supplier account',
                                value: _selectedSupplierId,
                                items: widget.suppliers.map((s) {
                                  return DropdownMenuItem<int>(
                                    value: s.id,
                                    child: Text(
                                      '${s.name} (${s.phone ?? "--"})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedSupplierId = val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                key: const Key('purchase_invoice_input'),
                                label: 'Invoice Number *',
                                hint: 'e.g. PINV-2026-001',
                                controller: _invoiceController,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Invoice number is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: AppTextField(
                                label: 'Purchase Date *',
                                hint: 'YYYY-MM-DD',
                                controller: _dateController,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Purchase date is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // SECTION 2: Items Entry
                        _buildSectionHeader('2. Purchase Items Entry', Icons.library_books_rounded),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: AppDropdown<int>(
                                      label: 'Book Selection',
                                      hint: 'Select book to add',
                                      value: _selectedBookId,
                                      items: widget.books.map((b) {
                                        return DropdownMenuItem<int>(
                                          value: b.id,
                                          child: Text(
                                            '${b.name} [Stock: ${b.stockQuantity}]',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _onBookSelected,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      label: 'Qty',
                                      controller: _itemQtyController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      label: 'Unit Price',
                                      controller: _itemPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: AppTextField(
                                      label: 'Line Disc.',
                                      controller: _itemDiscountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: AppButton(
                                      label: 'Add Item',
                                      icon: Icons.add_rounded,
                                      variant: AppButtonVariant.primary,
                                      onPressed: _addItem,
                                    ),
                                  ),
                                ],
                              ),
                              if (_itemError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _itemError!,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Added Items Table
                        if (_items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.neutral200, style: BorderStyle.solid),
                            ),
                            child: Text(
                              'No books added yet. Select a book above and click "Add Item".',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.neutral200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppColors.neutral50),
                                  dataRowMinHeight: 38,
                                  dataRowMaxHeight: 48,
                                  columnSpacing: 20,
                                  columns: const [
                                    DataColumn(label: Text('Book')),
                                    DataColumn(label: Text('Qty')),
                                    DataColumn(label: Text('Unit Price')),
                                    DataColumn(label: Text('Discount')),
                                    DataColumn(label: Text('Line Total')),
                                    DataColumn(label: Text('Remove')),
                                  ],
                                  rows: _items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item.bookName ?? 'Book #${item.bookId}')),
                                        DataCell(Text('${item.quantity}')),
                                        DataCell(Text('Rs. ${item.unitPrice.toStringAsFixed(2)}')),
                                        DataCell(Text('Rs. ${item.discount.toStringAsFixed(2)}')),
                                        DataCell(
                                          Text(
                                            'Rs. ${item.total.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                            color: AppColors.error,
                                            splashRadius: 18,
                                            onPressed: () => _removeItem(idx),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),

                        // SECTION 3: Summary & Settlement
                        _buildSectionHeader('3. Financial Settlement', Icons.account_balance_wallet_outlined),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.neutral200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Items Subtotal', style: AppTextStyles.caption),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rs. ${_subtotal.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Overall Discount',
                                controller: _overallDiscountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Net Total Payable', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rs. ${_total.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Paid Amount',
                                controller: _paidAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _remainingAmount > 0
                                      ? AppColors.errorLight.withValues(alpha: 0.5)
                                      : AppColors.successLight.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _remainingAmount > 0
                                        ? AppColors.error.withValues(alpha: 0.3)
                                        : AppColors.success.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Remaining: $_paymentStatus',
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _remainingAmount > 0 ? AppColors.errorText : AppColors.successText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rs. ${_remainingAmount.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: _remainingAmount > 0 ? AppColors.errorText : AppColors.successText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Internal Notes (Optional)',
                          hint: 'Supplier delivery batch, transport receipt, or terms',
                          controller: _notesController,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
                const SizedBox(height: 16),

                // Footer Actions
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
                      label: 'Save Purchase Invoice',
                      icon: Icons.check_circle_outline_rounded,
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
}
