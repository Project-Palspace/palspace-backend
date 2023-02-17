import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';

import 'user_details.dart';

part 'user_verify.g.dart';

@collection
class UserVerify {
  Id id = Isar.autoIncrement;

  String? token;
  DateTime? expiresAt;

  @Backlink(to: 'verifyToken')
  final user = IsarLink<User>();
}