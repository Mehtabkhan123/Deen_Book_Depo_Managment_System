/// Financial transaction representing outward supplier payment or invoice clearance
class SupplierPayment {
  final int? id;
  final int supplierId;
  final double amount;
  final String paymentDate;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String createdAt;

  const SupplierPayment({
    this.id,
    required this.supplierId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.createdAt = '',
  });

  /// Factory constructor to deserialize a [SupplierPayment] from SQLite row map
  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id'] as int?,
      supplierId: (map['supplier_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      paymentDate: map['payment_date'] as String,
      paymentMethod: map['payment_method'] as String,
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  /// Converts this [SupplierPayment] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'supplier_id': supplierId,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [SupplierPayment] with updated values
  SupplierPayment copyWith({
    int? id,
    int? supplierId,
    double? amount,
    String? paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
    String? createdAt,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'SupplierPayment(id: $id, supplierId: $supplierId, amount: $amount, date: $paymentDate, method: $paymentMethod)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierPayment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supplierId == other.supplierId &&
          reference == other.reference;

  @override
  int get hashCode => id.hashCode ^ supplierId.hashCode ^ amount.hashCode;
}
