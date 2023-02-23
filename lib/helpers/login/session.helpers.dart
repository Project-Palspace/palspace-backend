import 'dart:io';

import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/email_template.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/exceptions/email_not_verified_exception.dart';
import 'package:palspace_backend/exceptions/user_suspended_exception.dart';
import 'package:palspace_backend/helpers/user/user.trait-helpers.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/helpers/user/user_verify.helpers.dart';
import 'package:palspace_backend/routes/models/login_request.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:crypt/crypt.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:palspace_backend/utilities/utilities.dart';
import 'package:shelf/shelf.dart';

import 'package:palspace_backend/models/login/session.dart';

extension LoginSessionEx on LoginSession {}

class LoginSession_ {
  static Future<LoginSession?> fromLoginRequest(Request request) async {
    final loginRequest =
        await RequestUtils.bodyFromRequest<LoginRequest>(request);
    final isar = serviceCollection.get<Isar>();
    final user = await isar.users.where().emailEqualTo(loginRequest.email).findFirst();

    if (user == null) {
      return null;
    }

    final crypt = Crypt.sha256(loginRequest.password!, salt: user.salt);

    if (crypt.hash != user.hashedPassword) {
      return null;
    }

    // Check if user has EMAIL_VERIFIED trait
    if (!user.hasTrait(Trait.EMAIL_VERIFIED)) {
      // Check if user still has valid verify token
      final userVerify = await isar.userVerifys
          .filter()
          .reasonEqualTo(VerifyReason.EMAIL_VERIFY.name)
          .findFirst();

      if (userVerify == null) {
        // Create new user verify token
        await generateAndSendNewVerifyToken(user);
        return null;
      }

      if (userVerify.expiresAt!.isBefore(DateTime.now())) {
        // Delete the user verify token
        await isar.writeTxn(() async {
          await isar.userVerifys.delete(userVerify.id);
        });

        // Create new user verify token
        await generateAndSendNewVerifyToken(user);
      }

      throw EmailNotVerifiedException();
    }

    if (user.hasTrait(Trait.SUSPENDED)) {
      throw UserSuspendedException();
    }

    final ipAddress =
        (request.context['shelf.io.connection_info'] as HttpConnectionInfo)
            .remoteAddress
            .address;
    final userAgent =
        request.headers['user-agent'] ?? request.headers['User-Agent'];
    final session = LoginSession()
      ..userAgent = userAgent
      ..ipAddress = ipAddress
      ..token = Utilities.generateRandomString(128)
      ..refreshToken = Utilities.generateRandomString(128)
      ..expiresAt = DateTime.now().add(Duration(hours: 1))
      ..refreshExpiresAt = DateTime.now().add(Duration(days: 30))
      ..user.value = user;

    user.loginSessions.add(session);

    await isar.writeTxn(() async {
      await isar.loginSessions.put(session);
      await user.loginSessions.save();
    });

    return session;
  }

  static Future<void> generateAndSendNewVerifyToken(User user) async {
    // Create new user verify token
    final token = await UserVerify_.generateToken(
        user, VerifyReason.EMAIL_VERIFY,
        tokenLength: 10);

    // Send new email verification email
    final mailService = serviceCollection.get<MailService>();
    await mailService
        .sendTemplateMail(user, EmailTemplate.verifyEmail, replacements: {
      'token': token.token,
      'tokenPretty': Utilities.insertDashes(token.token!),
    });
  }

  static fromUser(User user, Request? request) {
    final ipAddress =
        ((request?.context['shelf.io.connection_info'] as HttpConnectionInfo)
            .remoteAddress
            .address);
    final userAgent =
        (request?.headers['user-agent'] ?? request?.headers['User-Agent']) ??
            'Unknown';
    final session = LoginSession()
      ..userAgent = userAgent
      ..ipAddress = ipAddress
      ..token = Utilities.generateRandomString(128)
      ..refreshToken = Utilities.generateRandomString(128)
      ..expiresAt = DateTime.now().add(Duration(hours: 1))
      ..refreshExpiresAt = DateTime.now().add(Duration(days: 30))
      ..user.value = user;

    user.loginSessions.add(session);

    // Insert into database
    final isar = serviceCollection.get<Isar>();
    isar.writeTxn(() async {
      await isar.loginSessions.put(session);
      await user.loginSessions.save();
    });

    return session;
  }
}
