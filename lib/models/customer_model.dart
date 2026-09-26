import 'package:isar/isar.dart';

part 'customer_model.g.dart';

@collection
class CustomerModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String name;

  String? phone;

  String? shopOrInstitutionName;

  String? address;

  double creditLimit = 0.0;

  double currentDebtBalance = 0.0;

  DateTime createdAt = DateTime.now();

  double get availableCredit => (creditLimit - currentDebtBalance) > 0 ? (creditLimit - currentDebtBalance) : 0.0;
}
