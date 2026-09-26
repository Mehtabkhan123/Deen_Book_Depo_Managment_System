/// Represents a chronological debit/credit transaction entry in a customer ledger
class CustomerLedgerEntry {
  final String date;
  final String type; // 'OPENING_BALANCE', 'SALE', 'PAYMENT'
  final String reference;
  final double debit; // Increases customer debt (e.g. Credit Sale)
  final double credit; // Decreases customer debt (e.g. Payment receipt)
  final double runningBalance;
  final String? notes;

  const CustomerLedgerEntry({
    required this.date,
    required this.type,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'reference': reference,
      'debit': debit,
      'credit': credit,
      'runningBalance': runningBalance,
      'notes': notes,
    };
  }
}
