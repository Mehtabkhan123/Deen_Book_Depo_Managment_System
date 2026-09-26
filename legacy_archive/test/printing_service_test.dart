import 'package:flutter_test/flutter_test.dart';
import '../lib/models/invoice_model.dart';
import '../lib/services/printing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PrintingService generates valid A4 PDF document with invoice data', () async {
    final invoice = InvoiceModel()
      ..invoiceNumber = 'INV-2026-TEST01'
      ..date = DateTime(2026, 9, 23, 10, 30)
      ..customerName = 'Al-Madinah Islamic Academy'
      ..subtotal = 54000.0
      ..discountAmount = 4000.0
      ..grandTotal = 50000.0
      ..amountPaid = 30000.0
      ..balanceDue = 20000.0
      ..paymentType = 'Credit / On Account'
      ..items = [
        InvoiceItemEmbedded()
          ..bookIsbn = '978-0140449136'
          ..title = 'The Holy Quran - Tajweed 16-Line Standard'
          ..quantity = 40
          ..unitsPerCarton = 20
          ..cartons = 2
          ..looseUnits = 0
          ..unitWholesalePrice = 450.0
          ..lineTotal = 18000.0,
        InvoiceItemEmbedded()
          ..bookIsbn = '978-9960717142'
          ..title = 'Sahih Al-Bukhari (Complete 9 Vol Edition)'
          ..quantity = 10
          ..unitsPerCarton = 4
          ..cartons = 2
          ..looseUnits = 2
          ..unitWholesalePrice = 3200.0
          ..lineTotal = 32000.0,
      ];

    final pdfDoc = await PrintingService.generateInvoicePdf(invoice);
    final bytes = await pdfDoc.save();

    expect(bytes, isNotNull);
    expect(bytes.isNotEmpty, isTrue);
    // Standard PDF files start with '%PDF-'
    expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
  });
}
