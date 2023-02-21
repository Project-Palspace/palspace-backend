import 'dart:convert';

import 'package:crypt/crypt.dart';
import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/email_taken_exception.dart';
import 'package:palspace_backend/exceptions/email_validation_exception.dart';
import 'package:palspace_backend/exceptions/password_validation_exception.dart';
import 'package:palspace_backend/exceptions/username_taken_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user_details.dart';
import 'package:palspace_backend/models/user/user_facts.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/utilities.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? email;
  String? username;

  String? hashedPassword;
  String? salt;

  UserDetails? details;
  UserFacts? facts;

  final verifyToken = IsarLink<UserVerify>();
  final traits = IsarLinks<UserTrait>();
  final loginSessions = IsarLinks<LoginSession>();

  dynamic toJson() {
    return {
      'username': username,
      'email': email,
      'details': details?.toJson(),
      'facts': facts?.toJson(),
      'traits': traits.toList()
    };
  }

  static Future fromRegisterRequest(
      RegisterRequest body, ServiceCollection serviceCollection) async {
    // Check if email is actually an email
    final regex = RegExp(
        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    if (!regex.hasMatch(body.email)) {
      throw EmailValidationException(json.encode({"error": "email-invalid"}));
    }

    // Check if the email is taken
    final isar = serviceCollection.get<Isar>();
    final user = await isar.users.where().emailEqualTo(body.email).findFirst();
    if (user != null) {
      throw EmailTakenException(json.encode({"error": "email-in-use"}));
    }

    // Check if the username is taken and attached to a user with the trait, EMAIL_VERIFIED.
    final user2 = await isar.users.where().usernameEqualTo(body.username).findFirst();
    if (user2 != null) {
      if (user2.hasTrait(Trait.EMAIL_VERIFIED)) {
        throw UsernameTakenException(json.encode({"error": "username-in-use"}));
      } else {
        // Check if the user has a verify token that is not expired.
        final userVerify = user2.verifyToken.value;
        if (userVerify != null) {
          if (userVerify.expiresAt!.isAfter(DateTime.now())) {
            throw UsernameTakenException(json.encode({"error": "username-in-use"}));
          }
        }

        // If the user has not verified their email, delete the user and continue with the registration.
        await isar.writeTxn(() async {
          if (userVerify != null) {
            await isar.userVerifys.delete(userVerify.id);
          }
          await isar.users.delete(user2.id);
        });
      }
    }

    // Check if password is long enough and has at least a digit and a letter
    if (body.password.length < 8 ||
        !body.password.contains(RegExp(r'[0-9]')) ||
        !body.password.contains(RegExp(r'[a-zA-Z]'))) {
      throw PasswordValidationException(json.encode({
        "error": "password-invalid",
        "message":
            "Password must be at least 8 characters long and contain at least a digit and a letter."
      }));
    }

    // Hash password
    final hashedPassword = Crypt.sha256(body.password);
    final finalUser = User()
      ..username = body.username
      ..email = body.email
      ..hashedPassword = hashedPassword.hash
      ..salt = hashedPassword.salt;
    final userVerify = UserVerify()
      ..user.value = finalUser
      ..expiresAt = DateTime.now().add(Duration(hours: 1))
      ..token = Utilities.generateRandomString(12);

    await isar.writeTxn(() async {
      await isar.users.put(finalUser);
      await isar.userVerifys.put(userVerify);
      await userVerify.user.save();
    });

    final mailService = serviceCollection.get<MailService>();
    await mailService.sendMail(body.email, "Verify email",
        "Please verify your email: https://api.palspace.dev/user/verify-email?t=${userVerify.token}");
  }

  hasTrait(Trait trait) {
    return traits.any((element) => element.trait == trait.name);
  }
}
