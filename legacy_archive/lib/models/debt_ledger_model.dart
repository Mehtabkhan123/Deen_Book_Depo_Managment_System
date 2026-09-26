import 'package:isar/isar.dart';

part 'debt_ledger_model.g.dart';

@collection
class DebtLedgerEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late int customerId;

  DateTime timestamp = DateTime.now();

  String? invoiceNumber;

  late String description; // e.g. "Wholesale Invoice #INV-...", "Cash Payment Settled"

  double debitAmount = 0.0; // Increases customer receivable debt balance

  double creditAmount = 0.0; // Decreases customer receivable debt balance

  double runningBalance = 0.0; // Customer's total debt after this transaction
}
