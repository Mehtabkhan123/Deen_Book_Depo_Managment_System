/// Category model representing book genres and classifications
class Category {
  final int? id;
  final String name;
  final String? description;
  final String createdAt;
  final String? updatedAt;

  const Category({
    this.id,
    required this.name,
    this.description,
    this.createdAt = '',
    this.updatedAt,
  });

  /// Factory constructor to create a [Category] from a SQLite map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Converts this [Category] instance into a SQLite compatible map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Returns a copy of this [Category] with updated fields
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name, description: $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
