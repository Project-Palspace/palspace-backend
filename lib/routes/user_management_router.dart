import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserManagementRouter {
  ServiceCollection serviceCollection;

  UserManagementRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.get('/logout', (Request request) async {
      final session = await RequestUtils.sessionFromRequest(request);

      // Remove session from database
      final isar = serviceCollection.get<Isar>();
      await isar.writeTxn(() => isar.loginSessions.delete(session.id));

      return Response(200);
    });

    router.get('/logout-all', (Request request) async {
      final session = await RequestUtils.sessionFromRequest(request);

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
      final user = await RequestUtils.userFromRequest(request);
      final sessions = user.loginSessions.map((s) => {'id': s.id, 'ipAddress': s.ipAddress, 'userAgent': s.userAgent, 'expiresAt': s.expiresAt!.toIso8601String()});
      return Response(200,
          body: json.encode(sessions.toList()),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/traits', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      return Response(200,
          body: json.encode(user.traits.toList()),
          headers: {'Content-Type': 'application/json'});
    });

    return router;
  }
}
