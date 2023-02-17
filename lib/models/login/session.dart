import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/routes/models/login_request.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:crypt/crypt.dart';
import 'package:palspace_backend/utilities/utilities.dart';

part 'session.g.dart';

@collection
class LoginSession {
  Id id = Isar.autoIncrement;

  String? token;
  String? refreshToken;
  DateTime? expiresAt;
  DateTime? refreshExpiresAt;

  @Backlink(to: 'loginSessions')
  final user = IsarLink<User>();

  dynamic toJson() {
    return {
      'id': id,
      'token': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'refreshExpiresAt': refreshExpiresAt?.toIso8601String(),
    };
  }

  static Future<LoginSession?> fromLoginRequest(LoginRequest loginRequest, ServiceCollection serviceCollection) async {
    final isar = serviceCollection.get<Isar>();
    final user = await isar.users.where().emailEqualTo(loginRequest.email).findFirst();
    final crypt = Crypt.sha256(loginRequest.password!, salt: user!.salt);

    if (crypt.hash != user.hashedPassword) {
      return null;
    }

    final session = LoginSession()
      ..token = Utilities.generateRandomString(128)
      ..refreshToken = Utilities.generateRandomString(128)
      ..expiresAt = DateTime.now().add(Duration(hours: 1))
      ..refreshExpiresAt = DateTime.now().add(Duration(days: 1))
      ..user.value = user;

    user.loginSessions.add(session);

    await isar.writeTxn(() async {
      await isar.loginSessions.put(session);
      await user.loginSessions.save();
    });

    return session;
  }
}