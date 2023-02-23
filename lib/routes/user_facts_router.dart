import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/email_template.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/helpers/user/user.helpers.dart';
import 'package:palspace_backend/helpers/user/user.trait-helpers.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_facts.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/routes/models/user_facts_request.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserFactsRouter {
  Router get router {
    final router = Router();

    router.put('/', (Request request) async {
      final user = await User_.fromRequest(request);
      final isar = serviceCollection.get<Isar>();

      if (user.facts != null) {
        return Response.forbidden(json.encode({
          'error': 'Account details already filled, use POST to update.',
        }));
      }

      // Add user with new details
      final body = await RequestUtils.bodyFromRequest<UserFactsRequest>(request);
      user.facts = UserFacts()
        ..firstName = body.firstName
        ..lastName = body.lastName
        ..nationality = body.nationality
        ..birthDate = body.birthDate;

      // Mark account that it's facts have been filled so it's allowed to make posts.
      user.addTrait(Trait.ACCOUNT_FACTS_FILLED);

      await isar.writeTxn(() async {
        await user.traits.save();
        await isar.users.put(user);
      });

      final emailService = serviceCollection.get<MailService>();
      await emailService.sendTemplateMail(user, EmailTemplate.welcome);

      return Response.ok(json.encode(user));
    });

    router.post('/', (Request request) async {
      final user = await User_.fromRequest(request);
      final isar = serviceCollection.get<Isar>();

      if (user.hasTrait(Trait.ACCOUNT_FACTS_LOCKED)) {
        return Response.forbidden(json.encode({
          'error': 'Account details locked',
        }));
      }

      if (user.facts == null) {
        return Response.forbidden(json.encode({
          'error': 'Account details never stored, use PUT to insert them.',
        }));
      }

      // Update user with new details
      final body = await RequestUtils.bodyFromRequest<UserFactsRequest>(request);
      user.facts = UserFacts()
        ..firstName = body.firstName
        ..lastName = body.lastName
        ..nationality = body.nationality
        ..birthDate = body.birthDate;

      final trait = UserTrait(userTrait: Trait.ACCOUNT_FACTS_LOCKED);
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
