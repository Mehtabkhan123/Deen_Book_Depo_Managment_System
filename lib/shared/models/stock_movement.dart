/// Immutable audit trail record of every physical inventory change
class StockMovement {
  final int? id;
  final int bookId;
  final String movementType;
  final int quantity;
  final String? referenceType;
  final int? referenceId;
  final int previousStock;
  final int newStock;
  final String movementDate;
  final String? notes;
  final String createdAt;
  final String? bookName;

  const StockMovement({
    this.id,
    required this.bookId,
    required this.movementType,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    required this.previousStock,
    required this.newStock,
    required this.movementDate,
    this.notes,
    this.createdAt = '',
    this.bookName,
  });

  /// Factory constructor to deserialize a [StockMovement] from SQLite row map
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      bookId: (map['book_id'] as num).toInt(),
      movementType: map['movement_type'] as String,
      quantity: (map['quantity'] as num).toInt(),
      referenceType: map['reference_type'] as String?,
      referenceId: (map['reference_id'] as num?)?.toInt(),
      previousStock: (map['previous_stock'] as num).toInt(),
      newStock: (map['new_stock'] as num).toInt(),
      movementDate: map['movement_date'] as String,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
      bookName: map['book_name'] as String?,
    );
  }

  /// Converts this [StockMovement] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'book_id': bookId,
      'movement_type': movementType,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'movement_date': movementDate,
      'notes': notes,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [StockMovement] with updated values
  StockMovement copyWith({
    int? id,
    int? bookId,
    String? movementType,
    int? quantity,
    String? referenceType,
    int? referenceId,
    int? previousStock,
    int? newStock,
    String? movementDate,
    String? notes,
    String? createdAt,
    String? bookName,
  }) {
    return StockMovement(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      movementDate: movementDate ?? this.movementDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      bookName: bookName ?? this.bookName,
    );
  }

  @override
  String toString() =>
      'StockMovement(id: $id, bookId: $bookId, type: $movementType, qty: $quantity, prev: $previousStock, new: $newStock)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bookId == other.bookId &&
          movementDate == other.movementDate;

  @override
  int get hashCode => id.hashCode ^ bookId.hashCode ^ movementDate.hashCode;
}
