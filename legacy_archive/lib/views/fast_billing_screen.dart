import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/book_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../services/db_service.dart';
import '../services/printing_service.dart';

class BasketLineItem {
  final BookProduct book;
  int quantity;
  double unitPrice;
  final TextEditingController qtyController;

  BasketLineItem({
    required this.book,
    this.quantity = 1,
    double? unitPrice,
  })  : unitPrice = unitPrice ?? book.wholesalePrice,
        qtyController = TextEditingController(text: (quantity).toString());

  int get cartons => book.unitsPerCarton > 0 ? quantity ~/ book.unitsPerCarton : 0;
  int get looseUnits => book.unitsPerCarton > 0 ? quantity % book.unitsPerCarton : quantity;
  double get lineTotal => quantity * unitPrice;

  void dispose() {
    qtyController.dispose();
  }
}

class FastBillingScreen extends StatefulWidget {
  final DbService dbService;

  const FastBillingScreen({super.key, required this.dbService});

  @override
  State<FastBillingScreen> createState() => _FastBillingScreenState();
}

class _FastBillingScreenState extends State<FastBillingScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _paidController = TextEditingController();

  final List<BasketLineItem> _basket = [];
  List<BookProduct> _searchResults = [];
  List<CustomerModel> _allCustomers = [];
  CustomerModel? _selectedCustomer;

  String _paymentMethod = 'Cash'; // 'Cash', 'Credit / On Account', 'Bank Transfer'
  bool _isProcessing = false;
  final NumberFormat _currency = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    // Request focus on initialization as required
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusSearchBox();
    });
  }

  void _focusSearchBox() {
    if (mounted) {
      _searchFocusNode.requestFocus();
    }
  }

  void _loadCustomers() {
    setState(() {
      _allCustomers = widget.dbService.getAllCustomers();
    });
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _searchResults = widget.dbService.searchBooks(query);
    });
  }

  void _addBookToBasket(BookProduct book) {
    final existingIndex = _basket.indexWhere((item) => item.book.isbn == book.isbn);
    setState(() {
      if (existingIndex >= 0) {
        _basket[existingIndex].quantity += 1;
        _basket[existingIndex].qtyController.text = _basket[existingIndex].quantity.toString();
      } else {
        _basket.add(BasketLineItem(book: book, quantity: 1));
      }
      _searchController.clear();
      _searchResults = [];
    });
    _updateTotals();
    _focusSearchBox();
  }

  void _removeBasketItem(int index) {
    setState(() {
      _basket[index].dispose();
      _basket.removeAt(index);
    });
    _updateTotals();
    _focusSearchBox();
  }

  void _clearBasket() {
    setState(() {
      for (final item in _basket) {
        item.dispose();
      }
      _basket.clear();
      _discountController.text = '0';
      _paidController.clear();
    });
    _focusSearchBox();
  }

  double get _subtotal => _basket.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get _grandTotal => (_subtotal - _discount) > 0 ? (_subtotal - _discount) : 0.0;
  int get _totalUnits => _basket.fold(0, (sum, item) => sum + item.quantity);
  int get _totalCartons => _basket.fold(0, (sum, item) => sum + item.cartons);
  int get _totalLoose => _basket.fold(0, (sum, item) => sum + item.looseUnits);

  void _updateTotals() {
    setState(() {
      if (_paymentMethod == 'Cash') {
        _paidController.text = _grandTotal.toStringAsFixed(2);
      }
    });
  }

  Future<void> _processCheckoutAndPrint() async {
    if (_basket.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot process an empty receipt. Please add books first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _focusSearchBox();
      return;
    }

    if (_paymentMethod == 'Credit / On Account' && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an authorized Wholesale Customer for credit transactions.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final invoiceNum = 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final paidAmt = double.tryParse(_paidController.text.trim()) ?? (_paymentMethod == 'Cash' ? _grandTotal : 0.0);

      final embeddedItems = _basket.map((item) {
        return InvoiceItemEmbedded()
          ..bookIsbn = item.book.isbn
          ..title = item.book.title
          ..quantity = item.quantity
          ..unitsPerCarton = item.book.unitsPerCarton
          ..cartons = item.cartons
          ..looseUnits = item.looseUnits
          ..unitWholesalePrice = item.unitPrice
          ..lineTotal = item.lineTotal;
      }).toList();

      // Save to Isar DB (Decrements stock, creates invoice, updates customer debt ledger)
      final invoice = await widget.dbService.processSaleInvoice(
        invoiceNumber: invoiceNum,
        items: embeddedItems,
        subtotal: _subtotal,
        discountAmount: _discount,
        grandTotal: _grandTotal,
        amountPaid: paidAmt,
        paymentType: _paymentMethod,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name ?? 'Walk-in Bulk Counter Customer',
      );

      // Launch automated PDF system spooling
      await PrintingService.printInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Invoice #$invoiceNum saved & spooled to printer!'),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Reset billing workspace
      _clearBasket();
      _loadCustomers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finalizing sale: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Key Requirement: Fall back focus directly into main barcode box
        _focusSearchBox();
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _discountController.dispose();
    _paidController.dispose();
    for (final item in _basket) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;

        if (isWide) {
          return Container(
            color: const Color(0xFFF4F6FA),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Search Desk & Active Basket (60% screen weight)
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchHeaderCard(),
                        const SizedBox(height: 12),
                        Expanded(child: _buildBasketTableCard()),
                      ],
                    ),
                  ),
                ),

                // Right Settlement Column (40% screen weight)
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: _buildSettlementCard(),
                  ),
                ),
              ],
            ),
          );
        }

        // Narrow screen layout (stacked vertically with scrolling)
        return Container(
          color: const Color(0xFFF4F6FA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchHeaderCard(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 420,
                  child: _buildBasketTableCard(),
                ),
                const SizedBox(height: 16),
                _buildSettlementCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Search Header Desk
  Widget _buildSearchHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Color(0xFF1A237E), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Fast Search Desk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Autofocus Active • Barcode or Title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF283593)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: _onSearchChanged,
              onSubmitted: (val) {
                if (_searchResults.isNotEmpty) {
                  _addBookToBasket(_searchResults.first);
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter ISBN / Barcode or Book Title (e.g. 978... or Bukhari, Quran)...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          _focusSearchBox();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFC5CAE9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                ),
              ),
            ),
            // Autocomplete suggestion overlay if search results exist
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC5CAE9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final book = _searchResults[index];
                    final inStock = book.totalStockQuantity > 0;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: inStock ? const Color(0xFFE8EAF6) : Colors.red.shade50,
                        child: Icon(Icons.menu_book, size: 18, color: inStock ? const Color(0xFF1A237E) : Colors.red),
                      ),
                      title: Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'ISBN: ${book.isbn} • Author: ${book.author} • ${book.unitsPerCarton} pcs/ctn',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${_currency.format(book.wholesalePrice)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 13),
                              ),
                              Text(
                                'Stock: ${book.totalStockQuantity} (${book.cartons} ctn + ${book.looseUnits})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: inStock ? Colors.grey.shade700 : Colors.red,
                                  fontWeight: inStock ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Add', style: TextStyle(fontSize: 12)),
                            onPressed: () => _addBookToBasket(book),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 2. Receipt Basket Table
  Widget _buildBasketTableCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                const Text(
                  'Active Receipt Basket',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_basket.length} Line Items',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (_basket.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearBasket,
                    icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    label: const Text('Clear Basket', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            const Divider(height: 16),
            Expanded(
              child: _basket.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'The receipt basket is empty.',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan an ISBN or search a book title above to rapidly populate lines.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _basket.length,
                      separatorBuilder: (ctx, idx) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _basket[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          child: Row(
                            children: [
                              // Line Number
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: const Color(0xFFE8EAF6),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Book Title & ISBN
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.book.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'ISBN: ${item.book.isbn} • ${item.book.unitsPerCarton}/ctn',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Wholesale Unit Rate
                              SizedBox(
                                width: 75,
                                child: Text(
                                  'Rs. ${_currency.format(item.unitPrice)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Inline Quantity Editor
                              SizedBox(
                                width: 140,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                                      color: const Color(0xFF1A237E),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          setState(() {
                                            item.quantity -= 1;
                                            item.qtyController.text = item.quantity.toString();
                                          });
                                          _updateTotals();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 2),
                                    SizedBox(
                                      width: 44,
                                      height: 30,
                                      child: TextField(
                                        controller: item.qtyController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val) ?? 1;
                                          setState(() {
                                            item.quantity = parsed > 0 ? parsed : 1;
                                          });
                                          _updateTotals();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 18),
                                      color: const Color(0xFF1A237E),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                      onPressed: () {
                                        setState(() {
                                          item.quantity += 1;
                                          item.qtyController.text = item.quantity.toString();
                                        });
                                        _updateTotals();
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    // Quick carton breakdown
                                    Expanded(
                                      child: Text(
                                        item.cartons > 0 ? '${item.cartons}c+${item.looseUnits}' : '${item.quantity}u',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Line Total
                              SizedBox(
                                width: 85,
                                child: Text(
                                  'Rs. ${_currency.format(item.lineTotal)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20)),
                                ),
                              ),

                              // Remove button
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                onPressed: () => _removeBasketItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Right Settlement & Payment Column
  Widget _buildSettlementCard() {
    final bool isCredit = _paymentMethod == 'Credit / On Account';
    final double paidAmt = double.tryParse(_paidController.text.trim()) ?? 0.0;
    final double balanceDue = (_grandTotal - paidAmt) > 0 ? (_grandTotal - paidAmt) : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.point_of_sale, color: Color(0xFF1A237E), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Settlement & Billing',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
              ],
            ),
            const Divider(height: 20),

            // Wholesale Customer Selector
            const Text('Wholesale Account / Buyer:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<CustomerModel?>(
              initialValue: _selectedCustomer,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem<CustomerModel?>(
                  value: null,
                  child: Text('Walk-in Bulk Counter Customer (Cash)', style: TextStyle(fontSize: 13)),
                ),
                ..._allCustomers.map((c) {
                  return DropdownMenuItem<CustomerModel?>(
                    value: c,
                    child: Text(
                      '${c.name} (Debt: Rs. ${_currency.format(c.currentDebtBalance)})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ],
              onChanged: (customer) {
                setState(() {
                  _selectedCustomer = customer;
                });
              },
            ),

            if (_selectedCustomer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Credit Line Limit', style: TextStyle(fontSize: 10, color: Colors.black54)),
                        Text('Rs. ${_currency.format(_selectedCustomer!.creditLimit)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Current Debt / Due', style: TextStyle(fontSize: 10, color: Colors.black54)),
                        Text('Rs. ${_currency.format(_selectedCustomer!.currentDebtBalance)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Bulk Carton Breakdown Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricTile('Cartons', '$_totalCartons ctn'),
                  _metricTile('Loose Pcs', '$_totalLoose pcs'),
                  _metricTile('Total Units', '$_totalUnits units'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Calculations
            _summaryRow('Subtotal', 'Rs. ${_currency.format(_subtotal)}'),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Special Trade Discount (Rs.):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                SizedBox(
                  width: 120,
                  height: 36,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (val) => _updateTotals(),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Grand Total Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NET PAYABLE:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Rs. ${_currency.format(_grandTotal)}',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Payment Mode Selector
            const Text('Payment Settlement Mode:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                _paymentTypeChip('Cash'),
                const SizedBox(width: 8),
                _paymentTypeChip('Credit / On Account'),
                const SizedBox(width: 8),
                _paymentTypeChip('Bank Transfer'),
              ],
            ),

            const SizedBox(height: 12),

            // Amount Paid Input & Balance Due
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Tendered (Rs.):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                SizedBox(
                  width: 140,
                  height: 38,
                  child: TextField(
                    controller: _paidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCredit ? 'Receivable Balance (Added to Ledger):' : 'Remaining / Balance Due:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: balanceDue > 0 ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
                Text(
                  'Rs. ${_currency.format(balanceDue)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: balanceDue > 0 ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Major Action Trigger: "Save Bill & Print Invoice"
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print, size: 24),
                label: Text(
                  _isProcessing ? 'Processing Transaction...' : 'Save Bill & Print Invoice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                onPressed: _isProcessing ? null : _processCheckoutAndPrint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _paymentTypeChip(String type) {
    final isSelected = _paymentMethod == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _paymentMethod = type;
            if (type == 'Cash') {
              _paidController.text = _grandTotal.toStringAsFixed(2);
            } else if (type == 'Credit / On Account') {
              _paidController.text = '0';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A237E) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade400),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
