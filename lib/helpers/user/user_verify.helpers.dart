import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/utilities/utilities.dart';

// ignore: camel_case_types
class UserVerify_ {
  static Future<UserVerify> generateToken(User user, VerifyReason verifyReason,
      {int tokenLength = 32}) async {
    final isar = serviceCollection.get<Isar>();
    final token = Utilities.generateRandomString(tokenLength).toLowerCase();
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