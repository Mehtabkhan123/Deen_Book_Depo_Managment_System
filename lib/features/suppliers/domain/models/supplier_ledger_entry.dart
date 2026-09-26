/// Represents a chronological debit/credit transaction entry in a supplier payable ledger
class SupplierLedgerEntry {
  final String date;
  final String type; // 'OPENING_BALANCE', 'PURCHASE', 'PAYMENT'
  final String reference;
  final double credit; // Increases amount owed to supplier (Credit Purchase)
  final double debit; // Decreases amount owed to supplier (Payment disbursed)
  final double runningBalance;
  final String? notes;

  const SupplierLedgerEntry({
    required this.date,
    required this.type,
    required this.reference,
    required this.credit,
    required this.debit,
    required this.runningBalance,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'reference': reference,
      'credit': credit,
      'debit': debit,
      'runningBalance': runningBalance,
      'notes': notes,
    };
  }
}
