/// Line item entity representing an individual book item on a wholesale sales invoice
class SaleItem {
  final int? id;
  final int saleId;
  final int bookId;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;
  final String? bookName;

  const SaleItem({
    this.id,
    required this.saleId,
    required this.bookId,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.total,
    this.bookName,
  });

  /// Factory constructor to deserialize a [SaleItem] from SQLite row map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: (map['sale_id'] as num).toInt(),
      bookId: (map['book_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      bookName: map['book_name'] as String?,
    );
  }

  /// Converts this [SaleItem] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sale_id': saleId,
      'book_id': bookId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total': total,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [SaleItem] with updated values
  SaleItem copyWith({
    int? id,
    int? saleId,
    int? bookId,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? total,
    String? bookName,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      bookId: bookId ?? this.bookId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      bookName: bookName ?? this.bookName,
    );
  }

  @override
  String toString() =>
      'SaleItem(id: $id, saleId: $saleId, bookId: $bookId, qty: $quantity, total: $total)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          saleId == other.saleId &&
          bookId == other.bookId;

  @override
  int get hashCode => id.hashCode ^ saleId.hashCode ^ bookId.hashCode;
}
