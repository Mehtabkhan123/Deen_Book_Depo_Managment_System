// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_ledger_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDebtLedgerEntryCollection on Isar {
  IsarCollection<DebtLedgerEntry> get debtLedgerEntrys => this.collection();
}

const DebtLedgerEntrySchema = CollectionSchema(
  name: r'DebtLedgerEntry',
  id: 2521577829199673856,
  properties: {
    r'creditAmount': PropertySchema(
      id: 0,
      name: r'creditAmount',
      type: IsarType.double,
    ),
    r'customerId': PropertySchema(
      id: 1,
      name: r'customerId',
      type: IsarType.long,
    ),
    r'debitAmount': PropertySchema(
      id: 2,
      name: r'debitAmount',
      type: IsarType.double,
    ),
    r'description': PropertySchema(
      id: 3,
      name: r'description',
      type: IsarType.string,
    ),
    r'invoiceNumber': PropertySchema(
      id: 4,
      name: r'invoiceNumber',
      type: IsarType.string,
    ),
    r'runningBalance': PropertySchema(
      id: 5,
      name: r'runningBalance',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 6,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _debtLedgerEntryEstimateSize,
  serialize: _debtLedgerEntrySerialize,
  deserialize: _debtLedgerEntryDeserialize,
  deserializeProp: _debtLedgerEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'customerId': IndexSchema(
      id: 1498639901530368512,
      name: r'customerId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'customerId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _debtLedgerEntryGetId,
  getLinks: _debtLedgerEntryGetLinks,
  attach: _debtLedgerEntryAttach,
  version: '3.1.0+1',
);

int _debtLedgerEntryEstimateSize(
  DebtLedgerEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.invoiceNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _debtLedgerEntrySerialize(
  DebtLedgerEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.creditAmount);
  writer.writeLong(offsets[1], object.customerId);
  writer.writeDouble(offsets[2], object.debitAmount);
  writer.writeString(offsets[3], object.description);
  writer.writeString(offsets[4], object.invoiceNumber);
  writer.writeDouble(offsets[5], object.runningBalance);
  writer.writeDateTime(offsets[6], object.timestamp);
}

DebtLedgerEntry _debtLedgerEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DebtLedgerEntry();
  object.creditAmount = reader.readDouble(offsets[0]);
  object.customerId = reader.readLong(offsets[1]);
  object.debitAmount = reader.readDouble(offsets[2]);
  object.description = reader.readString(offsets[3]);
  object.id = id;
  object.invoiceNumber = reader.readStringOrNull(offsets[4]);
  object.runningBalance = reader.readDouble(offsets[5]);
  object.timestamp = reader.readDateTime(offsets[6]);
  return object;
}

P _debtLedgerEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _debtLedgerEntryGetId(DebtLedgerEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _debtLedgerEntryGetLinks(DebtLedgerEntry object) {
  return [];
}

void _debtLedgerEntryAttach(
    IsarCollection<dynamic> col, Id id, DebtLedgerEntry object) {
  object.id = id;
}

extension DebtLedgerEntryQueryWhereSort
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QWhere> {
  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhere> anyCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'customerId'),
      );
    });
  }
}

extension DebtLedgerEntryQueryWhere
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QWhereClause> {
  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      customerIdEqualTo(int customerId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customerId',
        value: [customerId],
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      customerIdNotEqualTo(int customerId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [],
              upper: [customerId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [customerId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [customerId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerId',
              lower: [],
              upper: [customerId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      customerIdGreaterThan(
    int customerId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customerId',
        lower: [customerId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      customerIdLessThan(
    int customerId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customerId',
        lower: [],
        upper: [customerId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterWhereClause>
      customerIdBetween(
    int lowerCustomerId,
    int upperCustomerId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customerId',
        lower: [lowerCustomerId],
        includeLower: includeLower,
        upper: [upperCustomerId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DebtLedgerEntryQueryFilter
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QFilterCondition> {
  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      creditAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      creditAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creditAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      creditAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creditAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      creditAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creditAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      customerIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerId',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      customerIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerId',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      customerIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerId',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      customerIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      debitAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'debitAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      debitAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'debitAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      debitAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'debitAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      debitAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'debitAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invoiceNumber',
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invoiceNumber',
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      invoiceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      runningBalanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'runningBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      runningBalanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'runningBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      runningBalanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'runningBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      runningBalanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'runningBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DebtLedgerEntryQueryObject
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QFilterCondition> {}

extension DebtLedgerEntryQueryLinks
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QFilterCondition> {}

extension DebtLedgerEntryQuerySortBy
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QSortBy> {
  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByCreditAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByCreditAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByDebitAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debitAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByDebitAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debitAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByRunningBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningBalance', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByRunningBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningBalance', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension DebtLedgerEntryQuerySortThenBy
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QSortThenBy> {
  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByCreditAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByCreditAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByCustomerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerId', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByDebitAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debitAmount', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByDebitAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'debitAmount', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByRunningBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningBalance', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByRunningBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningBalance', Sort.desc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension DebtLedgerEntryQueryWhereDistinct
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct> {
  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByCreditAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creditAmount');
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByCustomerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerId');
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByDebitAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'debitAmount');
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByInvoiceNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByRunningBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runningBalance');
    });
  }

  QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension DebtLedgerEntryQueryProperty
    on QueryBuilder<DebtLedgerEntry, DebtLedgerEntry, QQueryProperty> {
  QueryBuilder<DebtLedgerEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DebtLedgerEntry, double, QQueryOperations>
      creditAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creditAmount');
    });
  }

  QueryBuilder<DebtLedgerEntry, int, QQueryOperations> customerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerId');
    });
  }

  QueryBuilder<DebtLedgerEntry, double, QQueryOperations>
      debitAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'debitAmount');
    });
  }

  QueryBuilder<DebtLedgerEntry, String, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<DebtLedgerEntry, String?, QQueryOperations>
      invoiceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceNumber');
    });
  }

  QueryBuilder<DebtLedgerEntry, double, QQueryOperations>
      runningBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runningBalance');
    });
  }

  QueryBuilder<DebtLedgerEntry, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
