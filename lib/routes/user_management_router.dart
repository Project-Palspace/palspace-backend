import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserManagementRouter {
  ServiceCollection serviceCollection;

  UserManagementRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.get('/logout', (Request request) async {
      final session = request.context['session'] as LoginSession;

      // Remove session from database
      final isar = serviceCollection.get<Isar>();
      await isar.writeTxn(() => isar.loginSessions.delete(session.id));

      return Response(200);
    });

    router.get('/logout-all', (Request request) async {
      final session = request.context['session'] as LoginSession;

      // Remove session from database
      final isar = serviceCollection.get<Isar>();

      // Get all sessions for user
      final sessions = session.user.value?.loginSessions.toList();
      sessions?.forEach((element) async {
        await isar.writeTxn(() => isar.loginSessions.delete(element.id));
      });

      return Response(200);
    });

    router.get('/sessions', (Request request) async {
      final session = request.context['session'] as LoginSession;
      return Response(200,
          body: json.encode(session.user.value?.loginSessions.toList()),
          headers: {'Content-Type': 'application/json'});
    });

    return router;
  }
}
