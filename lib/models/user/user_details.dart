import 'package:isar/isar.dart';

part 'user_details.g.dart';

@embedded
class UserDetails {
  String? firstName;
  String? lastName;
  String? homeCity;
  String? currentCity;
  DateTime? birthDate;
  String? bio;

  dynamic toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'homeCity': homeCity,
      'currentCity': currentCity,
      'birthDate': birthDate?.toIso8601String(),
      'bio': bio,
    };
  }
}