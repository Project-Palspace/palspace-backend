import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/utilities/utilities.dart';

part 'user_verify.g.dart';

@collection
class UserVerify {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: true)
  String? token;
  @Index()
  String? reason;
  DateTime? expiresAt;

  @Backlink(to: 'verifyTokens')
  final user = IsarLink<User>();

  static Future<UserVerify> generateToken(Isar isar, User user, VerifyReason verifyReason) async {
    final token = Utilities.generateRandomString(32);
    final verify = UserVerify()
      ..token = token
      ..reason = verifyReason.name
      ..expiresAt = DateTime.now().add(Duration(days: 1))
      ..user.value = user;

    await isar.writeTxn(() async {
      await isar.userVerifys.put(verify);
      await verify.user.save();
    });
    return verify;
  }
}
