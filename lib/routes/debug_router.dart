import 'dart:convert';

import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/helpers/user/user.helpers.dart';
import 'package:palspace_backend/helpers/user/user.trait-helpers.dart';
import 'package:palspace_backend/models/login/session.dart';
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
      final user = await User_.fromRequest(request);

      // Ban the user by adding a trait to it.
      await user.suspendUser();

      return Response(204);
    });

    router.get('/trait-test', (Request request) async {
      final user = await User_.fromRequest(request);
      bool unexpectedTraitExceptionThrown = false;
      bool missingTraitExceptionThrown = false;

      try {
        await user.assertMissingTraits([Trait.EMAIL_VERIFIED]);
      } on UnexpectedTraitException {
        unexpectedTraitExceptionThrown = true;
      }

      try {
        await user.assertHasTraits([Trait.EMAIL_VERIFIED]);
      } on MissingTraitException {
        missingTraitExceptionThrown = true;
      }

      return Response.ok(
          'EMAIL_VERIFIED: ${user.hasTrait(Trait.EMAIL_VERIFIED)}, '
          'unexpectedTraitExceptionThrown: $unexpectedTraitExceptionThrown, '
          'missingTraitExceptionThrown: $missingTraitExceptionThrown');
    });

    return router;
  }
}
