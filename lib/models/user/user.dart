import 'dart:convert';

import 'package:crypt/crypt.dart';
import 'package:isar/isar.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/exceptions/email_taken_exception.dart';
import 'package:palspace_backend/exceptions/email_validation_exception.dart';
import 'package:palspace_backend/exceptions/password_validation_exception.dart';
import 'package:palspace_backend/exceptions/username_taken_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/utilities.dart';
import 'package:uuid/uuid.dart';

import 'user_details.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? username;

  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? email;

  String? hashedPassword;
  String? salt;

  UserDetails? details;

  final verifyToken = IsarLink<UserVerify>();
  final traits = IsarLinks<UserTrait>();
  final loginSessions = IsarLinks<LoginSession>();

  dynamic toJson() {
    return {
      'uuid': uuid,
      'username': username,
      'email': email,
      'details': details?.toJson(),
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

    // Check if username is taken
    final user2 =
        await isar.users.where().usernameEqualTo(body.username).findFirst();
    if (user2 != null) {
      throw UsernameTakenException(json.encode({"error": "username-taken"}));
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
    const uuid = Uuid();
    final finalUser = User()
      ..uuid = uuid.v5(Uuid.NAMESPACE_URL, body.username).toString()
      ..username = body.username
      ..email = body.email
      ..hashedPassword = hashedPassword.hash
      ..salt = hashedPassword.salt;
    final userVerify = UserVerify()
      ..user.value = finalUser
      ..expiresAt = DateTime.now().add(Duration(hours: 1))
      ..token = Utilities.generateRandomString(128);

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
