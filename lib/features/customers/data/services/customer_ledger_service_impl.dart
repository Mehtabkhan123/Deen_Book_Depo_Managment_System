import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/customer_payment.dart';
import '../../../../shared/models/sale.dart';
import '../../domain/models/customer_ledger_entry.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/customer_ledger_service.dart';

/// Concrete implementation of [CustomerLedgerService]
class CustomerLedgerServiceImpl implements CustomerLedgerService {
  final CustomerRepository customerRepository;
  final DatabaseHelper _dbHelper;

  CustomerLedgerServiceImpl({
    required this.customerRepository,
    DatabaseHelper? dbHelper,
  })  : _dbHelper = dbHelper ?? DatabaseHelper();

  @override
  Future<double> getCustomerBalance(int customerId) async {
    final customer = await customerRepository.getById(customerId);
    if (customer == null) {
      throw NotFoundException('Customer with ID $customerId not found.');
    }

    // 1. Opening Balance
    final double openingBalance = customer.openingBalance;

    // 2. Sum of credit sales (unpaid invoice portions)
    final salesResult = await _dbHelper.rawQuery(
      'SELECT SUM(${DbConstants.colSaleRemainingAmount}) as total_credit '
      'FROM ${DbConstants.tableSales} '
      'WHERE ${DbConstants.colSaleCustomerId} = ?',
      [customerId],
    );
    final double creditSales = (salesResult.first['total_credit'] as num?)?.toDouble() ?? 0.0;

    // 3. Sum of customer payments (recovery payments)
    final paymentsResult = await _dbHelper.rawQuery(
      'SELECT SUM(${DbConstants.colCustPaymentAmount}) as total_paid '
      'FROM ${DbConstants.tableCustomerPayments} '
      'WHERE ${DbConstants.colCustPaymentCustomerId} = ?',
      [customerId],
    );
    final double customerPayments = (paymentsResult.first['total_paid'] as num?)?.toDouble() ?? 0.0;

    // Balance = Opening Balance + Credit Sales - Customer Payments
    return openingBalance + creditSales - customerPayments;
  }

  @override
  Future<List<Sale>> getCustomerSales(int customerId) async {
    final results = await _dbHelper.query(
      DbConstants.tableSales,
      where: '${DbConstants.colSaleCustomerId} = ?',
      whereArgs: [customerId],
      orderBy: '${DbConstants.colSaleDate} DESC, ${DbConstants.colId} DESC',
    );
    return results.map((row) => Sale.fromMap(row)).toList();
  }

  @override
  Future<List<CustomerPayment>> getCustomerPayments(int customerId) async {
    final results = await _dbHelper.query(
      DbConstants.tableCustomerPayments,
      where: '${DbConstants.colCustPaymentCustomerId} = ?',
      whereArgs: [customerId],
      orderBy: '${DbConstants.colCustPaymentDate} DESC, ${DbConstants.colId} DESC',
    );
    return results.map((row) => CustomerPayment.fromMap(row)).toList();
  }

  @override
  Future<List<CustomerLedgerEntry>> getCustomerTransactions(int customerId) async {
    final customer = await customerRepository.getById(customerId);
    if (customer == null) {
      throw NotFoundException('Customer with ID $customerId not found.');
    }

    final List<CustomerLedgerEntry> entries = [];
    double runningBalance = 0.0;

    // 1. Initial Opening Balance entry
    if (customer.openingBalance != 0.0) {
      runningBalance += customer.openingBalance;
      entries.add(
        CustomerLedgerEntry(
          date: customer.createdAt,
          type: 'OPENING_BALANCE',
          reference: 'OB-${customer.id}',
          debit: customer.openingBalance > 0 ? customer.openingBalance : 0.0,
          credit: customer.openingBalance < 0 ? customer.openingBalance.abs() : 0.0,
          runningBalance: runningBalance,
          notes: 'Account opening balance',
        ),
      );
    }

    // 2. Fetch sales and payments sorted chronologically
    final sales = await getCustomerSales(customerId);
    final payments = await getCustomerPayments(customerId);

    // Merge and sort chronologically
    final List<Map<String, dynamic>> combined = [];
    for (final s in sales) {
      combined.add({'type': 'SALE', 'date': s.saleDate, 'data': s});
    }
    for (final p in payments) {
      combined.add({'type': 'PAYMENT', 'date': p.paymentDate, 'data': p});
    }
    combined.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    for (final item in combined) {
      if (item['type'] == 'SALE') {
        final Sale s = item['data'] as Sale;
        final double debitAmount = s.remainingAmount;
        runningBalance += debitAmount;
        entries.add(
          CustomerLedgerEntry(
            date: s.saleDate,
            type: 'SALE',
            reference: s.invoiceNumber,
            debit: debitAmount,
            credit: 0.0,
            runningBalance: runningBalance,
            notes: 'Wholesale Invoice #${s.invoiceNumber} (${s.paymentStatus})',
          ),
        );
      } else {
        final CustomerPayment p = item['data'] as CustomerPayment;
        final double creditAmount = p.amount;
        runningBalance -= creditAmount;
        entries.add(
          CustomerLedgerEntry(
            date: p.paymentDate,
            type: 'PAYMENT',
            reference: p.reference ?? 'PAY-${p.id}',
            debit: 0.0,
            credit: creditAmount,
            runningBalance: runningBalance,
            notes: 'Payment via ${p.paymentMethod} - ${p.notes ?? ''}',
          ),
        );
      }
    }

    return entries;
  }
}
