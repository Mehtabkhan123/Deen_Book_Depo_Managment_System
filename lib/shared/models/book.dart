/// Book product entity for the wholesale inventory system
class Book {
  final int? id;
  final int? categoryId;
  final String name;
  final String? isbn;
  final String? author;
  final String? publisher;
  final double purchasePrice;
  final double wholesalePrice;
  final double retailPrice;
  final int stockQuantity;
  final int minimumStock;
  final String createdAt;
  final String? updatedAt;

  const Book({
    this.id,
    this.categoryId,
    required this.name,
    this.isbn,
    this.author,
    this.publisher,
    this.purchasePrice = 0.0,
    this.wholesalePrice = 0.0,
    this.retailPrice = 0.0,
    this.stockQuantity = 0,
    this.minimumStock = 0,
    this.createdAt = '',
    this.updatedAt,
  });

  /// Whether current stock has reached or dropped below reorder threshold
  bool get isLowStock => stockQuantity <= minimumStock;

  /// Creates a [Book] instance from SQLite row map
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      name: map['name'] as String,
      isbn: map['isbn'] as String?,
      author: map['author'] as String?,
      publisher: map['publisher'] as String?,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (map['wholesale_price'] as num?)?.toDouble() ?? 0.0,
      retailPrice: (map['retail_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      minimumStock: (map['minimum_stock'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Converts this [Book] instance into a SQLite map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'category_id': categoryId,
      'name': name,
      'isbn': isbn,
      'author': author,
      'publisher': publisher,
      'purchase_price': purchasePrice,
      'wholesale_price': wholesalePrice,
      'retail_price': retailPrice,
      'stock_quantity': stockQuantity,
      'minimum_stock': minimumStock,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [Book] with updated values
  Book copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? isbn,
    String? author,
    String? publisher,
    double? purchasePrice,
    double? wholesalePrice,
    double? retailPrice,
    int? stockQuantity,
    int? minimumStock,
    String? createdAt,
    String? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      isbn: isbn ?? this.isbn,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Book(id: $id, name: $name, isbn: $isbn, wholesalePrice: $wholesalePrice, stock: $stockQuantity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isbn == other.isbn &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ (isbn?.hashCode ?? name.hashCode);
}
