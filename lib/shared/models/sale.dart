import 'sale_item.dart';

/// Wholesale sale invoice entity representing outward book sales to customers
class Sale {
  final int? id;
  final int? customerId;
  final String invoiceNumber;
  final String saleDate;
  final double subtotal;
  final double discount;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final List<SaleItem>? items;

  const Sale({
    this.id,
    this.customerId,
    required this.invoiceNumber,
    required this.saleDate,
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

  /// Factory constructor to deserialize a [Sale] from SQLite row map
  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem>? items}) {
    return Sale(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      saleDate: map['sale_date'] as String,
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

  /// Converts this [Sale] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'sale_date': saleDate,
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

  /// Returns a copy of this [Sale] with updated values
  Sale copyWith({
    int? id,
    int? customerId,
    String? invoiceNumber,
    String? saleDate,
    double? subtotal,
    double? discount,
    double? total,
    double? paidAmount,
    double? remainingAmount,
    String? paymentStatus,
    String? notes,
    String? createdAt,
    String? updatedAt,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleDate: saleDate ?? this.saleDate,
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
      'Sale(id: $id, invoiceNumber: $invoiceNumber, customerId: $customerId, total: $total, status: $paymentStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sale &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          invoiceNumber == other.invoiceNumber;

  @override
  int get hashCode => id.hashCode ^ invoiceNumber.hashCode;
}
