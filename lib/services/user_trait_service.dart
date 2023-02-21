import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:darq/darq.dart';

class UserTraitService {
  final ServiceCollection serviceCollection;
  UserTraitService(this.serviceCollection);

  Future<void> addTrait(User user, Trait trait) async {
    final isar = serviceCollection.get<Isar>();
    final userTrait = UserTrait()
      ..user.value = user
      ..trait = trait.name;

    user.traits.add(userTrait);

    await isar.writeTxn(() async {
      await isar.userTraits.put(userTrait);
      await user.traits.save();
    });
  }

  Future<void> removeTrait(User user, Trait trait) async {
    final isar = serviceCollection.get<Isar>();
    final userTrait = await isar.userTraits
        .filter()
        .user((q) => q.idEqualTo(user.id))
        .traitEqualTo(trait.name)
        .findFirst();
    if (userTrait != null) {
      await isar.writeTxn(() async {
        await isar.userTraits.delete(userTrait.id);
        await user.traits.save();
      });
    }
  }

  hasTrait(User user, Trait trait) {
    return user.traits.any((element) => element.trait == trait.name);
  }

  Future assertHasTraits(User user, List<Trait> traits) async {
    final isar = serviceCollection.get<Isar>();
    final userTraits = await isar.userTraits
        .filter()
        .user((q) => q.idEqualTo(user.id))
        .findAll();
    final userTraitValues = userTraits.map((e) => e.trait).toList();
    for (final trait in traits) {
      if (!userTraitValues.contains(trait.name)) {
        throw MissingTraitException(trait);
      }
    }
  }

  Future<void> assertMissingTraits(User user, List<Trait> traits) async {
    final isar = serviceCollection.get<Isar>();
    final userTraits = await isar.userTraits
        .filter()
        .user((q) => q.idEqualTo(user.id))
        .findAll();
    final userTraitValues = userTraits.map((e) => e.trait).toList();
    for (final trait in traits) {
      if (userTraitValues.contains(trait.name)) {
        throw UnexpectedTraitException(
            Trait.values.firstWhere((e) => e.name.toString() == trait.name));
      }
    }
  }

  Future<void> suspendUser(User user) async {
    final isar = serviceCollection.get<Isar>();
    final loginSessions = (await isar.loginSessions
        .filter()
        .user((q) => q.idEqualTo(user.id))
        .findAll()
    ).select((e, index) => e.id).toList();

    // Clear users session tokens
    isar.writeTxn(() async {
      await isar.loginSessions.deleteAll(loginSessions);
    });

    addTrait(user, Trait.SUSPENDED);
  }
}
