import 'package:isar/isar.dart';
import '../models/book_model.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/debt_ledger_model.dart';

class DbService {
  final Isar? isar;

  // In-memory fallbacks when running in web preview or environment without native C++ DLL
  final List<BookProduct> _inMemoryBooks = [];
  final List<CustomerModel> _inMemoryCustomers = [];
  final List<InvoiceModel> _inMemoryInvoices = [];
  final List<DebtLedgerEntry> _inMemoryLedgers = [];
  int _nextId = 100;

  DbService(this.isar);

  bool get isOfflineIsarActive => isar != null;

  // Fast search books by title substring or ISBN substring
  List<BookProduct> searchBooks(String query) {
    if (isar != null) {
      if (query.trim().isEmpty) {
        return isar!.bookProducts.where().limit(30).findAllSync();
      }
      final q = query.trim().toLowerCase();
      return isar!.bookProducts
          .filter()
          .isbnContains(q, caseSensitive: false)
          .or()
          .titleContains(q, caseSensitive: false)
          .or()
          .authorContains(q, caseSensitive: false)
          .findAllSync();
    }

    // In-memory fallback
    if (query.trim().isEmpty) {
      return List.unmodifiable(_inMemoryBooks);
    }
    final q = query.trim().toLowerCase();
    return _inMemoryBooks.where((book) {
      return book.isbn.toLowerCase().contains(q) ||
          book.title.toLowerCase().contains(q) ||
          book.author.toLowerCase().contains(q);
    }).toList();
  }

  // Add or update book
  Future<Id> saveBook(BookProduct book) async {
    if (isar != null) {
      return isar!.writeTxn(() async {
        return await isar!.bookProducts.put(book);
      });
    }

    if (book.id == Isar.autoIncrement || book.id == 0) {
      book.id = _nextId++;
    }
    final idx = _inMemoryBooks.indexWhere((b) => b.isbn == book.isbn || b.id == book.id);
    if (idx >= 0) {
      _inMemoryBooks[idx] = book;
    } else {
      _inMemoryBooks.add(book);
    }
    return book.id;
  }

  // Delete book
  Future<bool> deleteBook(Id id) async {
    if (isar != null) {
      return isar!.writeTxn(() async {
        return await isar!.bookProducts.delete(id);
      });
    }

    final initialLen = _inMemoryBooks.length;
    _inMemoryBooks.removeWhere((b) => b.id == id);
    return _inMemoryBooks.length < initialLen;
  }

  // Save or update customer
  Future<Id> saveCustomer(CustomerModel customer) async {
    if (isar != null) {
      return isar!.writeTxn(() async {
        return await isar!.customerModels.put(customer);
      });
    }

    if (customer.id == Isar.autoIncrement || customer.id == 0) {
      customer.id = _nextId++;
    }
    final idx = _inMemoryCustomers.indexWhere((c) => c.name == customer.name || c.id == customer.id);
    if (idx >= 0) {
      _inMemoryCustomers[idx] = customer;
    } else {
      _inMemoryCustomers.add(customer);
    }
    return customer.id;
  }

  // Get all customers
  List<CustomerModel> getAllCustomers() {
    if (isar != null) {
      return isar!.customerModels.where().findAllSync();
    }
    return List.unmodifiable(_inMemoryCustomers);
  }

