import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_destinations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/sale.dart';
import '../../../../shared/models/sale_item.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../books/presentation/bloc/books_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_bloc.dart';
import '../../../navigation/presentation/bloc/navigation_bloc.dart';
import '../bloc/sales_bloc.dart';
import '../widgets/sale_detail_dialog.dart';

/// POS Sale Pricing Tier
enum PosSaleTier { retail, wholesale }

/// Represents an item in the active POS checkout cart
class PosCartItem {
  final Book book;
  int quantity;
  double unitPrice;
  double discount;

  PosCartItem({
    required this.book,
    this.quantity = 1,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get subtotal => quantity * unitPrice;
  double get lineTotal {
    final net = subtotal - discount;
    return net < 0 ? 0.0 : net;
  }

  bool get isStockExceeded => quantity > book.stockQuantity;
}

/// Professional Windows Desktop POS Billing Screen for Retail & Wholesale Bookstore Sales
class PosBillingPage extends StatefulWidget {
  const PosBillingPage({super.key});

  @override
  State<PosBillingPage> createState() => _PosBillingPageState();
}

class _PosBillingPageState extends State<PosBillingPage> {
  // POS Configuration
  PosSaleTier _saleTier = PosSaleTier.retail;
  bool _isWalkIn = true;
  Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';

  // Invoice & Timing
  late String _invoiceNumber;
  late String _saleDate;

  // Search & Cart Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _overallDiscountController =
      TextEditingController(text: '0.00');
  final TextEditingController _paidAmountController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _notesController = TextEditingController();

  // Active Cart Items
  final List<PosCartItem> _cartItems = [];

  // Live Book Search Suggestions
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _saleDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _invoiceNumber = _generateInvoiceNumber(_saleTier);

    final salesBloc = context.read<SalesBloc>();
    if (salesBloc.state is SalesInitial) {
      salesBloc.add(const LoadSales());
    } else {
      salesBloc.add(const RefreshSales());
    }

    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _overallDiscountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateInvoiceNumber(PosSaleTier tier) {
    final prefix = tier == PosSaleTier.retail ? 'RET' : 'WHO';
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = millis.length >= 4
        ? millis.substring(millis.length - 4)
        : millis;
    return '$prefix-$dateStr-$suffix';
  }

  void _onSaleTierChanged(PosSaleTier newTier) {
    if (_saleTier == newTier) return;

    setState(() {
      _saleTier = newTier;
      _invoiceNumber = _generateInvoiceNumber(newTier);

      // Automatically update unit prices of existing cart items to the selected tier price
      for (final item in _cartItems) {
        item.unitPrice = newTier == PosSaleTier.retail
            ? item.book.retailPrice
            : item.book.wholesalePrice;
      }
      _syncPaidAmountIfFullPaid();
    });
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();

    if (q.isEmpty) {
      context.read<SalesBloc>().add(const ClearPosBookSearch());
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.read<SalesBloc>().add(SearchPosBooks(q));
      }
    });
  }

  void _onSearchSubmitted(String query, SalesLoaded? state) async {
    final q = query.trim();
    if (q.isEmpty) return;

    Book? targetBook;
    // 1. Check if there are active search results in state
    if (state != null && state.posSearchResults.isNotEmpty) {
      final qLower = q.toLowerCase();
      final cleanQ = qLower.replaceAll('-', '').replaceAll(' ', '');
      try {
        targetBook = state.posSearchResults.firstWhere((b) {
          final bIsbn = (b.isbn ?? '').toLowerCase();
          final bClean = bIsbn.replaceAll('-', '').replaceAll(' ', '');
          return bIsbn == qLower || (cleanQ.isNotEmpty && bClean == cleanQ);
        });
      } catch (_) {
        try {
          targetBook = state.posSearchResults.firstWhere(
            (b) => b.name.toLowerCase() == qLower,
          );
        } catch (_) {
          targetBook = state.posSearchResults.first;
        }
      }
    }

    // 2. Direct SQLite repository search fallback
    if (targetBook == null && mounted) {
      try {
        final matches =
            await context.read<SalesBloc>().bookRepository.search(q);
        if (matches.isNotEmpty) {
          final qLower = q.toLowerCase();
          final cleanQ = qLower.replaceAll('-', '').replaceAll(' ', '');
          try {
            targetBook = matches.firstWhere((b) {
              final bIsbn = (b.isbn ?? '').toLowerCase();
              final bClean = bIsbn.replaceAll('-', '').replaceAll(' ', '');
              return bIsbn == qLower || (cleanQ.isNotEmpty && bClean == cleanQ);
            });
          } catch (_) {
            targetBook = matches.first;
          }
        }
      } catch (_) {}
    }

    if (targetBook != null) {
      if (targetBook.stockQuantity <= 0) {
        _showSnackbar(
          'Cannot add "${targetBook.name}": Book is currently OUT OF STOCK (0 available in warehouse).',
          isError: true,
        );
        return;
      }
      _addBookToCart(targetBook);
      _searchController.clear();
      if (mounted) {
        context.read<SalesBloc>().add(const ClearPosBookSearch());
        _searchFocusNode.requestFocus();
      }
    } else {
      _showSnackbar('No book found matching "$q".', isError: true);
    }
  }

