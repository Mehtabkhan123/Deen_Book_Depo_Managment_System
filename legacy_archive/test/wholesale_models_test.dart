import 'package:flutter_test/flutter_test.dart';
import '../lib/models/book_model.dart';
import '../lib/models/customer_model.dart';
import '../lib/views/fast_billing_screen.dart';

void main() {
  group('BookProduct Model & Packaging Tests', () {
    test('Calculates cartons and loose units correctly for bulk packaging', () {
      final book = BookProduct()
        ..isbn = '978-0140449136'
        ..title = 'The Holy Quran - Tajweed 16-Line Standard'
        ..author = 'Deen Publications'
        ..wholesalePrice = 450.0
        ..retailPrice = 750.0
        ..unitsPerCarton = 20
        ..totalStockQuantity = 405;

      expect(book.cartons, equals(20));
      expect(book.looseUnits, equals(5));
    });

    test('Handles zero units per carton safely without division by zero', () {
      final book = BookProduct()
        ..isbn = '978-0000000000'
        ..title = 'Loose Bound Pamphlet'
        ..author = 'Test Author'
        ..wholesalePrice = 50.0
        ..retailPrice = 80.0
        ..unitsPerCarton = 0
        ..totalStockQuantity = 17;

      expect(book.cartons, equals(0));
      expect(book.looseUnits, equals(17));
    });
  });

  group('CustomerModel Credit Line Tests', () {
    test('Calculates available credit margin correctly', () {
      final customer = CustomerModel()
        ..name = 'Al-Madinah Islamic Academy'
        ..creditLimit = 150000.0
        ..currentDebtBalance = 24500.0;

      expect(customer.availableCredit, equals(125500.0));
    });

    test('Available credit is 0 when current debt balance reaches or exceeds limit', () {
      final customer = CustomerModel()
        ..name = 'Exceeded Client'
        ..creditLimit = 50000.0
        ..currentDebtBalance = 55000.0;

      expect(customer.availableCredit, equals(0.0));
    });
  });

  group('BasketLineItem Calculations', () {
    test('Calculates line item totals and packaging breakdowns', () {
      final book = BookProduct()
        ..isbn = '978-9960717142'
        ..title = 'Sahih Al-Bukhari (Complete 9 Vol Edition)'
        ..author = 'Imam Bukhari'
        ..wholesalePrice = 3200.0
        ..retailPrice = 5000.0
        ..unitsPerCarton = 4
        ..totalStockQuantity = 80;

      final item = BasketLineItem(book: book, quantity: 10);

      expect(item.lineTotal, equals(32000.0));
      expect(item.cartons, equals(2));
      expect(item.looseUnits, equals(2));

      item.dispose();
    });
  });
}
