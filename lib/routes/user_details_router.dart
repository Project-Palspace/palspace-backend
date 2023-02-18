import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_details.dart';
import 'package:palspace_backend/routes/models/user_details.dart';
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

    router.post('/', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      final body = await RequestUtils.bodyFromRequest<UserDetailsRequest>(request);
      final isar = serviceCollection.get<Isar>();

      user.details ??= UserDetails();
      user.details!.bio = body.bio;
      user.details!.currentCity = body.currentCity;
      user.details!.homeCity = body.homeCity;

      await isar.writeTxn(() async {
        await isar.users.put(user);
      });

      return Response(200);
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

    return router;
  }
}
