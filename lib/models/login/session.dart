
import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';

part 'session.g.dart';

@collection
class LoginSession {
  Id id = Isar.autoIncrement;

  String? userAgent;
  String? ipAddress;
  String? token;
  String? refreshToken;
  DateTime? expiresAt;
  DateTime? refreshExpiresAt;

  @Backlink(to: 'loginSessions')
  final user = IsarLink<User>();

  dynamic toJson() {
    return {
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'token': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt?.toIso8601String(),
    };
  }
}