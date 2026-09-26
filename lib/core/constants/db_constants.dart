/// Canonical SQLite table and column constants for the Offline Wholesale Book Management System
class DbConstants {
  DbConstants._();

  // ==========================================
  // Table Names (12 Business Modules + 1 Settings)
  // ==========================================
  static const String tableCategories = 'categories';
  static const String tableBooks = 'books';
  static const String tableCustomers = 'customers';
  static const String tableSuppliers = 'suppliers';
  static const String tablePurchases = 'purchases';
  static const String tablePurchaseItems = 'purchase_items';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tableCustomerPayments = 'customer_payments';
  static const String tableSupplierPayments = 'supplier_payments';
  static const String tableStockMovements = 'stock_movements';
  static const String tableExpenses = 'expenses';
  static const String tableAppSettings = 'app_settings';

  // ==========================================
  // Common Column Names
  // ==========================================
  static const String colId = 'id';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // ==========================================
  // 1. Categories Table Columns
  // ==========================================
  static const String colCategoryName = 'name';
  static const String colCategoryDescription = 'description';

  // ==========================================
  // 2. Books Table Columns
  // ==========================================
  static const String colBookCategoryId = 'category_id';
  static const String colBookName = 'name';
  static const String colBookIsbn = 'isbn';
  static const String colBookAuthor = 'author';
  static const String colBookPublisher = 'publisher';
  static const String colBookPurchasePrice = 'purchase_price';
  static const String colBookWholesalePrice = 'wholesale_price';
  static const String colBookRetailPrice = 'retail_price';
  static const String colBookStockQuantity = 'stock_quantity';
  static const String colBookMinimumStock = 'minimum_stock';

  // ==========================================
  // 3. Customers Table Columns
  // ==========================================
  static const String colCustomerName = 'name';
  static const String colCustomerPhone = 'phone';
  static const String colCustomerAddress = 'address';
  static const String colCustomerEmail = 'email';
  static const String colCustomerOpeningBalance = 'opening_balance';
  static const String colCustomerNotes = 'notes';

  // ==========================================
  // 4. Suppliers Table Columns
  // ==========================================
  static const String colSupplierName = 'name';
  static const String colSupplierPhone = 'phone';
  static const String colSupplierAddress = 'address';
  static const String colSupplierEmail = 'email';
  static const String colSupplierOpeningBalance = 'opening_balance';
  static const String colSupplierNotes = 'notes';

  // ==========================================
  // 5. Purchases Table Columns
  // ==========================================
  static const String colPurchaseSupplierId = 'supplier_id';
  static const String colPurchaseInvoiceNumber = 'invoice_number';
  static const String colPurchaseDate = 'purchase_date';
  static const String colPurchaseSubtotal = 'subtotal';
  static const String colPurchaseDiscount = 'discount';
  static const String colPurchaseTotal = 'total';
  static const String colPurchasePaidAmount = 'paid_amount';
  static const String colPurchaseRemainingAmount = 'remaining_amount';
  static const String colPurchasePaymentStatus = 'payment_status';
  static const String colPurchaseNotes = 'notes';

  // ==========================================
  // 6. Purchase Items Table Columns
  // ==========================================
  static const String colPurchaseItemPurchaseId = 'purchase_id';
  static const String colPurchaseItemBookId = 'book_id';
  static const String colPurchaseItemQuantity = 'quantity';
  static const String colPurchaseItemUnitPrice = 'unit_price';
  static const String colPurchaseItemDiscount = 'discount';
  static const String colPurchaseItemTotal = 'total';

  // ==========================================
  // 7. Sales Table Columns
  // ==========================================
  static const String colSaleCustomerId = 'customer_id';
  static const String colSaleInvoiceNumber = 'invoice_number';
  static const String colSaleDate = 'sale_date';
  static const String colSaleSubtotal = 'subtotal';
  static const String colSaleDiscount = 'discount';
  static const String colSaleTotal = 'total';
  static const String colSalePaidAmount = 'paid_amount';
  static const String colSaleRemainingAmount = 'remaining_amount';
  static const String colSalePaymentStatus = 'payment_status';
  static const String colSaleNotes = 'notes';

  // ==========================================
  // 8. Sale Items Table Columns
  // ==========================================
  static const String colSaleItemSaleId = 'sale_id';
  static const String colSaleItemBookId = 'book_id';
  static const String colSaleItemQuantity = 'quantity';
  static const String colSaleItemUnitPrice = 'unit_price';
  static const String colSaleItemDiscount = 'discount';
  static const String colSaleItemTotal = 'total';

  // ==========================================
  // 9. Customer Payments Table Columns
  // ==========================================
  static const String colCustPaymentCustomerId = 'customer_id';
  static const String colCustPaymentAmount = 'amount';
  static const String colCustPaymentDate = 'payment_date';
  static const String colCustPaymentMethod = 'payment_method';
  static const String colCustPaymentReference = 'reference';
  static const String colCustPaymentNotes = 'notes';

  // ==========================================
  // 10. Supplier Payments Table Columns
  // ==========================================
  static const String colSuppPaymentSupplierId = 'supplier_id';
  static const String colSuppPaymentAmount = 'amount';
  static const String colSuppPaymentDate = 'payment_date';
  static const String colSuppPaymentMethod = 'payment_method';
  static const String colSuppPaymentReference = 'reference';
  static const String colSuppPaymentNotes = 'notes';

  // ==========================================
  // 11. Stock Movements Table Columns
  // ==========================================
  static const String colStockMovementBookId = 'book_id';
  static const String colStockMovementType = 'movement_type';
  static const String colStockMovementQuantity = 'quantity';
  static const String colStockMovementReferenceType = 'reference_type';
  static const String colStockMovementReferenceId = 'reference_id';
  static const String colStockMovementPreviousStock = 'previous_stock';
  static const String colStockMovementNewStock = 'new_stock';
  static const String colStockMovementDate = 'movement_date';
  static const String colStockMovementNotes = 'notes';

  // ==========================================
  // 12. Expenses Table Columns
  // ==========================================
  static const String colExpenseTitle = 'title';
  static const String colExpenseCategory = 'category';
  static const String colExpenseAmount = 'amount';
  static const String colExpenseDate = 'expense_date';
  static const String colExpensePaymentMethod = 'payment_method';
  static const String colExpenseNotes = 'notes';

  // ==========================================
  // 13. App Settings Table Columns
  // ==========================================
  static const String colSettingKey = 'key';
  static const String colSettingValue = 'value';
}