  void _addBookToCart(Book book) {
    if (book.stockQuantity <= 0) {
      _showSnackbar(
        'Cannot add "${book.name}": Book is OUT OF STOCK (0 available in warehouse).',
        isError: true,
      );
      return;
    }

    final existingIndex = _cartItems.indexWhere(
      (item) => item.book.id == book.id,
    );

    if (existingIndex >= 0) {
      final currentQty = _cartItems[existingIndex].quantity;
      if (currentQty + 1 > book.stockQuantity) {
        _showSnackbar(
          'Cannot add more: "${book.name}" has only ${book.stockQuantity} in stock (already in cart: $currentQty).',
          isError: true,
        );
        return;
      }
      setState(() {
        _cartItems[existingIndex].quantity += 1;
        _syncPaidAmountIfFullPaid();
      });
    } else {
      final initialPrice = _saleTier == PosSaleTier.retail
          ? book.retailPrice
          : book.wholesalePrice;

      setState(() {
        _cartItems.add(
          PosCartItem(book: book, quantity: 1, unitPrice: initialPrice),
        );
        _syncPaidAmountIfFullPaid();
      });
    }
  }

  void _updateCartItemQuantity(int index, int newQty) {
    if (newQty <= 0) return;
    setState(() {
      _cartItems[index].quantity = newQty;
      _syncPaidAmountIfFullPaid();
    });
  }

