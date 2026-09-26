import 'package:isar/isar.dart';

part 'book_model.g.dart';

@collection
class BookProduct {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String isbn;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  late String author;

  late double wholesalePrice;

  late double retailPrice;

  late int unitsPerCarton;

  late int totalStockQuantity;

  // Helper getters for wholesale calculations
  int get cartons => unitsPerCarton > 0 ? totalStockQuantity ~/ unitsPerCarton : 0;
  int get looseUnits => unitsPerCarton > 0 ? (totalStockQuantity % unitsPerCarton).toInt() : totalStockQuantity;
}