  // Save invoice and perform atomic inventory decrement & customer debt adjustments
  Future<InvoiceModel> processSaleInvoice({
    required String invoiceNumber,
    required List<InvoiceItemEmbedded> items,
    required double subtotal,
    required double discountAmount,
    required double grandTotal,
    required double amountPaid,
    required String paymentType,
    int? customerId,
    String? customerName,
  }) async {
    final balanceDue = (grandTotal - amountPaid) > 0 ? (grandTotal - amountPaid) : 0.0;

    final invoice = InvoiceModel()
      ..invoiceNumber = invoiceNumber
      ..date = DateTime.now()
      ..customerId = customerId
      ..customerName = customerName ?? 'Walk-in Bulk Customer'
      ..items = items
      ..subtotal = subtotal
      ..discountAmount = discountAmount
      ..grandTotal = grandTotal
      ..amountPaid = amountPaid
      ..balanceDue = balanceDue
      ..paymentType = paymentType;

    if (isar != null) {
      await isar!.writeTxn(() async {
        // 1. Save invoice
        await isar!.invoiceModels.put(invoice);

        // 2. Decrement inventory quantities for each book
        for (final item in items) {
          if (item.bookIsbn != null && item.bookIsbn!.isNotEmpty) {
            final book = await isar!.bookProducts.filter().isbnEqualTo(item.bookIsbn!).findFirst();
            if (book != null) {
              final newQty = book.totalStockQuantity - item.quantity;
              book.totalStockQuantity = newQty >= 0 ? newQty : 0;
              await isar!.bookProducts.put(book);
            }
          }
        }

        // 3. If customer is identified and there is balance due (credit purchase)
        if (customerId != null) {
          final customer = await isar!.customerModels.get(customerId);
          if (customer != null) {
            final previousDebt = customer.currentDebtBalance;
            final newDebt = previousDebt + balanceDue;
            customer.currentDebtBalance = newDebt;
            await isar!.customerModels.put(customer);

            // Add debt ledger entry
            if (balanceDue > 0) {
              final ledger = DebtLedgerEntry()
                ..customerId = customerId
                ..timestamp = DateTime.now()
                ..invoiceNumber = invoiceNumber
                ..description = 'Invoice #$invoiceNumber (Purchase on credit)'
                ..debitAmount = balanceDue
                ..creditAmount = 0.0
                ..runningBalance = newDebt;
              await isar!.debtLedgerEntrys.put(ledger);
            }
          }
        }
      });
      return invoice;
    }

    // In-memory handling
    invoice.id = _nextId++;
    _inMemoryInvoices.add(invoice);

    for (final item in items) {
      if (item.bookIsbn != null) {
        final bookIdx = _inMemoryBooks.indexWhere((b) => b.isbn == item.bookIsbn);
        if (bookIdx >= 0) {
          final book = _inMemoryBooks[bookIdx];
          final newQty = book.totalStockQuantity - item.quantity;
          book.totalStockQuantity = newQty >= 0 ? newQty : 0;
        }
      }
    }

    if (customerId != null) {
      final custIdx = _inMemoryCustomers.indexWhere((c) => c.id == customerId);
      if (custIdx >= 0) {
        final customer = _inMemoryCustomers[custIdx];
        final previousDebt = customer.currentDebtBalance;
        final newDebt = previousDebt + balanceDue;
        customer.currentDebtBalance = newDebt;

        if (balanceDue > 0) {
          final ledger = DebtLedgerEntry()
            ..id = _nextId++
            ..customerId = customerId
            ..timestamp = DateTime.now()
            ..invoiceNumber = invoiceNumber
            ..description = 'Invoice #$invoiceNumber (Purchase on credit)'
            ..debitAmount = balanceDue
            ..creditAmount = 0.0
            ..runningBalance = newDebt;
          _inMemoryLedgers.add(ledger);
        }
      }
    }

    return invoice;
  }

  // Record a payment received from a customer towards their debt ledger
  Future<void> recordCustomerPayment({
    required int customerId,
    required double amount,
    required String paymentMethod,
    String? referenceNote,
  }) async {
    if (isar != null) {
      await isar!.writeTxn(() async {
        final customer = await isar!.customerModels.get(customerId);
        if (customer == null) return;

        final previousDebt = customer.currentDebtBalance;
        final newDebt = (previousDebt - amount) >= 0 ? (previousDebt - amount) : 0.0;
        customer.currentDebtBalance = newDebt;
        await isar!.customerModels.put(customer);

        final ledger = DebtLedgerEntry()
          ..customerId = customerId
          ..timestamp = DateTime.now()
          ..description = 'Payment Received ($paymentMethod)${referenceNote != null && referenceNote.isNotEmpty ? ' - $referenceNote' : ''}'
          ..debitAmount = 0.0
          ..creditAmount = amount
          ..runningBalance = newDebt;

        await isar!.debtLedgerEntrys.put(ledger);
      });
      return;
    }

    final custIdx = _inMemoryCustomers.indexWhere((c) => c.id == customerId);
    if (custIdx >= 0) {
      final customer = _inMemoryCustomers[custIdx];
      final previousDebt = customer.currentDebtBalance;
      final newDebt = (previousDebt - amount) >= 0 ? (previousDebt - amount) : 0.0;
      customer.currentDebtBalance = newDebt;

      final ledger = DebtLedgerEntry()
        ..id = _nextId++
        ..customerId = customerId
        ..timestamp = DateTime.now()
        ..description = 'Payment Received ($paymentMethod)${referenceNote != null && referenceNote.isNotEmpty ? ' - $referenceNote' : ''}'
        ..debitAmount = 0.0
        ..creditAmount = amount
        ..runningBalance = newDebt;

      _inMemoryLedgers.add(ledger);
    }
  }

