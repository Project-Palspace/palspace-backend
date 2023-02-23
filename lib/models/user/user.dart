
import 'package:isar/isar.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/helpers/user/user.helpers.dart';
import 'package:palspace_backend/models/user/user_details.dart';
import 'package:palspace_backend/models/user/user_facts.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? email;
  @Index(caseSensitive: true)
  String? username;

  String? hashedPassword;
  String? salt;

  UserDetails? details;
  UserFacts? facts;

  final verifyTokens = IsarLinks<UserVerify>();
  final traits = IsarLinks<UserTrait>();
  final loginSessions = IsarLinks<LoginSession>();

  dynamic toJsonAsync() async {
    return {
      'username': username,
      'email': email,
      'details': details?.toJson(),
      'facts': facts?.toJson(),
      'traits': traits.toList(),
      'profilePictureUrl': await profilePictureUrl,
    };
  }

  dynamic toJson() {
    return {
      'username': username,
      'email': email,
      'details': details?.toJson(),
      'facts': facts?.toJson(),
      'traits': traits.toList(),
      'profilePictureUrl': null
    };
  }
}
