import 'dart:convert';

import 'package:crypt/crypt.dart';
import 'package:dotenv/dotenv.dart';
import 'package:isar/isar.dart';
import 'package:minio_new/src/minio.dart';
import 'package:palspace_backend/enums/email_template.dart';
import 'package:palspace_backend/enums/trait.dart';
import 'package:palspace_backend/enums/verify_reason.dart';
import 'package:palspace_backend/exceptions/email_taken_exception.dart';
import 'package:palspace_backend/exceptions/email_validation_exception.dart';
import 'package:palspace_backend/exceptions/password_validation_exception.dart';
import 'package:palspace_backend/exceptions/username_taken_exception.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user_details.dart';
import 'package:palspace_backend/models/user/user_facts.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/models/user/user_viewed_by.dart';
import 'package:palspace_backend/routes/models/register_request.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/services/user_trait_service.dart';
import 'package:palspace_backend/utilities/utilities.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? email;
  @Index(caseSensitive: true)
  String? username;

  String? hashedPassword;
  String? salt;

  UserDetails? details;
  UserFacts? facts;

  @ignore
  Future<String?> get profilePictureUrl async {
    if (serviceCollection == null) {
      return null;
    }

    final env = serviceCollection!.get<DotEnv>();
    final minio = serviceCollection!.get<Minio>();
    final bucket = env['PROFILE_PICTURES_BUCKET']!;
    final url = await minio.presignedGetObject(bucket, '$id');
    return url;
  }

  final verifyTokens = IsarLinks<UserVerify>();
  final traits = IsarLinks<UserTrait>();
  final loginSessions = IsarLinks<LoginSession>();

  @ignore
  ServiceCollection? serviceCollection;

  dynamic toJsonAsync() async {
    return {
      'username': username,
      'email': email,
      'details': details?.toJson(),
      'facts': facts?.toJson(),
      'traits': traits.toList(),
      'profilePictureUrl': await profilePictureUrl,
    };
  }

  dynamic toJson() {
    return {
      'username': username,
      'email': email,
      'details': details?.toJson(),
      'facts': facts?.toJson(),
      'traits': traits.toList(),
      'profilePictureUrl': null
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
    final traitService = serviceCollection.get<UserTraitService>();
    if (user2 != null) {
      if (traitService.hasTrait(user2, Trait.EMAIL_VERIFIED)) {
        throw UsernameTakenException(json.encode({"error": "username-in-use"}));
      } else {
        // Check if the user has a verify token that is not expired
        final userVerify = await isar.userVerifys.filter().reasonEqualTo(VerifyReason.DELETE_VERIFY.name).findFirst();

        if (userVerify != null && userVerify.reason == VerifyReason.EMAIL_VERIFY.name) {
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
    final finalUser = await User.createFromRegisterRequest(body, serviceCollection);
    final token = await UserVerify.generateToken(isar, finalUser, VerifyReason.EMAIL_VERIFY, tokenLength: 10);
    final mailService = serviceCollection.get<MailService>();
    await mailService.sendTemplateMail(finalUser, EmailTemplate.verifyEmail, replacements: {
      'token': token.token,
      'tokenPretty': Utilities.insertDashes(token.token!),
    });
  }

  static Future<User> createFromRegisterRequest(RegisterRequest body, ServiceCollection serviceCollection) async {
    final isar = serviceCollection.get<Isar>();
    final hashedPassword = Crypt.sha256(body.password);
    final user = User()
      ..username = body.username
      ..email = body.email
      ..hashedPassword = hashedPassword.hash
      ..salt = hashedPassword.salt;

    await isar.writeTxn(() async {
      await isar.users.put(user);
    });
    return user;
  }

  void populateServiceCollection(ServiceCollection? serviceCollection) {
    this.serviceCollection = serviceCollection;
  }

  Future markViewed(User viewer) async {
    final isar = serviceCollection!.get<Isar>();
    final userViewedBy = UserViews()
      ..dateTime = DateTime.now()
      ..subject.value = this
      ..viewedBy.value = viewer;

    await isar.writeTxn(() async {
      await isar.userViews.put(userViewedBy);
      await userViewedBy.subject.save();
      await userViewedBy.viewedBy.save();
    });
  }
}
