// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBookProductCollection on Isar {
  IsarCollection<BookProduct> get bookProducts => this.collection();
}

const BookProductSchema = CollectionSchema(
  name: r'BookProduct',
  id: -2033724957320094976,
  properties: {
    r'author': PropertySchema(
      id: 0,
      name: r'author',
      type: IsarType.string,
    ),
    r'cartons': PropertySchema(
      id: 1,
      name: r'cartons',
      type: IsarType.long,
    ),
    r'isbn': PropertySchema(
      id: 2,
      name: r'isbn',
      type: IsarType.string,
    ),
    r'looseUnits': PropertySchema(
      id: 3,
      name: r'looseUnits',
      type: IsarType.long,
    ),
    r'retailPrice': PropertySchema(
      id: 4,
      name: r'retailPrice',
      type: IsarType.double,
    ),
    r'title': PropertySchema(
      id: 5,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalStockQuantity': PropertySchema(
      id: 6,
      name: r'totalStockQuantity',
      type: IsarType.long,
    ),
    r'unitsPerCarton': PropertySchema(
      id: 7,
      name: r'unitsPerCarton',
      type: IsarType.long,
    ),
    r'wholesalePrice': PropertySchema(
      id: 8,
      name: r'wholesalePrice',
      type: IsarType.double,
    )
  },
  estimateSize: _bookProductEstimateSize,
  serialize: _bookProductSerialize,
  deserialize: _bookProductDeserialize,
  deserializeProp: _bookProductDeserializeProp,
  idName: r'id',
  indexes: {
    r'isbn': IndexSchema(
      id: 6054191419597679616,
      name: r'isbn',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'isbn',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'title': IndexSchema(
      id: -7636685945352118272,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _bookProductGetId,
  getLinks: _bookProductGetLinks,
  attach: _bookProductAttach,
  version: '3.1.0+1',
);

int _bookProductEstimateSize(
  BookProduct object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.author.length * 3;
  bytesCount += 3 + object.isbn.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _bookProductSerialize(
  BookProduct object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.author);
  writer.writeLong(offsets[1], object.cartons);
  writer.writeString(offsets[2], object.isbn);
  writer.writeLong(offsets[3], object.looseUnits);
  writer.writeDouble(offsets[4], object.retailPrice);
  writer.writeString(offsets[5], object.title);
  writer.writeLong(offsets[6], object.totalStockQuantity);
  writer.writeLong(offsets[7], object.unitsPerCarton);
  writer.writeDouble(offsets[8], object.wholesalePrice);
}

BookProduct _bookProductDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BookProduct();
  object.author = reader.readString(offsets[0]);
  object.id = id;
  object.isbn = reader.readString(offsets[2]);
  object.retailPrice = reader.readDouble(offsets[4]);
  object.title = reader.readString(offsets[5]);
  object.totalStockQuantity = reader.readLong(offsets[6]);
  object.unitsPerCarton = reader.readLong(offsets[7]);
  object.wholesalePrice = reader.readDouble(offsets[8]);
  return object;
}

P _bookProductDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bookProductGetId(BookProduct object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _bookProductGetLinks(BookProduct object) {
  return [];
}

void _bookProductAttach(
    IsarCollection<dynamic> col, Id id, BookProduct object) {
  object.id = id;
}

extension BookProductByIndex on IsarCollection<BookProduct> {
  Future<BookProduct?> getByIsbn(String isbn) {
    return getByIndex(r'isbn', [isbn]);
  }

  BookProduct? getByIsbnSync(String isbn) {
    return getByIndexSync(r'isbn', [isbn]);
  }

  Future<bool> deleteByIsbn(String isbn) {
    return deleteByIndex(r'isbn', [isbn]);
  }

  bool deleteByIsbnSync(String isbn) {
    return deleteByIndexSync(r'isbn', [isbn]);
  }

  Future<List<BookProduct?>> getAllByIsbn(List<String> isbnValues) {
    final values = isbnValues.map((e) => [e]).toList();
    return getAllByIndex(r'isbn', values);
  }

  List<BookProduct?> getAllByIsbnSync(List<String> isbnValues) {
    final values = isbnValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'isbn', values);
  }

  Future<int> deleteAllByIsbn(List<String> isbnValues) {
    final values = isbnValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'isbn', values);
  }

  int deleteAllByIsbnSync(List<String> isbnValues) {
    final values = isbnValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'isbn', values);
  }

  Future<Id> putByIsbn(BookProduct object) {
    return putByIndex(r'isbn', object);
  }

  Id putByIsbnSync(BookProduct object, {bool saveLinks = true}) {
    return putByIndexSync(r'isbn', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIsbn(List<BookProduct> objects) {
    return putAllByIndex(r'isbn', objects);
  }

  List<Id> putAllByIsbnSync(List<BookProduct> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'isbn', objects, saveLinks: saveLinks);
  }
}

extension BookProductQueryWhereSort
    on QueryBuilder<BookProduct, BookProduct, QWhere> {
  QueryBuilder<BookProduct, BookProduct, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }
}

