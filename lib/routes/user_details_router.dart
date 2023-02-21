import 'dart:convert';
import 'dart:typed_data';

import 'package:dotenv/dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:isar/isar.dart';
import 'package:minio_new/minio.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/models/user/user_details.dart';
import 'package:palspace_backend/routes/models/user_details.dart';
import 'package:palspace_backend/services/service_collection.dart';
import 'package:palspace_backend/utilities/request_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class UserDetailsRouter {
  ServiceCollection serviceCollection;

  UserDetailsRouter(this.serviceCollection);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final user = await RequestUtils.userFromRequest(request, serviceCollection: serviceCollection);
      return Response.ok(json.encode(await user.toJsonAsync()));
    });

    router.post('/', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      final body = await RequestUtils.bodyFromRequest<UserDetailsRequest>(request);
      final isar = serviceCollection.get<Isar>();

      user.details ??= UserDetails();
      user.details!.bio = body.bio;
      user.details!.currentCity = body.currentCity;
      user.details!.homeCity = body.homeCity;

      await isar.writeTxn(() async {
        await isar.users.put(user);
      });

      return Response(200);
    });

    router.post('/profile-picture', (Request request) async {
      final user = await RequestUtils.userFromRequest(request);
      final minio = serviceCollection.get<Minio>();

      // Read the image from the request
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.toLowerCase().startsWith('image/jpeg')) {
        return Response.badRequest(body: 'Invalid image type, only JPEG is supported.');
      }

      final bodyBytes = Uint8List.fromList(await request.read().expand((x) => x).toList());
      final image = Stream.value(bodyBytes);

      // Check that the data is a valid JPEG image
      try {
        final imageObj = img.decodeJpg(bodyBytes);
        if (imageObj == null) {
          return Response.badRequest(body: 'Invalid image format, only JPEG is supported.');
        }
      } on img.ImageException {
        return Response.badRequest(body: 'Invalid image format, only JPEG is supported.');
      }

      // Upload the image to Minio
      final env = serviceCollection.get<DotEnv>();
      await minio.putObject(env['PROFILE_PICTURES_BUCKET']!, '${user.id}.jpg', image, size: bodyBytes.length);

      return Response(204);
    });

    router.get('/<username>', (Request request, String username) async {
      // Get user based on username
      final isar = serviceCollection.get<Isar>();
      final user = isar.users.where().usernameEqualTo(username).findFirstSync();

      //TODO: Log that the requesting user has requested to view another user's details

      if (user == null) {
        return Response.notFound('No user found with username $username');
      }

      user.populateServiceCollection(serviceCollection);

      final userJson = await user.toJsonAsync() as Map<String, dynamic>;
      userJson.remove('email');
      return Response.ok(json.encode(userJson));
    });

    return router;
  }
}
