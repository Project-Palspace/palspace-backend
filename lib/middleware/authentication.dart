import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/services/user_trait_service.dart';
import 'package:shelf/shelf.dart';

Future<LoginSession?> isValidToken(
    String token, ServiceCollection serviceCollection) async {
  final isar = serviceCollection.get<Isar>();
  final loginSession =
      await isar.loginSessions.filter().tokenEqualTo(token).findFirst();

  if (loginSession == null) {
    return null;
  }

  if (loginSession.expiresAt!.millisecondsSinceEpoch <
      DateTime.now().millisecondsSinceEpoch) {
    return null;
  }

  return loginSession;
}

FutureOr<Middleware> authenticateMiddleware(ServiceCollection serviceCollection,
    {List<Trait> requiredTraits = const []}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final session = await isValidToken(token, serviceCollection);
        final userTraitService = serviceCollection.get<UserTraitService>();

        if (session != null) {
          final updatedRequest = request.change(context: {'session': session});

          try {
            await userTraitService.assertHasTraits(
                session.user.value!, requiredTraits);
          } on MissingTraitException catch (e) {
            return Response.unauthorized(json.encode({"error": 'Invalid or missing Bearer token'}));
          }

          return innerHandler(updatedRequest);
        }
      }
      return Response.unauthorized(json.encode({"error": 'Invalid or missing Bearer token'}));
    };
  };
}
