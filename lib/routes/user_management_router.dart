import 'dart:convert';

import 'package:darq/darq.dart';
import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/email_template.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/models/user/user_verify.helpers.dart';
import 'package:palspace_backend/models/user/user_viewed_by.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:palspace_backend/utilities/utilities.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserManagementRouter {
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
      final sessions = user.loginSessions.map((s) => {'ipAddress': s.ipAddress, 'userAgent': s.userAgent, 'expiresAt': s.expiresAt!.toIso8601String()});
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
      final token = await UserVerify_.generateToken(user, VerifyReason.DELETE_VERIFY, tokenLength: 16);

      // Send email to user to verify request of account deletion
      final mailService = serviceCollection.get<MailService>();
      await mailService.sendTemplateMail(user, EmailTemplate.verifyAccountDeletion, replacements: {
        'tokenPretty': Utilities.insertDashes(token.token!),
        'token': '${token.token?.substring(0, 5)}-${token.token?.substring(5)}',
      });

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
