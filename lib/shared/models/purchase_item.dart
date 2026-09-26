/// Line item entity representing an individual book item on a purchase invoice
class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int bookId;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;
  final String? bookName;

  const PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.bookId,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.total,
    this.bookName,
  });

  /// Factory constructor to deserialize a [PurchaseItem] from SQLite row map
  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: (map['purchase_id'] as num).toInt(),
      bookId: (map['book_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      bookName: map['book_name'] as String?,
    );
  }

  /// Converts this [PurchaseItem] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'purchase_id': purchaseId,
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

  /// Returns a copy of this [PurchaseItem] with updated values
  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? bookId,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? total,
    String? bookName,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
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
      'PurchaseItem(id: $id, purchaseId: $purchaseId, bookId: $bookId, qty: $quantity, total: $total)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          purchaseId == other.purchaseId &&
          bookId == other.bookId;

  @override
  int get hashCode => id.hashCode ^ purchaseId.hashCode ^ bookId.hashCode;
}
