import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Desktop-tailored wholesale sales invoice entry dialog
class SaleFormDialog extends StatefulWidget {
  final List<Customer> customers;
  final List<Book> books;
  final void Function(Sale sale, List<SaleItem> items) onSave;

  const SaleFormDialog({
    super.key,
    required this.customers,
    required this.books,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Customer> customers,
    required List<Book> books,
    required void Function(Sale sale, List<SaleItem> items) onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SaleFormDialog(
        customers: customers,
        books: books,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SaleFormDialog> createState() => _SaleFormDialogState();
}

class _SaleFormDialogState extends State<SaleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Header controllers
  late final TextEditingController _invoiceController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  int? _selectedCustomerId; // null represents Cash / Walk-in Customer

  // Item input controllers
  int? _selectedBookId;
  final _itemQtyController = TextEditingController(text: '1');
  final _itemPriceController = TextEditingController(text: '0.00');
  final _itemDiscountController = TextEditingController(text: '0.00');

  // Overall financial controllers
  final _overallDiscountController = TextEditingController(text: '0.00');
  final _paidAmountController = TextEditingController(text: '0.00');

  // In-memory line items
  final List<SaleItem> _items = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final autoInv =
        'SINV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    _invoiceController = TextEditingController(text: autoInv);
    _dateController = TextEditingController(text: dateStr);
    _notesController = TextEditingController();

    _itemQtyController.addListener(_onMathChanged);
    _itemPriceController.addListener(_onMathChanged);
    _itemDiscountController.addListener(_onMathChanged);
    _overallDiscountController.addListener(_onMathChanged);
    _paidAmountController.addListener(_onMathChanged);
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _itemQtyController.dispose();
    _itemPriceController.dispose();
    _itemDiscountController.dispose();
    _overallDiscountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _onMathChanged() {
    if (mounted) setState(() {});
  }

  Book? get _currentSelectedBook {
    if (_selectedBookId == null) return null;
    try {
      return widget.books.firstWhere((b) => b.id == _selectedBookId);
    } catch (_) {
      return null;
    }
  }

  int _getBookTotalRequestedQty(int bookId) {
    return _items
        .where((i) => i.bookId == bookId)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  void _onBookSelected(int? bookId) {
    setState(() {
      _selectedBookId = bookId;
      if (bookId != null) {
        final book = widget.books.firstWhere((b) => b.id == bookId);
        _itemPriceController.text = book.wholesalePrice.toStringAsFixed(2);
      }
    });
  }

  // Monetary & Settlement Calculations
  double get _lineSubtotal {
    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    final price = double.tryParse(_itemPriceController.text.trim()) ?? 0.0;
    return qty * price;
  }

  double get _lineTotal {
    final discount = double.tryParse(_itemDiscountController.text.trim()) ?? 0.0;
    final total = _lineSubtotal - discount;
    return total < 0 ? 0.0 : total;
  }

  double get _subtotal {
    return _items.fold(0.0, (acc, item) => acc + item.total);
  }

  double get _overallDiscount {
    return double.tryParse(_overallDiscountController.text.trim()) ?? 0.0;
  }

  double get _total {
    final sub = _subtotal;
    final disc = _overallDiscount;
    final tot = sub - disc;
    return tot < 0 ? 0.0 : tot;
  }

  double get _paidAmount {
    return double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  }

  double get _remainingAmount {
    final rem = _total - _paidAmount;
    return rem < 0 ? 0.0 : rem;
  }

  String get _paymentStatus {
    final tot = _total;
    final paid = _paidAmount;
    if (tot == 0) return 'PAID';
    if (paid >= tot) return 'PAID';
    if (paid > 0 && paid < tot) return 'PARTIAL';
    return 'UNPAID';
  }

  void _addItem() {
    if (_selectedBookId == null) {
      _showWarning('Please select a book to add to this sales invoice.');
      return;
    }

    final book = _currentSelectedBook;
    if (book == null) return;

    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showWarning('Item quantity must be greater than zero.');
      return;
    }

    final price = double.tryParse(_itemPriceController.text.trim()) ?? 0.0;
    if (price < 0) {
      _showWarning('Unit selling price cannot be negative.');
      return;
    }

    final discount = double.tryParse(_itemDiscountController.text.trim()) ?? 0.0;
    if (discount < 0) {
      _showWarning('Line discount cannot be negative.');
      return;
    }

    final lineSubtotal = qty * price;
    if (discount > lineSubtotal) {
      _showWarning('Line discount cannot exceed line subtotal (Rs. ${lineSubtotal.toStringAsFixed(2)}).');
      return;
    }

    // Cumulative stock verification
    final existingRequested = _getBookTotalRequestedQty(book.id!);
    final totalRequested = existingRequested + qty;
    if (totalRequested > book.stockQuantity) {
      _showWarning(
        'Insufficient stock for "${book.name}". Available: ${book.stockQuantity}, Already in Invoice: $existingRequested, Requested: $qty.',
      );
      return;
    }

    final lineTot = lineSubtotal - discount;

    setState(() {
      _items.add(SaleItem(
        saleId: 0,
        bookId: book.id!,
        quantity: qty,
        unitPrice: price,
        discount: discount,
        total: lineTot,
        bookName: book.name,
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

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      _showWarning('At least one line item is required on the sales invoice.');
      return;
    }

    // Pre-validate cumulative stock for all books against available stock
    final requestedMap = <int, int>{};
    for (final item in _items) {
      requestedMap[item.bookId] =
          (requestedMap[item.bookId] ?? 0) + item.quantity;
    }

    for (final entry in requestedMap.entries) {
      final book = widget.books.firstWhere((b) => b.id == entry.key);
      if (entry.value > book.stockQuantity) {
        _showWarning(
          'Insufficient stock for "${book.name}". Available: ${book.stockQuantity}, Requested: ${entry.value}.',
        );
        return;
      }
    }

    final subtotal = _subtotal;
    final discount = _overallDiscount;
    if (discount < 0) {
      _showWarning('Overall discount cannot be negative.');
      return;
    }
    if (subtotal > 0 && discount > subtotal) {
      _showWarning('Overall discount cannot exceed invoice subtotal.');
      return;
    }

    final total = _total;
    final paid = _paidAmount;
    if (paid < 0) {
      _showWarning('Paid amount cannot be negative.');
      return;
    }
    if (total > 0 && paid > total) {
      _showWarning('Paid amount cannot exceed total invoice amount.');
      return;
    }

    final invoiceNumber = _invoiceController.text.trim();
    final saleDate = _dateController.text.trim();
    final notes = _notesController.text.trim();

    final sale = Sale(
      customerId: _selectedCustomerId, // null if Cash / Walk-in
      invoiceNumber: invoiceNumber,
      saleDate: saleDate,
      subtotal: subtotal,
      discount: discount,
      total: total,
      paidAmount: paid,
      remainingAmount: _remainingAmount,
      paymentStatus: _paymentStatus,
      notes: notes.isEmpty ? null : notes,
    );

    widget.onSave(sale, List.unmodifiable(_items));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1020,
        height: 780,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              offset: Offset(0, 10),
              blurRadius: 28,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: AppColors.neutral200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
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
                            'Create Wholesale Sales Invoice',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select customer or cash walk-in, add book items, and settle payment.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textSecondary,
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Form Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: Sale Information
                      _buildSectionHeader('1. Sales Invoice Information', Icons.receipt_long_rounded),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer selector
                          Expanded(
                            flex: 4,
                            child: AppDropdown<int?>(
                              label: 'Customer Account / Sale Channel *',
                              hint: 'Select customer or cash walk-in',
                              value: _selectedCustomerId,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline_rounded, size: 16, color: AppColors.successText),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Cash / Walk-in Customer (No Ledger)',
                                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.successText),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...widget.customers.map((c) {
                                  return DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(
                                      '${c.name} (${c.phone ?? "--"})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) => setState(() => _selectedCustomerId = val),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Invoice Number
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              key: const Key('sale_invoice_input'),
                              label: 'Invoice Number *',
                              hint: 'e.g. SINV-2026-001',
                              controller: _invoiceController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Invoice number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Sale Date
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: 'Sale Date *',
                              hint: 'YYYY-MM-DD',
                              controller: _dateController,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Sale date is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // SECTION 2: Sale Items Entry
                      _buildSectionHeader('2. Wholesale Sale Items', Icons.menu_book_rounded),
                      const SizedBox(height: 12),

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
                                // Book selector
                                Expanded(
                                  flex: 5,
                                  child: AppDropdown<int>(
                                    label: 'Select Book Title *',
                                    hint: 'Choose book to sell...',
                                    value: _selectedBookId,
                                    items: widget.books.map((b) {
                                      final avail = b.stockQuantity - _getBookTotalRequestedQty(b.id!);
                                      return DropdownMenuItem<int>(
                                        value: b.id,
                                        child: Text(
                                          '${b.name} [Avail: $avail] (W.Price: Rs. ${b.wholesalePrice.toStringAsFixed(2)})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _onBookSelected,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Quantity
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    label: 'Qty',
                                    controller: _itemQtyController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Wholesale Unit Price
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    label: 'Unit Price',
                                    controller: _itemPriceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Line Discount
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    label: 'Line Disc.',
                                    controller: _itemDiscountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Add button
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: AppButton(
                                    label: 'Add Item',
                                    icon: Icons.add_shopping_cart_rounded,
                                    onPressed: _addItem,
                                  ),
                                ),
                              ],
                            ),

                            // Real-time stock & calculation indicator
                            if (_currentSelectedBook != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Available Stock: ${_currentSelectedBook!.stockQuantity} units',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _currentSelectedBook!.stockQuantity <= 0
                                          ? AppColors.errorText
                                          : AppColors.successText,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Calculated Line Total: Rs. ${_lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Items Table
                      if (_items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.neutral200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No items added yet. Select a book above and click "Add Item".',
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
                                  DataColumn(label: Text('Book Title')),
                                  DataColumn(label: Text('Qty')),
                                  DataColumn(label: Text('Unit Price')),
                                  DataColumn(label: Text('Line Discount')),
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

                      // SECTION 3: Summary & Financial Settlement
                      _buildSectionHeader('3. Financial Settlement', Icons.account_balance_wallet_outlined),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                AppTextField(
                                  label: 'Overall Invoice Discount (Rs.)',
                                  controller: _overallDiscountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  label: 'Paid Amount (Rs.)',
                                  controller: _paidAmountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  label: 'Notes / Remarks (Optional)',
                                  hint: 'e.g. Bulk order discount applied',
                                  controller: _notesController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Calculation Summary Box
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.neutral50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.neutral200),
                              ),
                              child: Column(
                                children: [
                                  _buildSummaryRow('Subtotal (Items Total):', 'Rs. ${_subtotal.toStringAsFixed(2)}', false),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow('Invoice Discount:', '- Rs. ${_overallDiscount.toStringAsFixed(2)}', false),
                                  const Divider(height: 16, thickness: 1, color: AppColors.neutral200),
                                  _buildSummaryRow('Net Total Payable:', 'Rs. ${_total.toStringAsFixed(2)}', true, AppColors.primary),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow('Paid Amount:', 'Rs. ${_paidAmount.toStringAsFixed(2)}', false, AppColors.successText),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'Remaining Balance:',
                                    'Rs. ${_remainingAmount.toStringAsFixed(2)}',
                                    true,
                                    _remainingAmount > 0 ? AppColors.errorText : AppColors.textSecondary,
                                  ),
                                  const Divider(height: 16, thickness: 1, color: AppColors.neutral200),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payment Status:',
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      _buildStatusBadge(_paymentStatus),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Dialog Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: AppColors.neutral200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Save Wholesale Sale',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
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

  Widget _buildSummaryRow(String label, String value, bool bold, [Color? color]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
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
}
