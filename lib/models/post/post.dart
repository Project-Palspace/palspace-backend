import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';

part 'post.g.dart';

@collection
class Post {
  Id id = Isar.autoIncrement;

  // TODO:  Can we maintain some form of history if changes have been made to this body?

  String? body;
  String? location;

  DateTime? createdAt;
  DateTime? updatedAt;

  // TODO: PRPS-99 Support for: final media = IsarLinks<Media>();
  final author = IsarLink<User>();
}