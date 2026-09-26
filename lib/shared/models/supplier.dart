/// Supplier entity representing publishers, printers, and wholesale book vendors
class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final double openingBalance;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  const Supplier({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.openingBalance = 0.0,
    this.notes,
    this.createdAt = '',
    this.updatedAt,
  });

  /// Factory constructor to deserialize a [Supplier] from SQLite row map
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      email: map['email'] as String?,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Converts this [Supplier] into a SQLite map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'opening_balance': openingBalance,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [Supplier] with updated values
  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? email,
    double? openingBalance,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      openingBalance: openingBalance ?? this.openingBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Supplier(id: $id, name: $name, phone: $phone, openingBalance: $openingBalance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
