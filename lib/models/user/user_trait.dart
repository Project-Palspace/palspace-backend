import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/models/user/user.dart';

part 'user_trait.g.dart';

@collection
class UserTrait {
  Id id = Isar.autoIncrement;

  String? trait;

  @Index()
  @Backlink(to: 'traits')
  final user = IsarLink<User>();

  UserTrait({Trait? userTrait}) {
    trait = userTrait?.name;
  }

  dynamic toJson() {
    return trait;
  }
}
