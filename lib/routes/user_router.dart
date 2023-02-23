import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/email_template.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/exceptions/email_not_verified_exception.dart';
import 'package:palspace_backend/exceptions/email_taken_exception.dart';
import 'package:palspace_backend/exceptions/email_validation_exception.dart';
import 'package:palspace_backend/exceptions/password_validation_exception.dart';
import 'package:palspace_backend/exceptions/user_suspended_exception.dart';
import 'package:palspace_backend/exceptions/username_taken_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserRouter {
  ServiceCollection serviceCollection;

  UserRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.post('/login', (Request request) async {
      try {
        final session = await LoginSession.fromLoginRequest(request, serviceCollection);

        if (session == null) {
          return Response(401, body: json.encode({"error": "invalid-credentials"}),
              headers: {'Content-Type': 'application/json'});
        }

        return Response(200,
            body: json.encode(session.toJson()),
            headers: {'Content-Type': 'application/json'});
      } on EmailNotVerifiedException {
        return Response(401,
            body: json.encode({"error": "email-not-verified"}),
            headers: {'Content-Type': 'application/json'});
      } on UserSuspendedException {
        return Response(401,
            body: json.encode({"error": "user-suspended"}),
            headers: {'Content-Type': 'application/json'});
      }
    });

    router.post('/register', (Request request) async {
      final body = await RequestUtils.bodyFromRequest<RegisterRequest>(request);

      try {
        await User.fromRegisterRequest(body, serviceCollection);
        return Response(201);
      } on EmailTakenException catch (e) {
        return Response(409, body: e.message);
      } on EmailValidationException catch (e) {
        return Response(400, body: e.message);
      } on UsernameTakenException catch (e) {
        return Response(409, body: e.message);
      } on PasswordValidationException catch (e) {
        return Response(409, body: e.message);
      }
    });

    router.get('/verify-email', (Request request) async {
      final token = request.url.queryParameters['t'];
      final isar = serviceCollection.get<Isar>();
      final userAgent = request.headers['user-agent'];
      final userVerify =
          await isar.userVerifys.filter().tokenEqualTo(token).reasonEqualTo(VerifyReason.EMAIL_VERIFY.name).findFirst();

      if (userVerify == null) {
        return Response(404);
      }

      // Check if the token is still valid
      if (userVerify.expiresAt!.isBefore(DateTime.now())) {
        // Delete expired token
        await isar.writeTxn(() async {
          await isar.userVerifys.delete(userVerify.id);
        });
        return Response(410);
      }

      // Add trait to user EMAIL_VERIFIED
      final trait = UserTrait(userTrait: Trait.EMAIL_VERIFIED);
      User user = userVerify.user.value as User;
      user.traits.add(trait);

      // Let's write the user and remove the userVerify
      await isar.writeTxn(() async {
        await isar.userVerifys.delete(userVerify.id);
        await isar.userTraits.put(trait);
        await user.traits.save();
      });

      final mailService = serviceCollection.get<MailService>();
      mailService.sendTemplateMail(user, EmailTemplate.emailVerified);

      if (! userAgent!.contains('Palspace')) {
        return Response.ok('Your email is now verified, you can now login in the app.');
      } else {
        // Create new session for user
        LoginSession session =
        await LoginSession.fromUser(user, request, serviceCollection);

        return Response(200,
          body: json.encode(session.toJson()),
          headers: {'Content-Type': 'application/json'});
      }
    });

    return router;
  }
}
