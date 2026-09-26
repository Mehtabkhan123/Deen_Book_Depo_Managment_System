import 'package:isar/isar.dart';

part 'invoice_model.g.dart';

@embedded
class InvoiceItemEmbedded {
  String? bookIsbn;
  String? title;
  int quantity = 1;
  int unitsPerCarton = 1;
  int cartons = 0;
  int looseUnits = 0;
  double unitWholesalePrice = 0.0;
  double lineTotal = 0.0;
}

@collection
class InvoiceModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String invoiceNumber;

  DateTime date = DateTime.now();

  int? customerId;

  String customerName = 'Walk-in Bulk Customer';

  List<InvoiceItemEmbedded> items = [];

  double subtotal = 0.0;

  double discountAmount = 0.0;

  double grandTotal = 0.0;

  double amountPaid = 0.0;

  double balanceDue = 0.0;

  String paymentType = 'Cash'; // 'Cash', 'Credit / On Account'
}
