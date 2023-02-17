import 'dart:async';

import 'package:isar/isar.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:shelf/shelf.dart';

Future<LoginSession?> isValidToken(String token, ServiceCollection serviceCollection) async {
  final isar = serviceCollection.get<Isar>();
  final loginSession = await isar.loginSessions.filter().tokenEqualTo(token).findFirst();

  if (loginSession == null) {
    return null;
  }

  if (loginSession.expiresAt!.millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
    return null;
  }

  return loginSession;
}

FutureOr<Middleware> authenticateMiddleware(ServiceCollection serviceCollection) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final session = await isValidToken(token, serviceCollection);
        if (session != null) {
          final updatedRequest = request.change(context: {'session': session});
          return innerHandler(updatedRequest);
        }
      }
      return Response.unauthorized('Invalid or missing Bearer token');
    };
  };
}
