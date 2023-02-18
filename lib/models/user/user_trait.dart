import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';

part 'user_trait.g.dart';

@collection
class UserTrait {
  Id id = Isar.autoIncrement;

  String? trait;

  @Backlink(to: 'traits')
  final user = IsarLink<User>();

  dynamic toJson() {
    return trait;
  }
}
