import 'package:dotenv/dotenv.dart';
import 'package:isar/isar.dart';
import 'package:minio_new/minio.dart';
import 'package:palspace_backend/models/login/session.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_trait.dart';
import 'package:palspace_backend/models/user/user_verify.dart';
import 'package:palspace_backend/models/user/user_viewed_by.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/services/mail_service.dart';
import 'package:palspace_backend/services/user_trait_service.dart';

final _schemas = List<CollectionSchema<dynamic>>.empty(growable: true);
final _apiController = ApiService();

void main() async {
  // Define schemas
  _schemas.addAll([
    UserSchema,
    UserTraitSchema,
    UserVerifySchema,
    LoginSessionSchema,
    UserViewsSchema
  ]);

  // Initialize services
  final traitService = UserTraitService();
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final mailService = MailService(env);
  final isar = await Isar.open(_schemas);
  final minio = Minio(
      endPoint: env['OBJ_HOST']!,
      port: int.parse(env['OBJ_PORT']!),
      accessKey: env['OBJ_KEY']!,
      secretKey: env['OBJ_SECRET']!,
      useSSL: env['OBJ_SSL']! == "TRUE");

  serviceCollection.addAll([minio, env, isar, mailService, traitService]);

  // Start api server
  await _apiController.startApi();
}
