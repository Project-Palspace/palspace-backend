import 'package:darq/darq.dart';
import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/services/api_service.dart';

extension UserTraitEx on User {
  Future addTrait(Trait trait) async {
    final isar = serviceCollection.get<Isar>();
    final userTrait = UserTrait()
      ..user.value = this
      ..trait = trait.name;

    traits.add(userTrait);

    await isar.writeTxn(() async {
      await isar.userTraits.put(userTrait);
      await traits.save();
    });
  }

  Future removeTrait(Trait trait) async {
    final isar = serviceCollection.get<Isar>();
    final userTrait = await isar.userTraits
        .filter()
        .user((q) => q.idEqualTo(id))
        .traitEqualTo(trait.name)
        .findFirst();
    if (userTrait != null) {
      await isar.writeTxn(() async {
        await isar.userTraits.delete(userTrait.id);
        await traits.save();
      });
    }
  }

  hasTrait(Trait trait) {
    return traits.any((element) => element.trait == trait.name);
  }

  Future assertHasTraits(List<Trait> traits) async {
    final isar = serviceCollection.get<Isar>();
    final userTraits = await isar.userTraits
        .filter()
        .user((q) => q.idEqualTo(id))
        .findAll();
    final userTraitValues = userTraits.map((e) => e.trait).toList();
    for (final trait in traits) {
      if (!userTraitValues.contains(trait.name)) {
        throw MissingTraitException(trait);
      }
    }
  }

  Future assertMissingTraits(List<Trait> traits) async {
    final isar = serviceCollection.get<Isar>();
    final userTraits = await isar.userTraits
        .filter()
        .user((q) => q.idEqualTo(id))
        .findAll();
    final userTraitValues = userTraits.map((e) => e.trait).toList();
    for (final trait in traits) {
      if (userTraitValues.contains(trait.name)) {
        throw UnexpectedTraitException(
            Trait.values.firstWhere((e) => e.name.toString() == trait.name));
      }
    }
  }

  Future suspendUser() async {
    final isar = serviceCollection.get<Isar>();
    final loginSessions = (await isar.loginSessions
        .filter()
        .user((q) => q.idEqualTo(id))
        .findAll()
    ).select((e, index) => e.id).toList();

    // Clear users session tokens
    isar.writeTxn(() async {
      await isar.loginSessions.deleteAll(loginSessions);
    });

    addTrait(Trait.SUSPENDED);
  }
}