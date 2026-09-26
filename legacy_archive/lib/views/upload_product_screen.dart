import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/book_model.dart';
import '../services/db_service.dart';

class UploadProductScreen extends StatefulWidget {
  final DbService dbService;

  const UploadProductScreen({super.key, required this.dbService});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _isbnFocusNode = FocusNode();
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _unitsPerCartonController = TextEditingController();
  final _initialStockController = TextEditingController();

  final _searchCatalogController = TextEditingController();
  List<BookProduct> _catalog = [];
  bool _isSaving = false;
  final NumberFormat _currency = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isbnFocusNode.requestFocus();
    });
  }

  void _loadCatalog() {
    setState(() {
      _catalog = widget.dbService.searchBooks(_searchCatalogController.text);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final book = BookProduct()
        ..isbn = _isbnController.text.trim()
        ..title = _titleController.text.trim()
        ..author = _authorController.text.trim()
        ..wholesalePrice = double.parse(_wholesalePriceController.text.trim())
        ..retailPrice = double.parse(_retailPriceController.text.trim())
        ..unitsPerCarton = int.parse(_unitsPerCartonController.text.trim())
        ..totalStockQuantity = int.parse(_initialStockController.text.trim());

      await widget.dbService.saveBook(book);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('"${book.title}" saved successfully to wholesale catalog!'),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Flush out values for the next book sequence
      _formKey.currentState!.reset();
      _isbnController.clear();
      _titleController.clear();
      _authorController.clear();
      _wholesalePriceController.clear();
      _retailPriceController.clear();
      _unitsPerCartonController.clear();
      _initialStockController.clear();

      _loadCatalog();
      _isbnFocusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save book product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _quickAdjustStock(BookProduct book, int delta) async {
    final newStock = book.totalStockQuantity + delta;
    book.totalStockQuantity = newStock >= 0 ? newStock : 0;
    await widget.dbService.saveBook(book);
    _loadCatalog();
  }

  @override
  void dispose() {
    _isbnFocusNode.dispose();
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _unitsPerCartonController.dispose();
    _initialStockController.dispose();
    _searchCatalogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6FA),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Centralized Product Entry Form Card (45% width)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EAF6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.library_add, color: Color(0xFF1A237E), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wholesale Catalog Entry',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                                ),
                                Text(
                                  'Register new book title or update existing stock',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // ISBN / Barcode
                        _buildTextField(
                          controller: _isbnController,
                          focusNode: _isbnFocusNode,
                          label: 'ISBN / Barcode identifier',
                          hint: 'e.g. 978-0140449136 or scan barcode',
                          icon: Icons.qr_code,
                          validator: (val) => val == null || val.trim().isEmpty ? 'ISBN cannot be blank' : null,
                        ),
                        const SizedBox(height: 14),

                        // Title
                        _buildTextField(
                          controller: _titleController,
                          label: 'Book Title & Edition',
                          hint: 'e.g. Tajweed Quran Majeed (16-Line Standard)',
                          icon: Icons.book,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Title cannot be blank' : null,
                        ),
                        const SizedBox(height: 14),

                        // Author / Publisher
                        _buildTextField(
                          controller: _authorController,
                          label: 'Author / Publishing House',
                          hint: 'e.g. Darussalam / Deen Publications',
                          icon: Icons.person_outline,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Author/Publisher cannot be blank' : null,
                        ),
                        const SizedBox(height: 14),

                        // Prices Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _wholesalePriceController,
                                label: 'Wholesale Price (Rs.)',
                                hint: 'e.g. 450.00',
                                icon: Icons.sell,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (double.tryParse(val.trim()) == null) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildTextField(
                                controller: _retailPriceController,
                                label: 'Retail MRP (Rs.)',
                                hint: 'e.g. 750.00',
                                icon: Icons.storefront,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (double.tryParse(val.trim()) == null) return 'Invalid price';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Packaging & Initial Stock Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _unitsPerCartonController,
                                label: 'Units Per Carton (Pcs)',
                                hint: 'e.g. 20',
                                icon: Icons.inventory_2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  final num = int.tryParse(val.trim());
                                  if (num == null || num <= 0) return 'Must be >= 1';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildTextField(
                                controller: _initialStockController,
                                label: 'Initial Stock Quantity (Units)',
                                hint: 'e.g. 400',
                                icon: Icons.all_inbox,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (int.tryParse(val.trim()) == null) return 'Invalid qty';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save, size: 20),
                            label: Text(
                              _isSaving ? 'Saving to Database...' : 'Save Product & Ready Next (Enter)',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isSaving ? null : _saveProduct,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Right: Active Catalog & Inventory Stock Grid (55% width)
          Expanded(
            flex: 6,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search & Stats Row
                    Row(
                      children: [
                        const Icon(Icons.inventory, color: Color(0xFF1A237E)),
                        const SizedBox(width: 8),
                        Text(
                          'Current Inventory (${_catalog.length} Titles)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E)),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 240,
                          height: 38,
                          child: TextField(
                            controller: _searchCatalogController,
                            onChanged: (val) => _loadCatalog(),
                            decoration: InputDecoration(
                              hintText: 'Filter catalog...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Inventory Table
                    Expanded(
                      child: _catalog.isEmpty
                          ? Center(
                              child: Text('No books registered yet.', style: TextStyle(color: Colors.grey.shade600)),
                            )
                          : ListView.separated(
                              itemCount: _catalog.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final book = _catalog[index];
                                final isLowStock = book.totalStockQuantity < 25;
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: isLowStock ? Colors.amber.shade100 : const Color(0xFFE8EAF6),
                                    child: Icon(
                                      Icons.menu_book,
                                      size: 18,
                                      color: isLowStock ? Colors.orange.shade800 : const Color(0xFF1A237E),
                                    ),
                                  ),
                                  title: Text(
                                    book.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'ISBN: ${book.isbn} • Wholesale: Rs. ${_currency.format(book.wholesalePrice)} • Retail: Rs. ${_currency.format(book.retailPrice)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Stock badges
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${book.totalStockQuantity} units',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isLowStock ? Colors.red.shade900 : Colors.green.shade900,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${book.cartons} ctn (${book.looseUnits} loose)',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Quick stock adjusters
                                      IconButton(
                                        icon: const Icon(Icons.add_box, size: 22, color: Color(0xFF1A237E)),
                                        tooltip: 'Restock +1 carton (${book.unitsPerCarton} units)',
                                        onPressed: () => _quickAdjustStock(book, book.unitsPerCarton),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1A237E)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
