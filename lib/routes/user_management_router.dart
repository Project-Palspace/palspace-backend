import 'dart:convert';

import 'package:darq/darq.dart';
import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/models/user/user_viewed_by.dart';
import 'package:palspace_backend/services/mail_service.dart';
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

    router.get('/delete', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);

      // Create a deletion verify token and store it
      final isar = serviceCollection.get<Isar>();
      final token = await UserVerify.generateToken(isar, user, VerifyReason.DELETE_VERIFY);

      //TODO: Use template for email verification
      // Send email to user to verify request of account deletion
      final mailService = serviceCollection.get<MailService>();
      await mailService.sendMail(user.email!, "Verify account deletion",
          "Please verify account deletion: https://api.palspace.dev/user/verify-delete?t=${token.token}");

      return Response(201);
    });

    router.delete('/verify-delete', (Request request) async {
      final token = request.url.queryParameters['t'];
      final isar = serviceCollection.get<Isar>();
      final user = await RequestUtils.userFromRequest(request);
      final userVerify = await isar.userVerifys.filter().tokenEqualTo(token).reasonEqualTo(VerifyReason.DELETE_VERIFY.name).findFirst();

      if (userVerify == null) {
        return Response(404);
      }

      // Only allow user to delete it's own account
      if (userVerify.user.value!.id != user.id) {
        return Response(401);
      }

      // Check if the token is still valid
      if (userVerify.expiresAt!.isBefore(DateTime.now())) {
        // Delete expired token
        await isar.writeTxn(() async {
          await isar.userVerifys.delete(userVerify.id);
        });
        return Response(410);
      }

      // Delete user from database
      //TODO: Can we delete everything in a more efficient way?
      //TODO: Maybe somehow we can delete just based on it's relations?

      // Delete all users trait links
      user.traits.toList().forEach((element) async {
        await isar.writeTxn(() => isar.userTraits.delete(element.id));
      });

      //Delete all user sessions
      user.loginSessions.toList().forEach((element) async {
        await isar.writeTxn(() => isar.loginSessions.delete(element.id));
      });

      // Delete all user verifications
      user.verifyTokens.toList().forEach((element) async {
        await isar.writeTxn(() => isar.userVerifys.delete(element.id));
      });

      // Delete all user views
      final views = await isar.userViews.filter().subject((q) => q.idEqualTo(user.id)).findAll();
      await isar.writeTxn(() => isar.userViews.deleteAll(views.select((e, index) => e.id).toList()));

      await isar.writeTxn(() => isar.users.delete(user.id));
      return Response(204);
    });

    return router;
  }
}
