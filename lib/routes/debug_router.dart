import 'dart:convert';

import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/services/user_trait_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class DebugRouter {
  ServiceCollection serviceCollection;

  DebugRouter(this.serviceCollection);

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

    router.get('/trait-test', (Request request) async {
      final session = request.context['session'] as LoginSession;
      final userTraitService = serviceCollection.get<UserTraitService>();
      bool unpectedTraitExceptionThrown = false;
      bool missingTraitExceptionThrown = false;

      try {
        await userTraitService
            .assertHasNotTraits(session.user.value!, [Trait.EMAIL_VERIFIED]);
      } on UnexpectedTraitException catch (e) {
        unpectedTraitExceptionThrown = true;
      }

      try {
        await userTraitService
            .assertHasTraits(session.user.value!, [Trait.EMAIL_VERIFIED]);
      } on MissingTraitException catch (e) {
        missingTraitExceptionThrown = true;
      }

      return Response.ok(
          'EMAIL_VERIFIED: ${session.user.value!.hasTrait(Trait.EMAIL_VERIFIED)}, '
          'unpectedTraitExceptionThrown: $unpectedTraitExceptionThrown, '
          'missingTraitExceptionThrown: $missingTraitExceptionThrown');
    });

    return router;
  }
}