extension BookProductQueryWhere
    on QueryBuilder<BookProduct, BookProduct, QWhereClause> {
  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> isbnEqualTo(
      String isbn) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isbn',
        value: [isbn],
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> isbnNotEqualTo(
      String isbn) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isbn',
              lower: [],
              upper: [isbn],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isbn',
              lower: [isbn],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isbn',
              lower: [isbn],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isbn',
              lower: [],
              upper: [isbn],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleNotEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleGreaterThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [title],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleLessThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [],
        upper: [title],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleBetween(
    String lowerTitle,
    String upperTitle, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [lowerTitle],
        includeLower: includeLower,
        upper: [upperTitle],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleStartsWith(
      String TitlePrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'title',
        lower: [TitlePrefix],
        upper: ['$TitlePrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [''],
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterWhereClause> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'title',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'title',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'title',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'title',
              upper: [''],
            ));
      }
    });
  }
}

extension BookProductQueryFilter
    on QueryBuilder<BookProduct, BookProduct, QFilterCondition> {
  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> authorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      authorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> authorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> authorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'author',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      authorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> authorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> authorContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> authorMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'author',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      authorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      authorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> cartonsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cartons',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      cartonsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cartons',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> cartonsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cartons',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> cartonsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cartons',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isbn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isbn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isbn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isbn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'isbn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'isbn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'isbn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'isbn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> isbnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isbn',
        value: '',
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      isbnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'isbn',
        value: '',
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      looseUnitsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'looseUnits',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      looseUnitsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'looseUnits',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      looseUnitsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'looseUnits',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      looseUnitsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'looseUnits',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      retailPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retailPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      retailPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retailPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      retailPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retailPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      retailPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retailPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      totalStockQuantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalStockQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      totalStockQuantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalStockQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      totalStockQuantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalStockQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      totalStockQuantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalStockQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      unitsPerCartonEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitsPerCarton',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      unitsPerCartonGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitsPerCarton',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      unitsPerCartonLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitsPerCarton',
        value: value,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      unitsPerCartonBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitsPerCarton',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      wholesalePriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wholesalePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      wholesalePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wholesalePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      wholesalePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wholesalePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterFilterCondition>
      wholesalePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wholesalePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension BookProductQueryObject
    on QueryBuilder<BookProduct, BookProduct, QFilterCondition> {}

extension BookProductQueryLinks
    on QueryBuilder<BookProduct, BookProduct, QFilterCondition> {}

extension BookProductQuerySortBy
    on QueryBuilder<BookProduct, BookProduct, QSortBy> {
  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByCartons() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cartons', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByCartonsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cartons', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByIsbn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isbn', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByIsbnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isbn', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByLooseUnits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'looseUnits', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByLooseUnitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'looseUnits', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByRetailPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retailPrice', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByRetailPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retailPrice', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      sortByTotalStockQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStockQuantity', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      sortByTotalStockQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStockQuantity', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByUnitsPerCarton() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsPerCarton', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      sortByUnitsPerCartonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsPerCarton', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> sortByWholesalePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wholesalePrice', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      sortByWholesalePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wholesalePrice', Sort.desc);
    });
  }
}

extension BookProductQuerySortThenBy
    on QueryBuilder<BookProduct, BookProduct, QSortThenBy> {
  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByCartons() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cartons', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByCartonsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cartons', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByIsbn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isbn', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByIsbnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isbn', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByLooseUnits() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'looseUnits', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByLooseUnitsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'looseUnits', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByRetailPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retailPrice', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByRetailPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retailPrice', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      thenByTotalStockQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStockQuantity', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      thenByTotalStockQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalStockQuantity', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByUnitsPerCarton() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsPerCarton', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      thenByUnitsPerCartonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitsPerCarton', Sort.desc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy> thenByWholesalePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wholesalePrice', Sort.asc);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QAfterSortBy>
      thenByWholesalePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wholesalePrice', Sort.desc);
    });
  }
}

extension BookProductQueryWhereDistinct
    on QueryBuilder<BookProduct, BookProduct, QDistinct> {
  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByAuthor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'author', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByCartons() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cartons');
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByIsbn(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isbn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByLooseUnits() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'looseUnits');
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByRetailPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retailPrice');
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct>
      distinctByTotalStockQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalStockQuantity');
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByUnitsPerCarton() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitsPerCarton');
    });
  }

  QueryBuilder<BookProduct, BookProduct, QDistinct> distinctByWholesalePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wholesalePrice');
    });
  }
}

extension BookProductQueryProperty
    on QueryBuilder<BookProduct, BookProduct, QQueryProperty> {
  QueryBuilder<BookProduct, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BookProduct, String, QQueryOperations> authorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'author');
    });
  }

  QueryBuilder<BookProduct, int, QQueryOperations> cartonsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cartons');
    });
  }

  QueryBuilder<BookProduct, String, QQueryOperations> isbnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isbn');
    });
  }

  QueryBuilder<BookProduct, int, QQueryOperations> looseUnitsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'looseUnits');
    });
  }

  QueryBuilder<BookProduct, double, QQueryOperations> retailPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retailPrice');
    });
  }

  QueryBuilder<BookProduct, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<BookProduct, int, QQueryOperations>
      totalStockQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalStockQuantity');
    });
  }

  QueryBuilder<BookProduct, int, QQueryOperations> unitsPerCartonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitsPerCarton');
    });
  }

  QueryBuilder<BookProduct, double, QQueryOperations> wholesalePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wholesalePrice');
    });
  }
}
