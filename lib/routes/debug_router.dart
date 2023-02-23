import 'dart:convert';

import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/services/user_trait_service.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class DebugRouter {
  Router get router {
    final router = Router();

    router.get('/', (Request request) {
      final session = request.context['session'] as LoginSession;
      final details = {
        "session": session.toJson(),
        "user": session.user.value?.toJson(),
      };
      return Response.ok(json.encode(details),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/suspend-me', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);

      // Ban the user by adding a trait to it.
      final traitService = serviceCollection.get<UserTraitService>();
      await traitService.suspendUser(user);

      return Response(204);
    });

    router.get('/trait-test', (Request request) async {
      final session = request.context['session'] as LoginSession;
      final userTraitService = serviceCollection.get<UserTraitService>();
      final traitService = serviceCollection.get<UserTraitService>();
      bool unexpectedTraitExceptionThrown = false;
      bool missingTraitExceptionThrown = false;

      try {
        await userTraitService
            .assertMissingTraits(session.user.value!, [Trait.EMAIL_VERIFIED]);
      } on UnexpectedTraitException {
        unexpectedTraitExceptionThrown = true;
      }

      try {
        await userTraitService
            .assertHasTraits(session.user.value!, [Trait.EMAIL_VERIFIED]);
      } on MissingTraitException {
        missingTraitExceptionThrown = true;
      }

      return Response.ok(
          'EMAIL_VERIFIED: ${traitService.hasTrait(session.user.value!, Trait.EMAIL_VERIFIED)}, '
          'unexpectedTraitExceptionThrown: $unexpectedTraitExceptionThrown, '
          'missingTraitExceptionThrown: $missingTraitExceptionThrown');
    });

    return router;
  }
}
