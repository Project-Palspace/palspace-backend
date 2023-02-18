import 'package:isar/isar.dart';

part 'user_facts.g.dart';

@embedded
class UserFacts {
  String? firstName;
  String? lastName;
  String? nationality;
  DateTime? birthDate;

  dynamic toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'nationality': nationality,
      'birthDate': birthDate?.toIso8601String()
    };
  }
}
