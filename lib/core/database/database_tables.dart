import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/db_constants.dart';

/// Defines production-ready SQLite DDL schemas and migration scripts for all 12 business modules
class DatabaseTables {
  DatabaseTables._();

  /// Create all tables and indexes in an atomic batch
  static Future<void> createAllTables(Database db) async {
    final batch = db.batch();

    // ==========================================
    // 1. Categories Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableCategories} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colCategoryName} TEXT NOT NULL UNIQUE,
        ${DbConstants.colCategoryDescription} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT
      );
    ''');

    // ==========================================
    // 2. Books Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableBooks} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colBookCategoryId} INTEGER,
        ${DbConstants.colBookName} TEXT NOT NULL,
        ${DbConstants.colBookIsbn} TEXT,
        ${DbConstants.colBookAuthor} TEXT,
        ${DbConstants.colBookPublisher} TEXT,
        ${DbConstants.colBookPurchasePrice} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colBookWholesalePrice} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colBookRetailPrice} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colBookStockQuantity} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colBookMinimumStock} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT,
        FOREIGN KEY (${DbConstants.colBookCategoryId}) 
          REFERENCES ${DbConstants.tableCategories}(${DbConstants.colId}) 
          ON DELETE SET NULL
      );
    ''');

    // ==========================================
    // 3. Customers Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableCustomers} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colCustomerName} TEXT NOT NULL,
        ${DbConstants.colCustomerPhone} TEXT,
        ${DbConstants.colCustomerAddress} TEXT,
        ${DbConstants.colCustomerEmail} TEXT,
        ${DbConstants.colCustomerOpeningBalance} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colCustomerNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT
      );
    ''');

    // ==========================================
    // 4. Suppliers Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSuppliers} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colSupplierName} TEXT NOT NULL,
        ${DbConstants.colSupplierPhone} TEXT,
        ${DbConstants.colSupplierAddress} TEXT,
        ${DbConstants.colSupplierEmail} TEXT,
        ${DbConstants.colSupplierOpeningBalance} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSupplierNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT
      );
    ''');

    // ==========================================
    // 5. Purchases Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tablePurchases} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colPurchaseSupplierId} INTEGER NOT NULL,
        ${DbConstants.colPurchaseInvoiceNumber} TEXT NOT NULL UNIQUE,
        ${DbConstants.colPurchaseDate} TEXT NOT NULL,
        ${DbConstants.colPurchaseSubtotal} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colPurchaseDiscount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colPurchaseTotal} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colPurchasePaidAmount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colPurchaseRemainingAmount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colPurchasePaymentStatus} TEXT NOT NULL,
        ${DbConstants.colPurchaseNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT,
        FOREIGN KEY (${DbConstants.colPurchaseSupplierId}) 
          REFERENCES ${DbConstants.tableSuppliers}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 6. Purchase Items Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tablePurchaseItems} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colPurchaseItemPurchaseId} INTEGER NOT NULL,
        ${DbConstants.colPurchaseItemBookId} INTEGER NOT NULL,
        ${DbConstants.colPurchaseItemQuantity} INTEGER NOT NULL,
        ${DbConstants.colPurchaseItemUnitPrice} REAL NOT NULL,
        ${DbConstants.colPurchaseItemDiscount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colPurchaseItemTotal} REAL NOT NULL,
        FOREIGN KEY (${DbConstants.colPurchaseItemPurchaseId}) 
          REFERENCES ${DbConstants.tablePurchases}(${DbConstants.colId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.colPurchaseItemBookId}) 
          REFERENCES ${DbConstants.tableBooks}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 7. Sales Table (Wholesale Sales)
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSales} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colSaleCustomerId} INTEGER,
        ${DbConstants.colSaleInvoiceNumber} TEXT NOT NULL UNIQUE,
        ${DbConstants.colSaleDate} TEXT NOT NULL,
        ${DbConstants.colSaleSubtotal} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSaleDiscount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSaleTotal} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSalePaidAmount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSaleRemainingAmount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSalePaymentStatus} TEXT NOT NULL,
        ${DbConstants.colSaleNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT,
        FOREIGN KEY (${DbConstants.colSaleCustomerId}) 
          REFERENCES ${DbConstants.tableCustomers}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 8. Sale Items Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSaleItems} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colSaleItemSaleId} INTEGER NOT NULL,
        ${DbConstants.colSaleItemBookId} INTEGER NOT NULL,
        ${DbConstants.colSaleItemQuantity} INTEGER NOT NULL,
        ${DbConstants.colSaleItemUnitPrice} REAL NOT NULL,
        ${DbConstants.colSaleItemDiscount} REAL NOT NULL DEFAULT 0,
        ${DbConstants.colSaleItemTotal} REAL NOT NULL,
        FOREIGN KEY (${DbConstants.colSaleItemSaleId}) 
          REFERENCES ${DbConstants.tableSales}(${DbConstants.colId}) 
          ON DELETE CASCADE,
        FOREIGN KEY (${DbConstants.colSaleItemBookId}) 
          REFERENCES ${DbConstants.tableBooks}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 9. Customer Payments Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableCustomerPayments} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colCustPaymentCustomerId} INTEGER NOT NULL,
        ${DbConstants.colCustPaymentAmount} REAL NOT NULL,
        ${DbConstants.colCustPaymentDate} TEXT NOT NULL,
        ${DbConstants.colCustPaymentMethod} TEXT NOT NULL,
        ${DbConstants.colCustPaymentReference} TEXT,
        ${DbConstants.colCustPaymentNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colCustPaymentCustomerId}) 
          REFERENCES ${DbConstants.tableCustomers}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 10. Supplier Payments Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSupplierPayments} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colSuppPaymentSupplierId} INTEGER NOT NULL,
        ${DbConstants.colSuppPaymentAmount} REAL NOT NULL,
        ${DbConstants.colSuppPaymentDate} TEXT NOT NULL,
        ${DbConstants.colSuppPaymentMethod} TEXT NOT NULL,
        ${DbConstants.colSuppPaymentReference} TEXT,
        ${DbConstants.colSuppPaymentNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colSuppPaymentSupplierId}) 
          REFERENCES ${DbConstants.tableSuppliers}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 11. Stock Movements Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableStockMovements} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colStockMovementBookId} INTEGER NOT NULL,
        ${DbConstants.colStockMovementType} TEXT NOT NULL,
        ${DbConstants.colStockMovementQuantity} INTEGER NOT NULL,
        ${DbConstants.colStockMovementReferenceType} TEXT,
        ${DbConstants.colStockMovementReferenceId} INTEGER,
        ${DbConstants.colStockMovementPreviousStock} INTEGER NOT NULL,
        ${DbConstants.colStockMovementNewStock} INTEGER NOT NULL,
        ${DbConstants.colStockMovementDate} TEXT NOT NULL,
        ${DbConstants.colStockMovementNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colStockMovementBookId}) 
          REFERENCES ${DbConstants.tableBooks}(${DbConstants.colId})
          ON DELETE RESTRICT
      );
    ''');

    // ==========================================
    // 12. Expenses Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableExpenses} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colExpenseTitle} TEXT NOT NULL,
        ${DbConstants.colExpenseCategory} TEXT,
        ${DbConstants.colExpenseAmount} REAL NOT NULL,
        ${DbConstants.colExpenseDate} TEXT NOT NULL,
        ${DbConstants.colExpensePaymentMethod} TEXT,
        ${DbConstants.colExpenseNotes} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT
      );
    ''');

    // ==========================================
    // 13. App Settings Table
    // ==========================================
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
        ${DbConstants.colSettingKey} TEXT PRIMARY KEY,
        ${DbConstants.colSettingValue} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT NOT NULL
      );
    ''');

    // ==========================================
    // Performance Indexes
    // ==========================================
    // Books indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_books_isbn ON ${DbConstants.tableBooks}(${DbConstants.colBookIsbn});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_books_category_id ON ${DbConstants.tableBooks}(${DbConstants.colBookCategoryId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_books_name ON ${DbConstants.tableBooks}(${DbConstants.colBookName});',
    );

    // Customers indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON ${DbConstants.tableCustomers}(${DbConstants.colCustomerName});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_phone ON ${DbConstants.tableCustomers}(${DbConstants.colCustomerPhone});',
    );

    // Suppliers indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_suppliers_name ON ${DbConstants.tableSuppliers}(${DbConstants.colSupplierName});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_suppliers_phone ON ${DbConstants.tableSuppliers}(${DbConstants.colSupplierPhone});',
    );

    // Purchases indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON ${DbConstants.tablePurchases}(${DbConstants.colPurchaseSupplierId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_invoice_number ON ${DbConstants.tablePurchases}(${DbConstants.colPurchaseInvoiceNumber});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_date ON ${DbConstants.tablePurchases}(${DbConstants.colPurchaseDate});',
    );

    // Purchase items indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON ${DbConstants.tablePurchaseItems}(${DbConstants.colPurchaseItemPurchaseId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchase_items_book ON ${DbConstants.tablePurchaseItems}(${DbConstants.colPurchaseItemBookId});',
    );

    // Sales indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON ${DbConstants.tableSales}(${DbConstants.colSaleCustomerId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_invoice_number ON ${DbConstants.tableSales}(${DbConstants.colSaleInvoiceNumber});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_date ON ${DbConstants.tableSales}(${DbConstants.colSaleDate});',
    );

    // Sale items indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON ${DbConstants.tableSaleItems}(${DbConstants.colSaleItemSaleId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_items_book ON ${DbConstants.tableSaleItems}(${DbConstants.colSaleItemBookId});',
    );

    // Customer payments indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cust_pay_customer ON ${DbConstants.tableCustomerPayments}(${DbConstants.colCustPaymentCustomerId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_cust_pay_date ON ${DbConstants.tableCustomerPayments}(${DbConstants.colCustPaymentDate});',
    );

    // Supplier payments indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_supp_pay_supplier ON ${DbConstants.tableSupplierPayments}(${DbConstants.colSuppPaymentSupplierId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_supp_pay_date ON ${DbConstants.tableSupplierPayments}(${DbConstants.colSuppPaymentDate});',
    );

    // Stock movements indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_movements_book ON ${DbConstants.tableStockMovements}(${DbConstants.colStockMovementBookId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON ${DbConstants.tableStockMovements}(${DbConstants.colStockMovementDate});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_movements_ref ON ${DbConstants.tableStockMovements}(${DbConstants.colStockMovementReferenceType}, ${DbConstants.colStockMovementReferenceId});',
    );

    // Expenses indexes
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON ${DbConstants.tableExpenses}(${DbConstants.colExpenseDate});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_category ON ${DbConstants.tableExpenses}(${DbConstants.colExpenseCategory});',
    );

    await batch.commit(noResult: true);
  }

  /// Migrates database from old version to new version
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Step 2 Migration: Rebuild tables to canonical Step 2 schema
      final batch = db.batch();

      // Drop obsolete/initial prototype tables cleanly
      final tablesToDrop = [
        'inventory_transactions',
        'sale_items',
        'sales',
        'purchase_items',
        'purchases',
        'customer_payments',
        'supplier_payments',
        'expenses',
        'books',
        'customers',
        'suppliers',
        'categories',
      ];

      for (final table in tablesToDrop) {
        batch.execute('DROP TABLE IF EXISTS $table;');
      }

      await batch.commit(noResult: true);

      // Recreate all tables with canonical schema
      await createAllTables(db);
    }
  }
}