  // Get customer ledger history
  List<DebtLedgerEntry> getCustomerLedger(int customerId) {
    if (isar != null) {
      return isar!.debtLedgerEntrys
          .filter()
          .customerIdEqualTo(customerId)
          .sortByTimestampDesc()
          .findAllSync();
    }

    return _inMemoryLedgers
        .where((l) => l.customerId == customerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Seed sample data for immediate wholesale demonstration
  Future<void> seedInitialDataIfEmpty() async {
    if (isar != null) {
      final count = await isar!.bookProducts.count();
      if (count > 0) return;
    } else {
      if (_inMemoryBooks.isNotEmpty) return;
    }

    final sampleBooks = [
      BookProduct()
        ..isbn = '978-0140449136'
        ..title = 'The Holy Quran - Tajweed 16-Line Standard'
        ..author = 'Deen Publications'
        ..wholesalePrice = 450.0
        ..retailPrice = 750.0
        ..unitsPerCarton = 20
        ..totalStockQuantity = 400,
      BookProduct()
        ..isbn = '978-9960717142'
        ..title = 'Sahih Al-Bukhari (Complete 9 Vol Edition)'
        ..author = 'Imam Bukhari / Darussalam'
        ..wholesalePrice = 3200.0
        ..retailPrice = 5000.0
        ..unitsPerCarton = 4
        ..totalStockQuantity = 80,
      BookProduct()
        ..isbn = '978-9960717319'
        ..title = 'Riyad-us-Saliheen (Gardens of the Righteous)'
        ..author = 'Imam An-Nawawi'
        ..wholesalePrice = 650.0
        ..retailPrice = 1100.0
        ..unitsPerCarton = 15
        ..totalStockQuantity = 225,
      BookProduct()
        ..isbn = '978-9960892016'
        ..title = 'Tafseer Ibn Kathir (English Abridged 10 Vols)'
        ..author = 'Hafiz Ibn Kathir'
        ..wholesalePrice = 3800.0
        ..retailPrice = 6200.0
        ..unitsPerCarton = 3
        ..totalStockQuantity = 45,
      BookProduct()
        ..isbn = '978-9960892221'
        ..title = 'Ar-Raheeq Al-Makhtum (The Sealed Nectar)'
        ..author = 'Safiur Rahman Mubarakpuri'
        ..wholesalePrice = 380.0
        ..retailPrice = 650.0
        ..unitsPerCarton = 25
        ..totalStockQuantity = 350,
      BookProduct()
        ..isbn = '978-0199120932'
        ..title = 'Advanced Pure Mathematics (A-Level Wholesale Edition)'
        ..author = 'Oxford University Press'
        ..wholesalePrice = 850.0
        ..retailPrice = 1400.0
        ..unitsPerCarton = 30
        ..totalStockQuantity = 600,
      BookProduct()
        ..isbn = '978-0199146338'
        ..title = 'Fundamentals of Physics (Comprehensive Volume)'
        ..author = 'Halliday & Resnick'
        ..wholesalePrice = 1100.0
        ..retailPrice = 1850.0
        ..unitsPerCarton = 20
        ..totalStockQuantity = 300,
      BookProduct()
        ..isbn = '978-0194323450'
        ..title = 'Oxford Advanced Learner\'s Dictionary (10th Ed)'
        ..author = 'A. S. Hornby'
        ..wholesalePrice = 950.0
        ..retailPrice = 1600.0
        ..unitsPerCarton = 16
        ..totalStockQuantity = 240,
      BookProduct()
        ..isbn = '978-9694943210'
        ..title = 'Urdu Lughat Feroz-ul-Lughat (Jame Jadeed)'
        ..author = 'Al-Hajj Maulvi Ferozuddin'
        ..wholesalePrice = 600.0
        ..retailPrice = 1000.0
        ..unitsPerCarton = 10
        ..totalStockQuantity = 150,
      BookProduct()
        ..isbn = '978-9694949984'
        ..title = 'Islamic Studies Curriculum Series - Grade 9 & 10'
        ..author = 'Federal Board Curriculum'
        ..wholesalePrice = 180.0
        ..retailPrice = 300.0
        ..unitsPerCarton = 50
        ..totalStockQuantity = 1500,
    ];

    final customer1 = CustomerModel()
      ..name = 'Al-Madinah Islamic Academy'
      ..shopOrInstitutionName = 'Madinah Academy Book Depot'
      ..phone = '+92 300 1234567'
      ..address = 'Commercial Area, Block 4, Clifton'
      ..creditLimit = 150000.0
      ..currentDebtBalance = 24500.0;

    final customer2 = CustomerModel()
      ..name = 'Darul Ilm School Network'
      ..shopOrInstitutionName = 'Darul Ilm Library Supplies'
      ..phone = '+92 321 9876543'
      ..address = 'Main Boulevard, Gulberg III'
      ..creditLimit = 250000.0
      ..currentDebtBalance = 58200.0;

    final customer3 = CustomerModel()
      ..name = 'Al-Huda Educational Bookshop'
      ..shopOrInstitutionName = 'Al-Huda Retail Book Depot'
      ..phone = '+92 333 5551212'
      ..address = 'Urdu Bazaar, Shop #42'
      ..creditLimit = 100000.0
      ..currentDebtBalance = 0.0;

    if (isar != null) {
      await isar!.writeTxn(() async {
        for (final book in sampleBooks) {
          await isar!.bookProducts.put(book);
        }
        final id1 = await isar!.customerModels.put(customer1);
        final id2 = await isar!.customerModels.put(customer2);
        await isar!.customerModels.put(customer3);

        await isar!.debtLedgerEntrys.put(DebtLedgerEntry()
          ..customerId = id1
          ..timestamp = DateTime.now().subtract(const Duration(days: 14))
          ..invoiceNumber = 'INV-2026-0001'
          ..description = 'Invoice #INV-2026-0001 (Wholesale Books Purchase)'
          ..debitAmount = 44500.0
          ..creditAmount = 0.0
          ..runningBalance = 44500.0);

        await isar!.debtLedgerEntrys.put(DebtLedgerEntry()
          ..customerId = id1
          ..timestamp = DateTime.now().subtract(const Duration(days: 7))
          ..description = 'Bank Transfer Payment Received'
          ..debitAmount = 0.0
          ..creditAmount = 20000.0
          ..runningBalance = 24500.0);

        await isar!.debtLedgerEntrys.put(DebtLedgerEntry()
          ..customerId = id2
          ..timestamp = DateTime.now().subtract(const Duration(days: 5))
          ..invoiceNumber = 'INV-2026-0002'
          ..description = 'Invoice #INV-2026-0002 (Bulk Quran & Textbooks)'
          ..debitAmount = 58200.0
          ..creditAmount = 0.0
          ..runningBalance = 58200.0);
      });
    } else {
      for (final book in sampleBooks) {
        book.id = _nextId++;
        _inMemoryBooks.add(book);
      }
      customer1.id = _nextId++;
      customer2.id = _nextId++;
      customer3.id = _nextId++;
      _inMemoryCustomers.addAll([customer1, customer2, customer3]);

      _inMemoryLedgers.add(DebtLedgerEntry()
        ..id = _nextId++
        ..customerId = customer1.id
        ..timestamp = DateTime.now().subtract(const Duration(days: 14))
        ..invoiceNumber = 'INV-2026-0001'
        ..description = 'Invoice #INV-2026-0001 (Wholesale Books Purchase)'
        ..debitAmount = 44500.0
        ..creditAmount = 0.0
        ..runningBalance = 44500.0);

      _inMemoryLedgers.add(DebtLedgerEntry()
        ..id = _nextId++
        ..customerId = customer1.id
        ..timestamp = DateTime.now().subtract(const Duration(days: 7))
        ..description = 'Bank Transfer Payment Received'
        ..debitAmount = 0.0
        ..creditAmount = 20000.0
        ..runningBalance = 24500.0);

      _inMemoryLedgers.add(DebtLedgerEntry()
        ..id = _nextId++
        ..customerId = customer2.id
        ..timestamp = DateTime.now().subtract(const Duration(days: 5))
        ..invoiceNumber = 'INV-2026-0002'
        ..description = 'Invoice #INV-2026-0002 (Bulk Quran & Textbooks)'
        ..debitAmount = 58200.0
        ..creditAmount = 0.0
        ..runningBalance = 58200.0);
    }
  }
}
