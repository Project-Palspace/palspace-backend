import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_details.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/routes/models/user_details_request.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserDetailsRouter {
  ServiceCollection serviceCollection;

  UserDetailsRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      return Response.ok(json.encode(user));
    });

    router.get('/<username>', (Request request, String username) {
      // Get user based on username
      final isar = serviceCollection.get<Isar>();
      final user = isar.users.where().usernameEqualTo(username).findFirstSync();

      //TODO: Log that the requesting user has requested to view another user's details

      if (user == null) {
        return Response.notFound('No user found with username $username');
      }
      final userJson = user.toJson() as Map<String, dynamic>;
      userJson.remove('email');
      return Response.ok(json.encode(userJson));
    });

    router.put('/', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      final isar = serviceCollection.get<Isar>();

      if (user.details != null) {
        return Response.forbidden(json.encode({
          'error': 'Account details already filled, use POST to update.',
        }));
      }

      // Add user with new details
      final body = await RequestUtils.bodyFromRequest<UserDetailsRequest>(request);
      user.details = UserDetails()
        ..firstName = body.firstName
        ..lastName = body.lastName
        ..currentCity = body.currentCity
        ..homeCity = body.homeCity
        ..birthDate = body.birthDate;

      await isar.writeTxn(() async {
        await user.traits.save();
        await isar.users.put(user);
      });

      return Response.ok(json.encode(user));
    });

    router.post('/', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      final isar = serviceCollection.get<Isar>();

      if (user.hasTrait(Trait.ACCOUNT_DETAILS_LOCKED)) {
        return Response.forbidden(json.encode({
          'error': 'Account details locked',
        }));
      }

      if (user.details == null) {
        return Response.forbidden(json.encode({
          'error': 'Account details never stored, use PUT to insert them.',
        }));
      }

      // Update user with new details
      final body = await RequestUtils.bodyFromRequest<UserDetailsRequest>(request);
      user.details = UserDetails()
        ..firstName = body.firstName
        ..lastName = body.lastName
        ..currentCity = body.currentCity
        ..homeCity = body.homeCity
        ..birthDate = body.birthDate;

      final trait = UserTrait(userTrait: Trait.ACCOUNT_DETAILS_LOCKED);
      user.traits.add(trait);

      await isar.writeTxn(() async {
        await isar.userTraits.put(trait);
        await user.traits.save();
        await isar.users.put(user);
      });

      return Response.ok(json.encode(user));
    });

    return router;
  }
}
