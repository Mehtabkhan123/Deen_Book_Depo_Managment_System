/// Financial transaction representing debt settlement or incoming payment from a customer
class CustomerPayment {
  final int? id;
  final int customerId;
  final double amount;
  final String paymentDate;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String createdAt;

  const CustomerPayment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.createdAt = '',
  });

  /// Factory constructor to deserialize a [CustomerPayment] from SQLite row map
  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'] as int?,
      customerId: (map['customer_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      paymentDate: map['payment_date'] as String,
      paymentMethod: map['payment_method'] as String,
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
    );
  }

  /// Converts this [CustomerPayment] into a SQLite row map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'customer_id': customerId,
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

  /// Returns a copy of this [CustomerPayment] with updated values
  CustomerPayment copyWith({
    int? id,
    int? customerId,
    double? amount,
    String? paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
    String? createdAt,
  }) {
    return CustomerPayment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
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
      'CustomerPayment(id: $id, customerId: $customerId, amount: $amount, date: $paymentDate, method: $paymentMethod)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerPayment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerId == other.customerId &&
          reference == other.reference;

  @override
  int get hashCode => id.hashCode ^ customerId.hashCode ^ amount.hashCode;
}