  void _removeCartItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _syncPaidAmountIfFullPaid();
    });
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    setState(() {
      _cartItems.clear();
      _overallDiscountController.text = '0.00';
      _paidAmountController.text = '0.00';
      _notesController.clear();
      _invoiceNumber = _generateInvoiceNumber(_saleTier);
    });
    _searchFocusNode.requestFocus();
  }

  // ==========================================
  // Calculations
  // ==========================================
  double get _itemsSubtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  double get _overallDiscount {
    return double.tryParse(_overallDiscountController.text.trim()) ?? 0.0;
  }

  double get _grandTotal {
    final total = _itemsSubtotal - _overallDiscount;
    return total < 0.0 ? 0.0 : total;
  }

  double get _paidOrTenderedAmount {
    return double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  }

  double get _changeDue {
    final tendered = _paidOrTenderedAmount;
    final total = _grandTotal;
    return tendered > total ? tendered - total : 0.0;
  }

  double get _remainingDue {
    final tendered = _paidOrTenderedAmount;
    final total = _grandTotal;
    return tendered < total ? total - tendered : 0.0;
  }

  String get _calculatedPaymentStatus {
    final tendered = _paidOrTenderedAmount;
    final total = _grandTotal;
    if (total <= 0) return 'PAID';
    if (tendered >= total) return 'PAID';
    if (tendered <= 0) return 'UNPAID';
    return 'PARTIAL';
  }

  void _syncPaidAmountIfFullPaid() {
    // If previously paid amount matches the total or is empty/default, auto-fill with new grand total
    final currentPaid =
        double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    if (currentPaid == 0.0 || currentPaid == _grandTotal) {
      _paidAmountController.text = _grandTotal.toStringAsFixed(2);
    }
  }

  void _setExactPaid() {
    setState(() {
      _paidAmountController.text = _grandTotal.toStringAsFixed(2);
    });
  }

  void _addCashTender(double extra) {
    final current = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    setState(() {
      _paidAmountController.text = (current + extra).toStringAsFixed(2);
    });
  }

  // ==========================================
  // Checkout Execution
  // ==========================================
  void _executeCheckout() {
    if (_cartItems.isEmpty) {
      _showSnackbar(
        'Cannot checkout: Cart is empty. Add at least one book.',
        isError: true,
      );
      return;
    }

    // 1. Validate Stock
    for (final item in _cartItems) {
      if (item.quantity > item.book.stockQuantity) {
        _showSnackbar(
          'Cannot checkout: "${item.book.name}" has only ${item.book.stockQuantity} in stock (requested ${item.quantity}).',
          isError: true,
        );
        return;
      }
    }

    // 2. Validate Customer Credit
    final status = _calculatedPaymentStatus;
    if ((status == 'UNPAID' || status == 'PARTIAL') && _isWalkIn) {
      _showSnackbar(
        'Credit or partial sales require a registered customer. Please select a customer or collect full payment.',
        isError: true,
      );
      return;
    }

    // 3. Compute final financial fields for SQLite record
    final grandTotal = _grandTotal;
    final tendered = _paidOrTenderedAmount;
    final effectivePaid = tendered >= grandTotal ? grandTotal : tendered;
    final remainingAmount = (grandTotal - effectivePaid) < 0.0
        ? 0.0
        : (grandTotal - effectivePaid);

    final rawSubtotal = _cartItems.fold(
      0.0,
      (sum, i) => sum + (i.quantity * i.unitPrice),
    );
    final totalDiscounts = rawSubtotal - grandTotal;

    final tierTag = _saleTier == PosSaleTier.retail
        ? '[RETAIL POS]'
        : '[WHOLESALE POS]';
    final notesText = _notesController.text.trim();
    final combinedNotes = notesText.isNotEmpty
        ? '$tierTag $notesText | Tendered: ${tendered.toStringAsFixed(2)}, Change: ${_changeDue.toStringAsFixed(2)}'
        : '$tierTag Tendered: ${tendered.toStringAsFixed(2)}, Change: ${_changeDue.toStringAsFixed(2)}';

    final sale = Sale(
      customerId: _isWalkIn ? null : _selectedCustomer?.id,
      invoiceNumber: _invoiceNumber.trim(),
      saleDate: _saleDate,
      subtotal: rawSubtotal,
      discount: totalDiscounts > 0 ? totalDiscounts : 0.0,
      total: grandTotal,
      paidAmount: effectivePaid,
      remainingAmount: remainingAmount,
      paymentStatus: status,
      notes: combinedNotes,
    );

    final saleItems = _cartItems.map((item) {
      return SaleItem(
        saleId: 0,
        bookId: item.book.id!,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discount: item.discount,
        total: item.lineTotal,
      );
    }).toList();

    // 4. Dispatch to SalesBloc
    context.read<SalesBloc>().add(CreateSale(sale: sale, items: saleItems));

    // 5. Refresh Books and Inventory
    context.read<BooksBloc>().add(const LoadBooks());
    context.read<InventoryBloc>().add(const LoadInventory());
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesBloc, SalesState>(
      listener: (context, state) {
        if (state is SalesLoaded) {
          if (state.selectedSale != null && state.selectedSaleItems != null) {
            final sale = state.selectedSale!;
            final items = state.selectedSaleItems!;
            final customerName = state.getCustomerName(sale.customerId);
            final customerPhone = state.getCustomerPhone(sale.customerId);
            final bookTitles = {
              for (final b in state.books.values)
                if (b.id != null) b.id!: b.name,
            };

            SaleDetailDialog.show(
              context,
              sale: sale,
              items: items,
              customerName: customerName,
              customerPhone: customerPhone,
              bookTitles: bookTitles,
            );
          }

          if (state.successMessage != null) {
            _showSnackbar(state.successMessage!);
            _clearCart();
            context.read<SalesBloc>().add(const ClearSaleMessages());
          } else if (state.errorMessage != null) {
            _showSnackbar(state.errorMessage!, isError: true);
            context.read<SalesBloc>().add(const ClearSaleMessages());
          }
        }
      },
      builder: (context, state) {
        if (state is SalesLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: LoadingIndicator(message: 'Loading POS Billing Terminal...'),
          );
        }

        final customers = state is SalesLoaded
            ? state.customers.values.toList()
            : <Customer>[];
        final recentSales = state is SalesLoaded
            ? state.sales.take(8).toList()
            : <Sale>[];
        final isCreating = state is SalesLoaded && state.isCreating;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Terminal Navigation Bar
                _buildTopBar(recentSales, state is SalesLoaded ? state : null),
                const SizedBox(height: 16),

                // Main POS Workstation Layout (Cart/Search & Settlement/Recent)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Section (65% width): Cart & Book Catalog
                      Expanded(
                        flex: 65,
                        child: _buildLeftCartSection(
                          state is SalesLoaded ? state : null,
                          isCreating,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Right Section (35% width): Settlement Drawer & Recent Invoices
                      Expanded(
                        flex: 35,
                        child: _buildRightSettlementSection(
                          customers,
                          recentSales,
                          isCreating,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(List<Sale> recentSales, SalesLoaded? loadedState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POS Billing Terminal',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'High-Speed Wholesale & Retail Counter Checkout',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Sale Tier Switcher (Retail vs Wholesale)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              children: [
                _buildTierButton(
                  title: 'RETAIL SALE',
                  icon: Icons.storefront_rounded,
                  tier: PosSaleTier.retail,
                  activeColor: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                _buildTierButton(
                  title: 'WHOLESALE SALE',
                  icon: Icons.inventory_2_rounded,
                  tier: PosSaleTier.wholesale,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // All Invoices button
          AppButton(
            label: 'All Invoices',
            icon: Icons.receipt_long_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () {
              context.read<NavigationBloc>().add(
                const NavigateTo(AppDestinations.sales),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTierButton({
    required String title,
    required IconData icon,
    required PosSaleTier tier,
    required Color activeColor,
  }) {
    final isSelected = _saleTier == tier;
    return InkWell(
      onTap: () => _onSaleTierChanged(tier),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Left Cart & Search Section
  // ==========================================
  Widget _buildLeftCartSection(SalesLoaded? loadedState, bool isCreating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barcode & Product Search Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Scan Barcode / Enter ISBN, Title, Author, or Publisher...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<SalesBloc>()
                                      .add(const ClearPosBookSearch());
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.neutral50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.neutral200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: _onSearchQueryChanged,
                      onSubmitted: (val) =>
                          _onSearchSubmitted(val, loadedState),
                    ),
                  ),
                ],
              ),

              // Live Search Autocomplete Results & States
              if (loadedState != null &&
                  loadedState.posBookSearchQuery.isNotEmpty) ...[
                const SizedBox(height: 10),
                if (loadedState.isSearchingPosBooks)
                  // 1. Loading State
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Searching bookstore catalog in database...',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (loadedState.posSearchError != null)
                  // 2. Error State
                  Material(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.errorText,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loadedState.posSearchError!,
                              style: const TextStyle(
                                color: AppColors.errorText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (loadedState.posSearchResults.isEmpty)
                  // 3. Empty State
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No books found matching "${loadedState.posBookSearchQuery}"',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Search by Book Title, ISBN, Barcode, Author, or Publisher.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // 4. Results List
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    shadowColor: const Color(0x15000000),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: loadedState.posSearchResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.neutral100),
                        itemBuilder: (context, index) {
                          final book = loadedState.posSearchResults[index];
                          final price = _saleTier == PosSaleTier.retail
                              ? book.retailPrice
                              : book.wholesalePrice;
                          final isOutOfStock = book.stockQuantity <= 0;
                          final isLow = !isOutOfStock &&
                              book.stockQuantity <= book.minimumStock;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isOutOfStock
                                    ? AppColors.neutral200
                                    : AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: isOutOfStock
                                      ? AppColors.neutral500
                                      : AppColors.primary,
                                ),
                              ),
                              title: Text(
                                book.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isOutOfStock
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'ISBN: ${book.isbn ?? "--"} • Auth: ${book.author ?? "Unknown"} • Pub: ${book.publisher ?? "--"}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Rs. ${price.toStringAsFixed(2)}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isOutOfStock
                                              ? AppColors.neutral500
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (isOutOfStock)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.errorLight,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColors.error
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Text(
                                            'OUT OF STOCK',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.errorText,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLow
                                                ? AppColors.warningLight
                                                : AppColors.neutral100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isLow
                                                ? 'Low: ${book.stockQuantity}'
                                                : 'Stock: ${book.stockQuantity}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isLow
                                                  ? AppColors.warningText
                                                  : AppColors.neutral700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      isOutOfStock
                                          ? Icons.block_rounded
                                          : Icons.add_circle_rounded,
                                      size: 20,
                                      color: isOutOfStock
                                          ? AppColors.neutral400
                                          : AppColors.primary,
                                    ),
                                    tooltip: isOutOfStock
                                        ? 'Out of Stock'
                                        : 'Add to Cart',
                                    splashRadius: 18,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (isOutOfStock) {
                                        _showSnackbar(
                                          'Cannot add "${book.name}": Book is currently OUT OF STOCK (0 available in warehouse).',
                                          isError: true,
                                        );
                                        return;
                                      }
                                      _addBookToCart(book);
                                      _searchController.clear();
                                      context
                                          .read<SalesBloc>()
                                          .add(const ClearPosBookSearch());
                                      _searchFocusNode.requestFocus();
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (isOutOfStock) {
                                  _showSnackbar(
                                    'Cannot add "${book.name}": Book is currently OUT OF STOCK (0 available in warehouse).',
                                    isError: true,
                                  );
                                  return;
                                }
                                _addBookToCart(book);
                                _searchController.clear();
                                context
                                    .read<SalesBloc>()
                                    .add(const ClearPosBookSearch());
                                _searchFocusNode.requestFocus();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Active Cart Table
        Expanded(
          child: AppCard(
            expand: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Checkout Cart Items (${_cartItems.length})',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_cartItems.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'Clear Cart',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _clearCart,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.neutral200),

                Expanded(
                  child: _cartItems.isEmpty
                      ? const Center(
                          child: SingleChildScrollView(
                            child: EmptyState(
                              icon: Icons.add_shopping_cart_rounded,
                              title: 'Cart is Empty',
                              message:
                                  'Scan a barcode or type title/ISBN above to begin billing.',
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _cartItems.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppColors.neutral100,
                          ),
                          itemBuilder: (context, index) {
                            return _buildCartRow(index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartRow(int index) {
    final item = _cartItems[index];
    final isExceeded = item.isStockExceeded;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isExceeded
            ? AppColors.errorLight.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Index Badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & ISBN & Stock
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.book.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        'ISBN: ${item.book.isbn ?? "--"}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isExceeded
                              ? AppColors.errorLight
                              : AppColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isExceeded
                              ? 'Stock: ${item.book.stockQuantity} (EXCEEDED)'
                              : 'Stock: ${item.book.stockQuantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isExceeded
                                ? AppColors.errorText
                                : AppColors.neutral700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selling Price (Editable)
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  initialValue: item.unitPrice.toStringAsFixed(2),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final price = double.tryParse(val) ?? 0.0;
                    setState(() {
                      item.unitPrice = price;
                      _syncPaidAmountIfFullPaid();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantity Increment/Decrement
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Qty',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                      onPressed: item.quantity > 1
                          ? () => _updateCartItemQuantity(
                              index,
                              item.quantity - 1,
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 40,
                      child: TextFormField(
                        key: ValueKey('qty_${item.book.id}_${item.quantity}'),
                        initialValue: item.quantity.toString(),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final q = int.tryParse(val);
                          if (q != null && q > 0) {
                            _updateCartItemQuantity(index, q);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                      onPressed: () =>
                          _updateCartItemQuantity(index, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Line Discount ($)
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disc.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  initialValue: item.discount.toStringAsFixed(2),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final disc = double.tryParse(val) ?? 0.0;
                    setState(() {
                      item.discount = disc;
                      _syncPaidAmountIfFullPaid();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Net Line Total
          SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${item.lineTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Remove Button
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.error,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            onPressed: () => _removeCartItem(index),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Right Settlement Section
  // ==========================================
  Widget _buildRightSettlementSection(
    List<Customer> customers,
    List<Sale> recentSales,
    bool isCreating,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer & Invoice Metadata Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Customer & Channel',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INV: #$_invoiceNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Walk-in vs Registered Switch
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        labelPadding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 15),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Walk-in Cash',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isWalkIn
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: _isWalkIn
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: _isWalkIn,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _isWalkIn
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: _isWalkIn
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _isWalkIn = true;
                            _selectedCustomer = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        labelPadding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_box_outlined, size: 15),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Registered Client',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: !_isWalkIn
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                  fontWeight: !_isWalkIn
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: !_isWalkIn,
                        selectedColor: AppColors.secondaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: !_isWalkIn
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontWeight: !_isWalkIn
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _isWalkIn = false;
                            if (customers.isNotEmpty &&
                                _selectedCustomer == null) {
                              _selectedCustomer = customers.first;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Customer Dropdown if Registered
                if (!_isWalkIn) ...[
                  const SizedBox(height: 12),
                  AppDropdown<Customer>(
                    label: 'Select Customer',
                    value: _selectedCustomer,
                    items: customers.map((c) {
                      return DropdownMenuItem<Customer>(
                        value: c,
                        child: Text('${c.name} (${c.phone ?? "No Phone"})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCustomer = val;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settlement Summary Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Financial Settlement',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),

                // Subtotal
                _buildSummaryLine(
                  'Subtotal',
                  'Rs. ${_itemsSubtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),

                // Overall Discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Discount', style: AppTextStyles.bodyMedium),
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _overallDiscountController,
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixText: 'Rs. ',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.neutral200),
                const SizedBox(height: 12),

                // Grand Total Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GRAND TOTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Rs. ${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8), // Electric Sky Blue
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                AppDropdown<String>(
                  label: 'Payment Method',
                  value: _paymentMethod,
                  items: const [
                    DropdownMenuItem(
                      value: 'Cash',
                      child: Text('Cash Payment'),
                    ),
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Text('Bank Transfer / Cheque'),
                    ),
                    DropdownMenuItem(
                      value: 'Card',
                      child: Text('Debit / Credit Card'),
                    ),
                    DropdownMenuItem(
                      value: 'Credit / Account',
                      child: Text('Credit (Customer Ledger)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMethod = val;
                        if (val == 'Credit / Account') {
                          _paidAmountController.text = '0.00';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Tendered Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tendered / Paid',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: _paidAmountController,
                        textAlign: TextAlign.end,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixText: 'Rs. ',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick Cash Buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Exact'),
                      onPressed: _setExactPaid,
                    ),
                    ActionChip(
                      label: const Text('+100'),
                      onPressed: () => _addCashTender(100),
                    ),
                    ActionChip(
                      label: const Text('+500'),
                      onPressed: () => _addCashTender(500),
                    ),
                    ActionChip(
                      label: const Text('+1000'),
                      onPressed: () => _addCashTender(1000),
                    ),
                    ActionChip(
                      label: const Text('+5000'),
                      onPressed: () => _addCashTender(5000),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic Status & Change Badge
                _buildSettlementFeedbackBadge(),
                const SizedBox(height: 16),

                // Checkout Button
                AppButton(
                  label: isCreating
                      ? 'Processing Transaction...'
                      : 'COMPLETE & SAVE SALE',
                  icon: Icons.check_circle_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: isCreating ? null : _executeCheckout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Sales List
          if (recentSales.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Counter Invoices',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.neutral200),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentSales.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.neutral100),
                    itemBuilder: (context, index) {
                      final sale = recentSales[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '#${sale.invoiceNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Rs. ${sale.total.toStringAsFixed(2)} • ${sale.paymentStatus}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            context.read<SalesBloc>().add(
                              LoadSaleDetails(sale.id!),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSettlementFeedbackBadge() {
    final status = _calculatedPaymentStatus;
    final change = _changeDue;
    final remaining = _remainingDue;

    if (status == 'PAID') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'PAYMENT STATUS: PAID',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.successText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              change > 0
                  ? 'Change: Rs. ${change.toStringAsFixed(2)}'
                  : 'Fully Settled',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.successText,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'PARTIAL') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'STATUS: PARTIAL PAYMENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warningText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Due: Rs. ${remaining.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.warningText,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'STATUS: UNPAID (CREDIT)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.errorText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Credit: Rs. ${remaining.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.errorText,
              ),
            ),
          ],
        ),
      );
    }
  }
}
