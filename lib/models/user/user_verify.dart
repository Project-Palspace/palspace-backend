import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';

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
}
