import 'package:isar/isar.dart';

part 'user_details.g.dart';

@embedded
class UserDetails {
  String? bio;
  String? currentCity;
  String? homeCity;

  dynamic toJson() {
    return {
      'bio': bio,
      'currentCity': currentCity,
      'homeCity': homeCity,
    };
  }
}
