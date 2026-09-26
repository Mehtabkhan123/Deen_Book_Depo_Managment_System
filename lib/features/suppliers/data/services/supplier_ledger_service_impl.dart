import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/purchase.dart';
import '../../../../shared/models/supplier_payment.dart';
import '../../domain/models/supplier_ledger_entry.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/services/supplier_ledger_service.dart';

/// Concrete implementation of [SupplierLedgerService]
class SupplierLedgerServiceImpl implements SupplierLedgerService {
  final SupplierRepository supplierRepository;
  final DatabaseHelper _dbHelper;

  SupplierLedgerServiceImpl({
    required this.supplierRepository,
    DatabaseHelper? dbHelper,
  })  : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<double> getSupplierBalance(int supplierId) async {
    final supplier = await supplierRepository.getById(supplierId);
    if (supplier == null) {
      throw NotFoundException('Supplier with ID $supplierId not found.');
    }

    // 1. Opening Balance
    final double openingBalance = supplier.openingBalance;

    // 2. Sum of credit purchases (unpaid invoice portions)
    final purchasesResult = await _dbHelper.rawQuery(
      'SELECT SUM(${DbConstants.colPurchaseRemainingAmount}) as total_credit '
      'FROM ${DbConstants.tablePurchases} '
      'WHERE ${DbConstants.colPurchaseSupplierId} = ?',
      [supplierId],
    );
    final double creditPurchases = (purchasesResult.first['total_credit'] as num?)?.toDouble() ?? 0.0;

    // 3. Sum of supplier payments
    final paymentsResult = await _dbHelper.rawQuery(
      'SELECT SUM(${DbConstants.colSuppPaymentAmount}) as total_paid '
      'FROM ${DbConstants.tableSupplierPayments} '
      'WHERE ${DbConstants.colSuppPaymentSupplierId} = ?',
      [supplierId],
    );
    final double supplierPayments = (paymentsResult.first['total_paid'] as num?)?.toDouble() ?? 0.0;

    // Balance = Opening Balance + Credit Purchases - Supplier Payments
    return openingBalance + creditPurchases - supplierPayments;
  }

  @override
  Future<List<Purchase>> getSupplierPurchases(int supplierId) async {
    final results = await _dbHelper.query(
      DbConstants.tablePurchases,
      where: '${DbConstants.colPurchaseSupplierId} = ?',
      whereArgs: [supplierId],
      orderBy: '${DbConstants.colPurchaseDate} DESC, ${DbConstants.colId} DESC',
    );
    return results.map((row) => Purchase.fromMap(row)).toList();
  }

  @override
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async {
    final results = await _dbHelper.query(
      DbConstants.tableSupplierPayments,
      where: '${DbConstants.colSuppPaymentSupplierId} = ?',
      whereArgs: [supplierId],
      orderBy: '${DbConstants.colSuppPaymentDate} DESC, ${DbConstants.colId} DESC',
    );
    return results.map((row) => SupplierPayment.fromMap(row)).toList();
  }

  @override
  Future<List<SupplierLedgerEntry>> getSupplierTransactions(int supplierId) async {
    final supplier = await supplierRepository.getById(supplierId);
    if (supplier == null) {
      throw NotFoundException('Supplier with ID $supplierId not found.');
    }

    final List<SupplierLedgerEntry> entries = [];
    double runningBalance = 0.0;

    // 1. Initial Opening Balance entry
    if (supplier.openingBalance != 0.0) {
      runningBalance += supplier.openingBalance;
      entries.add(
        SupplierLedgerEntry(
          date: supplier.createdAt,
          type: 'OPENING_BALANCE',
          reference: 'OB-${supplier.id}',
          credit: supplier.openingBalance > 0 ? supplier.openingBalance : 0.0,
          debit: supplier.openingBalance < 0 ? supplier.openingBalance.abs() : 0.0,
          runningBalance: runningBalance,
          notes: 'Account opening balance',
        ),
      );
    }

    // 2. Fetch purchases and payments sorted chronologically
    final purchases = await getSupplierPurchases(supplierId);
    final payments = await getSupplierPayments(supplierId);

    final List<Map<String, dynamic>> combined = [];
    for (final p in purchases) {
      combined.add({'type': 'PURCHASE', 'date': p.purchaseDate, 'data': p});
    }
    for (final pay in payments) {
      combined.add({'type': 'PAYMENT', 'date': pay.paymentDate, 'data': pay});
    }
    combined.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    for (final item in combined) {
      if (item['type'] == 'PURCHASE') {
        final Purchase p = item['data'] as Purchase;
        final double creditAmount = p.remainingAmount;
        runningBalance += creditAmount;
        entries.add(
          SupplierLedgerEntry(
            date: p.purchaseDate,
            type: 'PURCHASE',
            reference: p.invoiceNumber,
            credit: creditAmount,
            debit: 0.0,
            runningBalance: runningBalance,
            notes: 'Wholesale Purchase Invoice #${p.invoiceNumber} (${p.paymentStatus})',
          ),
        );
      } else {
        final SupplierPayment pay = item['data'] as SupplierPayment;
        final double debitAmount = pay.amount;
        runningBalance -= debitAmount;
        entries.add(
          SupplierLedgerEntry(
            date: pay.paymentDate,
            type: 'PAYMENT',
            reference: pay.reference ?? 'PAY-${pay.id}',
            credit: 0.0,
            debit: debitAmount,
            runningBalance: runningBalance,
            notes: 'Payment disbursed via ${pay.paymentMethod} - ${pay.notes ?? ''}',
          ),
        );
      }
    }

    return entries;
  }
}
