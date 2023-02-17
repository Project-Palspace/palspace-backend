
import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/services/service_collection.dart';

class UserTraitService {
  final ServiceCollection serviceCollection;
  UserTraitService(this.serviceCollection);

  Future assertHasTraits(User user, List<Trait> traits) async {
    final isar = serviceCollection.get<Isar>();
    final userTraits = await isar.userTraits.filter().user((q) => q.uuidEqualTo(user.uuid)).findAll();
    final userTraitValues = userTraits.map((e) => e.trait).toList();
    for (final trait in traits) {
      if (!userTraitValues.contains(trait.name)) {
        throw MissingTraitException(trait);
      }
    }
  }

  Future<void> assertHasNotTraits(User user, List<Trait> traits) async {
    final isar = serviceCollection.get<Isar>();
    final userTraits = await isar.userTraits.filter().user((q) => q.uuidEqualTo(user.uuid)).findAll();
    final userTraitValues = userTraits.map((e) => e.trait).toList();
    for (final trait in userTraitValues) {
      if (!traits.contains(trait)) {
        throw UnexpectedTraitException(Trait.values.firstWhere((e) => e.name.toString() == trait));
      }
    }
  }
}
