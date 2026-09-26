import 'purchase_item.dart';

/// Purchase invoice header representing stock intake from suppliers
class Purchase {
  final int? id;
  final int supplierId;
  final String invoiceNumber;
  final String purchaseDate;
  final double subtotal;
  final double discount;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final List<PurchaseItem>? items;

  const Purchase({
    this.id,
    required this.supplierId,
    required this.invoiceNumber,
    required this.purchaseDate,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    required this.paymentStatus,
    this.notes,
    this.createdAt = '',
    this.updatedAt,
    this.items,
  });

  /// Factory constructor to deserialize a [Purchase] from SQLite row map
  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem>? items}) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: (map['supplier_id'] as num).toInt(),
      invoiceNumber: map['invoice_number'] as String,
      purchaseDate: map['purchase_date'] as String,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] as String,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: map['updated_at'] as String?,
      items: items,
    );
  }

  /// Converts this [Purchase] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'purchase_date': purchaseDate,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [Purchase] with updated values
  Purchase copyWith({
    int? id,
    int? supplierId,
    String? invoiceNumber,
    String? purchaseDate,
    double? subtotal,
    double? discount,
    double? total,
    double? paidAmount,
    double? remainingAmount,
    String? paymentStatus,
    String? notes,
    String? createdAt,
    String? updatedAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() =>
      'Purchase(id: $id, invoiceNumber: $invoiceNumber, supplierId: $supplierId, total: $total, status: $paymentStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Purchase &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          invoiceNumber == other.invoiceNumber;

  @override
  int get hashCode => id.hashCode ^ invoiceNumber.hashCode;
}
