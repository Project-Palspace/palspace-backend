import 'dart:async';
import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/missing_trait_exception.dart';
import 'package:palspace_backend/exceptions/unexpected_trait_exception.dart';
import 'package:palspace_backend/helpers/user/user.helpers.dart';
import 'package:palspace_backend/helpers/user/user.trait-helpers.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:shelf/shelf.dart';

FutureOr<Middleware> authenticateMiddleware(
    {List<Trait> requiredTraits = const [],
    List<Trait> requiredMissingTraits = const [Trait.SUSPENDED]}) {
  Future<LoginSession?> isValidToken(String token) async {
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

  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final session = await isValidToken(token);
        final user = await User_.fromRequest(request);

        if (session != null) {
          final updatedRequest = request.change(context: {'session': session});

          try {
            await user.assertHasTraits(requiredTraits);
          } on MissingTraitException {
            return Response.unauthorized(
                json.encode({"error": 'Invalid or missing Bearer token'}));
          }

          try {
            await user.assertMissingTraits(requiredMissingTraits);
          } on UnexpectedTraitException {
            if (requiredMissingTraits.contains(Trait.SUSPENDED)) {
              return Response.unauthorized(
                  json.encode({"error": 'This account has been suspended.'}));
            }
            return Response.unauthorized(
                json.encode({"error": 'Invalid or missing Bearer token'}));
          }

          return innerHandler(updatedRequest);
        }
      }
      return Response.unauthorized(
          json.encode({"error": 'Invalid or missing Bearer token'}));
    };
  };
}
